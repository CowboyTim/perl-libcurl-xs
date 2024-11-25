use Test::More tests => 6;

use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub {push @warn, $_[0]};

my $k;
my $e = http::curl_easy_init();
is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'https://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SHARE(), undef);
is($k, http::CURLE_NOT_BUILT_IN(), 'http::curl_easy_setopt() return CURLE_NOT_BUILT_IN');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SHARE());
is($k, http::CURLE_NOT_BUILT_IN(), 'http::curl_easy_setopt() return CURLE_NOT_BUILT_IN');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SHARE(), \my $share);
is($k, http::CURLE_NOT_BUILT_IN(), 'http::curl_easy_setopt() return CURLE_NOT_BUILT_IN');

is_deeply(\@warn, [], 'no warnings');
