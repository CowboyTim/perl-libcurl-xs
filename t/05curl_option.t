use Test::More tests => 13;
use strict; use warnings;

BEGIN {use_ok('utils::curl', qw())};

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
like($@, qr/Undefined subroutine/, 'http::curl_easy_setopt() CURLOPT_TCP_KEEPCNT');

is(http::curl_easy_setopt(), undef, 'http::curl_easy_setopt() error check 1');
is(http::curl_easy_setopt($r1), undef, 'http::curl_easy_setopt() error check 2');

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
