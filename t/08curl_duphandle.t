use Test::More tests => 17;

use strict; use warnings;

BEGIN {use_ok('utils::curl', qw())};

{
    my ($r1, $r2, $r3, $r4, $re, $ro, $r5, $r6);
    $r1 = http::curl_easy_init();
    is(ref($r1), 'http::curl::easy', 'http::curl_easy_init() R1 ok');
    $ro = http::curl_easy_setopt($r1, http::CURLOPT_URL(), 'http://www.example.com/');
    is($ro, 0, 'http::curl_easy_setopt() OK');
    $r2 = http::curl_easy_duphandle($r1);
    is(ref($r2), 'http::curl::easy', 'http::curl_easy_duphandle() R2 clone from R1 ok');
    $r3 = http::curl_easy_perform($r2);
    is($r3, 0, 'http::curl_easy_perform() R2: OK');
    $re = http::curl_easy_reset($r2);
    is($re, undef, 'http::curl_easy_reset() R2 RESET');
    $r4 = http::curl_easy_perform($r2);
    is($r4, 3, 'http::curl_easy_perform() R2: 3: URL using bad/illegal format or missing URL (error 3)');
    $r5 = http::curl_easy_strerror($r4);
    is($r5, 'URL using bad/illegal format or missing URL', 'http::curl_easy_strerror() return: "URL using bad/illegal format or missing URL"');
    $r6 = http::curl_easy_perform($r1);
    is($r6, 0, 'http::curl_easy_perform() return: 0: OK');

    http::curl_easy_cleanup($r2);
    is(ref($r2), 'SCALAR', 'http::curl_easy_cleanup() cleanup R2 REF');
    is($$r2, undef, 'http::curl_easy_cleanup() cleanup R2 VALUE');
    http::curl_easy_cleanup($r2);
    is(ref($r2), 'SCALAR', 'http::curl_easy_cleanup() cleanup R2 REF BIS');
    is($$r2, undef, 'http::curl_easy_cleanup() cleanup R2 VALUE BIS');

    http::curl_easy_cleanup($r1);
    is(ref($r2), 'SCALAR', 'http::curl_easy_cleanup() cleanup R1 REF BIS');
    is($$r2, undef, 'http::curl_easy_cleanup() cleanup R1 VALUE BIS');
    http::curl_easy_cleanup($r1);
    is(ref($r2), 'SCALAR', 'http::curl_easy_cleanup() cleanup R1 REF BIS');
    is($$r2, undef, 'http::curl_easy_cleanup() cleanup R1 VALUE BIS');
}
