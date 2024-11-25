use Test::More tests => 14;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub {push @warn, $_[0]};

my $e = http::curl_easy_init();
is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
my $k;
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'bluh://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_PUT(), 1);
$k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
$k |= http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 1);
$k |= http::curl_easy_setopt($e, http::CURLOPT_ERRORBUFFER(), my $abc = "");
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYPEER(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYHOST(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSLVERSION(), http::CURL_SSLVERSION_TLSv1());
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_CIPHER_LIST(), "DEFAULT");
$k |= http::curl_easy_perform($e);
is($k, http::CURLE_UNSUPPORTED_PROTOCOL(), 'http::curl_easy_setopt() return CURLE_UNSUPPORTED_PROTOCOL');
is(length($abc), 256, 'http::curl_easy_setopt() return CURLE_OK error buffer');
like($abc, qr/Protocol "bluh" not supported/, 'http::curl_easy_setopt() return CURLE_OK error buffer');
my $d = http::curl_easy_duphandle($e);
$k |= http::curl_easy_setopt($d, http::CURLOPT_URL(), 'bloh://www.example.com/');
# old
$k |= http::curl_easy_perform($e);
is($k, http::CURLE_UNSUPPORTED_PROTOCOL(), 'http::curl_easy_setopt() return CURLE_UNSUPPORTED_PROTOCOL');
# new
$k |= http::curl_easy_perform($d);
is($k, http::CURLE_UNSUPPORTED_PROTOCOL(), 'http::curl_easy_perform() return CURLE_UNSUPPORTED_PROTOCOL');
like($abc, qr/Protocol "bloh" not supported/, 'http::curl_easy_setopt() return CURLE_OK error buffer');
$k |= http::curl_easy_setopt($d, http::CURLOPT_ERRORBUFFER(), my $def = "");
$k |= http::curl_easy_perform($d);
is($k, http::CURLE_UNSUPPORTED_PROTOCOL(), 'http::curl_easy_perform() return CURLE_UNSUPPORTED_PROTOCOL');
like($def, qr/Protocol "bloh" not supported/, 'http::curl_easy_setopt() return CURLE_OK error buffer');

$k |= http::curl_easy_setopt($d, http::CURLOPT_ERRORBUFFER(), my $def = {abc => "def"});
is($def, "\0"x256, 'http::curl_easy_setopt() return CURLE_OK error buffer');
$k |= http::curl_easy_perform($d);
is($k, http::CURLE_UNSUPPORTED_PROTOCOL(), 'http::curl_easy_perform() return CURLE_UNSUPPORTED_PROTOCOL');
like($def, qr/Protocol "bloh" not supported/, 'http::curl_easy_setopt() return CURLE_OK error buffer');

is_deeply(\@warn, [], 'no warnings');
