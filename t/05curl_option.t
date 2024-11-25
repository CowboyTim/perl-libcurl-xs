use Test::More tests => 33;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

my $r1;
{
    eval {
        $r1 = http::curl_easy_init();
    };
    is($@, '', 'http::curl_easy_init() eval');
    is(ref($r1), 'http::curl::easy', 'http::curl_easy_init() return');
}

is(http::curl_easy_setopt($r1, http::CURLOPT_URL(), 'http://www.example.com/'), 0, 'http::curl_easy_setopt() CURLOPT_URL');
is(http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPALIVE(), 1), 0, 'http::curl_easy_setopt() CURLOPT_TCP_KEEPALIVE');
is(http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPIDLE(), 120), 0, 'http::curl_easy_setopt() CURLOPT_TCP_KEEPIDLE');
is(http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPINTVL(), 60), 0, 'http::curl_easy_setopt() CURLOPT_TCP_KEEPINTVL');

eval {
    http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPCNT(), 10);
};
ok(($@ eq '' or $@ =~ qr/Undefined subroutine/), 'http::curl_easy_setopt() CURLOPT_TCP_KEEPCNT');

is(http::curl_easy_setopt(), undef, 'http::curl_easy_setopt() error check 1');
{
    no warnings;
    my $r_nok = http::curl_easy_setopt($r1);
    is($r_nok, 48, 'http::curl_easy_setopt() error check 2');
    is(http::curl_easy_strerror($r_nok), 'An unknown option was passed in to libcurl', 'http::curl_easy_strerror() error check');
    is($r_nok, http::CURLE_UNKNOWN_OPTION(), 'http::curl_easy_strerror() error check');

}

eval {
    http::unknown_function();
};
like($@, qr/Undefined subroutine/, 'http::unknown_function() error check unknown_function()');

eval {
    http::CURLOPT_BLAH();
};
like($@, qr/Undefined subroutine/, 'http::unknown_function() error check CURLOPT_BLAH()');

eval {
    http::CURLOPT_();
};
like($@, qr/Undefined subroutine/, 'http::unknown_function() error check: CUIRLOPT_()');

my $k;
$k = http::curl_easy_setopt($r1, http::CURLOPT_URL());
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k = http::curl_easy_setopt($r1, http::CURLOPT_URL(), undef);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k = http::curl_easy_setopt($r1, http::CURLOPT_URL(), '');
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k = http::curl_easy_setopt($r1, http::CURLOPT_URL(), {});
is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT');
$k = http::curl_easy_setopt($r1, http::CURLOPT_URL(), []);
is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT');
$k = http::curl_easy_setopt($r1, http::CURLOPT_URL(), sub{});
is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT');
$k = http::curl_easy_setopt($r1, http::CURLOPT_URL(), \(""));
is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT');
$k = http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPALIVE());
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k = http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPALIVE(), undef);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k = http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPALIVE(), '');
is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT');
$k = http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPALIVE(), {});
is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT');
$k = http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPALIVE(), 0.0);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k = http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPALIVE(), "0.0");
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k = http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPALIVE(), "1.1");
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k = http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPALIVE(), "0");
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k = http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPALIVE(), "1");
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');

$k = http::curl_easy_setopt($r1, http::CURLOPT_TCP_KEEPALIVE(), "2");
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');

is_deeply(\@warn, [], 'no warnings');
