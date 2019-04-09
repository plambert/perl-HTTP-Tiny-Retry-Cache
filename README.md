SYNOPSIS
     use HTTP::Tiny::Retry::Cache;

     my $res  = HTTP::Tiny::Retry::Cache->new(
         # retries     => 4, # optional, default 3
         # retry_delay => 5, # optional, default is 2
         # cache_dir => '~/.cache/my_cache_dir', # directory in which to store cache files
         # cache_max_age => 86400, # maximum time in seconds to keep cached responses
         # ...
     )->get("http://www.example.com/");

DESCRIPTION
    This class is a subclass of HTTP::Tiny::Retry that caches responses for
    a fixed amount of time, regardless of the status returned.

ENVIRONMENT
  HTTP_TINY_CACHE_MAX_AGE
    Int. Sets the default for the "cache_max_age" attribute, if not
    specified in the constructor. The default if not specified anywhere is
    86400 seconds or one full day.

  HTTP_TINY_CACHE_DIR
    Int. Sets the default for the "cache_dir" attribute, if not specified in
    the constructor. If not set anywhere, the default is a subdirectory of
    the value of File::Spec->tmpdir() named "http-tiny-cache-X" where X is
    the basename of the running script.

SEE ALSO
    HTTP::Tiny HTTP::Tiny::Retry

