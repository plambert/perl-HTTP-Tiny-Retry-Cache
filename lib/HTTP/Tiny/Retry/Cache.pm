package HTTP::Tiny::Retry::Cache;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;
use File::Spec;
use Path::Tiny;
use Digest::SHA;
use JSON::MaybeXS;
use Try::Tiny;

our $VERSION=0.001;

use parent 'HTTP::Tiny::Retry';

sub request {
    my ($self, $method, $url, $options) = @_;

    $self->{cache_max_age} //= $ENV{HTTP_TINY_CACHE_MAX_AGE} // 3;
    $self->{cache_dir} //= $ENV{HTTP_TINY_CACHE_DIR} // path(File::Spec->tmpdir, "http-tiny-cache-" . path($0)->basename)->realpath;
    $self->{cache_dir}->mkpath unless -d $self->{cache_dir};

    my $res;
    if (uc($method) ne 'GET') {
        $res = $self->SUPER::request($method, $url, $options);
    }
    else {
        my $cachefile=path $self->{cache_dir}->child(Digest::SHA::sha256_hex($url) . ".json");
        try {
            if (-f $cachefile and $cachefile->stat->mtime > time - $self->{cache_max_age}) {
                $res=JSON->new->decode($cachefile->slurp_raw);
            }
        }
        catch {
            log_warn "%s: could not read cache file: %s", $cachefile, $_;
        };
        unless (defined $res) {
            $res = $self->SUPER::request($method, $url, $options);
            try {
                $cachefile->spew_raw(JSON->new->canonical->allow_nonref->pretty->encode($res));
            }
            catch {
                log_warn "%s: could not write cache file: %s", $cachefile, $_;
            };
        }
    }
    $res;
}

sub clean_cache {
    my ($self, $clean_all) = @_;
    $self->{cache_max_age} //= $ENV{HTTP_TINY_CACHE_MAX_AGE} // 86400;
    $self->{cache_dir} //= $ENV{HTTP_TINY_CACHE_DIR} // path(File::Spec->tmpdir, "http-tiny-cache-" . path($0)->basename)->realpath;

    if ($clean_all) {
        log_debug "%s: removing entire directory", $self->{cache_dir};
        path($self->{cache_dir})->remove_tree;
    }
    else {
        for my $cachefile (path($self->{cache_dir})->children(qr{\.json$})) {
            try {
                if ($cachefile->stat->mtime < time - $self->{cache_max_age}) {
                    $cachefile->remove;
                }
            }
            catch {
                log_warn "%s: could not remove expired cache file: %s", $cachefile, $_;
            };
        }
    }
}

1;

# ABSTRACT: Cache HTTP::Tiny requests, and retry failed responses

=head1 SYNOPSIS

 use HTTP::Tiny::Retry::Cache;

 my $res  = HTTP::Tiny::Retry::Cache->new(
     # retries     => 4, # optional, default 3
     # retry_delay => 5, # optional, default is 2
     # cache_dir => '~/.cache/my_cache_dir', # directory in which to store cache files
     # cache_max_age => 86400, # maximum time in seconds to keep cached responses
     # ...
 )->get("http://www.example.com/");


=head1 DESCRIPTION

This class is a subclass of L<HTTP::Tiny::Retry> that caches responses for a fixed
amount of time, regardless of the status returned.


=head1 ENVIRONMENT

=head2 HTTP_TINY_CACHE_MAX_AGE

Int. Sets the default for the L</cache_max_age> attribute, if not specified in the constructor.  The default
if not specified anywhere is 86400 seconds or one full day.

=head2 HTTP_TINY_CACHE_DIR

Int. Sets the default for the L</cache_dir> attribute, if not specified in the constructor.  If not set
anywhere, the default is a subdirectory of the value of File::Spec->tmpdir() named "http-tiny-cache-X" where
X is the basename of the running script.


=head1 SEE ALSO

L<HTTP::Tiny>
L<HTTP::Tiny::Retry>
