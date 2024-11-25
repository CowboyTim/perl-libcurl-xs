use Test::More tests => 10;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub {push @warn, $_[0]};

my $e = http::curl_easy_init();
is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
my $k;
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'https://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_WRITEFUNCTION(), sub {length($_[1])});
$k |= http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYPEER(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYHOST(), 0);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK string');
$k |= http::curl_easy_setopt($e, http::CURLOPT_PRIVATE(), my $abc = "");
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK string');
my $d = http::curl_easy_duphandle($e);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK');
$k |= http::curl_easy_setopt($d, http::CURLOPT_PRIVATE(), my $def = "");
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK');
$k |= http::curl_easy_setopt($d, http::CURLOPT_PRIVATE(), my $def = {abc => "def"});
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK');

my $p = http::curl_easy_getinfo($d, http::CURLINFO_PRIVATE());
is("$p", "$def", 'http::curl_easy_getinfo() return HASH(0x0)');
is_deeply($p, $def, 'http::curl_easy_getinfo() return HASH(0x0)');

is_deeply(\@warn, [], 'no warnings');
