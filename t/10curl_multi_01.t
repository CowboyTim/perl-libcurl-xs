use Test::More tests => 19;

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

{
    my $r = http::curl_multi_init();
    isnt($r, undef, 'http::curl_multi_init(): return ok');
    is(ref($r), 'http::curl::multi', 'http::curl_multi_init(): return type ok');
    isnt($$r, undef, 'http::curl_multi_init(): return value ok');

    my $s = http::curl_easy_init();
    my $k = http::curl_multi_add_handle($r, $s);
    is($k, http::CURLM_OK(), 'http::curl_multi_add_handle(): return value ok');

    my $t = http::curl_multi_timeout($r, my $to);
    is($t, http::CURLM_OK(), 'http::curl_multi_timeout(): return value ok');
    is($to, 0, 'http::curl_multi_timeout(): return value ok');

    my $l = http::curl_multi_remove_handle($r, $s);
    is($l, http::CURLM_OK(), 'http::curl_multi_remove_handle(): return value ok');

    my $e = http::curl_multi_cleanup($r);
    is($e, http::CURLM_OK(), 'http::curl_multi_cleanup(): return value ok');
    isnt($r, undef, 'http::curl_multi_init(): return ok');
    is(ref($r), 'SCALAR', 'http::curl_multi_init(): return type ok');
    is($$r, undef, 'http::curl_multi_init(): return value ok');
}
