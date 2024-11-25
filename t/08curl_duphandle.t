use Test::More tests => 27;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

{
    my $r1 = http::curl_easy_init();
    is(ref($r1), 'http::curl::easy', 'http::curl_easy_init() R1 ok');
    my $ro = http::curl_easy_setopt($r1, http::CURLOPT_URL(), 'http://www.example.com/');
    is($ro, 0, 'http::curl_easy_setopt() OK');
    my $r2 = http::curl_easy_duphandle($r1);
    is(ref($r2), 'http::curl::easy', 'http::curl_easy_duphandle() R2 clone from R1 ok');
    my $r3 = http::curl_easy_perform($r2);
    is($r3, 0, 'http::curl_easy_perform() R2: OK');
    my $re = http::curl_easy_reset($r2);
    is($re, undef, 'http::curl_easy_reset() R2 RESET');
    my $r4 = http::curl_easy_perform($r2);
    is($r4, 3, 'http::curl_easy_perform() R2: 3: URL using bad/illegal format or missing URL (error 3)');
    my $r5 = http::curl_easy_strerror($r4);
    is($r5, 'URL using bad/illegal format or missing URL', 'http::curl_easy_strerror() return: "URL using bad/illegal format or missing URL"');
    my $r6 = http::curl_easy_perform($r1);
    is($r6, 0, 'http::curl_easy_perform() return: 0: OK');

    http::curl_easy_cleanup($r2);
    is($r2, undef, 'http::curl_easy_cleanup() cleanup R2');
    http::curl_easy_cleanup($r2);
    is($r2, undef, 'http::curl_easy_cleanup() cleanup R2');

    http::curl_easy_cleanup($r1);
    is($r1, undef, 'http::curl_easy_cleanup() cleanup R1');
    http::curl_easy_cleanup($r1);
    is($r1, undef, 'http::curl_easy_cleanup() cleanup R1');
}

{
    my $r1 = http::curl_easy_init();
    is(ref($r1), 'http::curl::easy', 'http::curl_easy_init() R1 ok');
    {
        my $r7 = http::curl_easy_pause($r1, http::CURLPAUSE_SEND()|http::CURLPAUSE_RECV());
        is($r7, 43, 'http::curl_easy_pause() R1: OK');
        my $r8 = http::curl_easy_strerror($r7);
        is($r8, 'A libcurl function was given a bad argument', 'http::curl_easy_strerror() return: "A libcurl function was given a bad argument"');
    }
    {
        my $r5 = http::curl_easy_pause($r1, 0);
        is($r5, 43, 'http::curl_easy_pause() R1: OK');
        my $r6 = http::curl_easy_strerror($r5);
        is($r6, 'A libcurl function was given a bad argument', 'http::curl_easy_strerror() return: "A libcurl function was given a bad argument"');
    }
    {
        my $r5 = http::curl_easy_pause($r1, http::CURLPAUSE_CONT());
        is($r5, 43, 'http::curl_easy_pause() R1: OK');
        my $r6 = http::curl_easy_strerror($r5);
        is($r6, 'A libcurl function was given a bad argument', 'http::curl_easy_strerror() return: "A libcurl function was given a bad argument"');
    }
    {
        my $r5 = http::curl_easy_pause($r1);
        is($r5, 43, 'http::curl_easy_pause() R1: OK');
        my $r6 = http::curl_easy_strerror($r5);
        is($r6, 'A libcurl function was given a bad argument', 'http::curl_easy_strerror() return: "A libcurl function was given a bad argument"');
    }
    my $ro = http::curl_easy_setopt($r1, http::CURLOPT_URL(), 'http://www.example.com/');
    is($ro, 0, 'http::curl_easy_setopt() OK');
    my $r4 = http::curl_easy_upkeep($r1);
    is($r4, 0, 'http::curl_easy_upkeep() R1: OK');
    my $r3 = http::curl_easy_perform($r1);
    is($r3, 0, 'http::curl_easy_perform() R1: OK');
    http::curl_easy_cleanup($r1);
    is($r1, undef, 'http::curl_easy_cleanup() cleanup R1');
}

is_deeply(\@warn, [], 'no warnings');
