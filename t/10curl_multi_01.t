use Test::More tests => 8;

use strict; use warnings;

use_ok('utils::curl');

{
    my $r = http::curl_multi_init();
    isnt($r, undef, 'http::curl_multi_init(): return ok');
    is(ref($r), 'http::curl::multi', 'http::curl_multi_init(): return type ok');
    isnt($$r, undef, 'http::curl_multi_init(): return value ok');

    my $e = http::curl_multi_cleanup($r);
    is($e, http::CURLM_OK(), 'http::curl_multi_cleanup(): return value ok');
    isnt($r, undef, 'http::curl_multi_init(): return ok');
    is(ref($r), 'SCALAR', 'http::curl_multi_init(): return type ok');
    is($$r, undef, 'http::curl_multi_init(): return value ok');

}
