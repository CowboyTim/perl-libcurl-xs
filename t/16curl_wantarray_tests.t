use Test::More tests => 21;

use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

my @B;
my $c;
is(scalar(@B = http::curl_global_init()), 1, 'http::curl_global_init() return 0 array element');
is(scalar(@B = http::curl_global_init("tst")), 1, 'http::curl_global_init() return 0 array element');
is(scalar(@B = http::curl_global_cleanup()), 1, 'http::curl_global_cleanup() return 1 array element');is(scalar(@B = http::curl_global_trace()), 1, 'http::curl_global_trace() return 0 array element');
is(scalar(@B = http::curl_easy_init()), 1, 'http::curl_easy_init() return 1 array element');
is(scalar(@B = http::curl_easy_cleanup($c = http::curl_easy_init())), 1, 'http::curl_easy_cleanup() return 0 array element');
is(scalar(@B = http::curl_easy_setopt($c, http::CURLOPT_URL(), "http://example.com")), 1, 'http::curl_easy_setopt() return 0 array element');
is($B[0], undef, 'http::curl_easy_setopt() return undef');
is(scalar(@B = http::curl_easy_getinfo($c, http::CURLINFO_EFFECTIVE_URL())), 1, 'http::curl_easy_getinfo() return 1 array element');
is($B[0], undef, 'http::curl_easy_getinfo() return 0 string');
is(scalar(@B = http::curl_easy_perform($c)), 1, 'http::curl_easy_perform() return 1 array element');
is(scalar(@B = http::curl_easy_init()), 1, 'http::curl_easy_cleanup() return 0 array element');
$c = $B[0];
is(scalar(@B = http::curl_easy_setopt($c, http::CURLOPT_NOBODY(), 1)), 1, 'http::curl_easy_setopt() return 0 array element');
is(scalar(@B = http::curl_easy_setopt($c, http::CURLOPT_URL(), "http://example.com")), 1, 'http::curl_easy_setopt() return 0 array element');
is($B[0], http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
is(scalar(@B = http::curl_easy_getinfo($c, http::CURLINFO_EFFECTIVE_URL())), 1, 'http::curl_easy_getinfo() return 1 array element');
is($B[0], "http://example.com", 'http::curl_easy_getinfo() return "http://example.com"');
is(scalar(@B = http::curl_easy_perform($c)), 1, 'http::curl_easy_perform() return 1 array element');
is(scalar(@B = http::curl_easy_duphandle($c)), 1, 'http::curl_easy_duphandle() return 1 array element');

is_deeply(\@warn, [], 'no warnings');
