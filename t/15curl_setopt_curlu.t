use Test::More tests => 13;

use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub {push @warn, $_[0]};

my $k;
my $u = http::curl_url();
$k = http::curl_url_set($u, http::CURLUPART_URL(), "https://www.example.com/");
is($k, http::CURLE_OK(), 'http::curl_url_set() return CURLE_OK');

my $e = http::curl_easy_init();
is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'https://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_WRITEFUNCTION(), sub {length($_[1])});
$k |= http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYPEER(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYHOST(), 0);
$k |= http::curl_easy_perform($e) if $k == http::CURLE_OK();
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, init');
$k |= http::curl_easy_setopt($e, http::CURLOPT_CURLU(), my $def = "{\"name\": \"daniel\"}");
is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT 1: a string');
$k = 0;
$k |= http::curl_easy_setopt($e, http::CURLOPT_CURLU(), $def = \(""));
is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT 2: a ref to a string');
# This is in fact NULL/clear
$k = 0;
$k |= http::curl_easy_setopt($e, http::CURLOPT_CURLU(), bless \(my $_s = 0x00), "http::curl::url");
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK for 0x00');
$k = 0;
$k |= http::curl_easy_setopt($e, http::CURLOPT_CURLU(), $u);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK a real curl::url');

my $d = http::curl_easy_duphandle($e);
# old
$k = 0;
$k |= http::curl_easy_perform($e) if $k == http::CURLE_OK();
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after duphandle, on original');
# new
$k = 0;
$k |= http::curl_easy_perform($d) if $k == http::CURLE_OK();
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after duphandle');

$k = 0;
$k |= http::curl_easy_setopt($d, http::CURLOPT_CURLU(), undef);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, set undef');

$k = 0;
$k |= http::curl_easy_setopt($d, http::CURLOPT_CURLU());
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, set empty');

is_deeply(\@warn, [], 'no warnings');
