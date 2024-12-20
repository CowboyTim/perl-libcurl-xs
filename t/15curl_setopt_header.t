use Test::More tests => 12;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub {push @warn, $_[0]};

my $e = http::curl_easy_init();
is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
my $k;
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
$k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_WRITEHEADER(), my $abc = "");
is($abc, '', 'http::curl_easy_setopt() return CURLE_OK header buffer');
open(my $fh, ">", \my $def);
$k |= http::curl_easy_setopt($e, http::CURLOPT_WRITEHEADER(), $fh);
is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT');
$k = 0;
my $headerdata = "";
$k |= http::curl_easy_setopt($e, http::CURLOPT_HEADERFUNCTION(), sub {
    my ($data, $userp) = @_;
    $headerdata .= $data;
    return length($data);
});
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref');
is($abc, '', 'http::curl_easy_setopt() return CURLE_OK header buffer');
$k |= http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
$k = 0;
$k |= http::curl_easy_perform($e);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK');
is($abc, '', 'http::curl_easy_setopt() return CURLE_OK header buffer');
is($def, undef, 'http::curl_easy_setopt() return CURLE_OK header buffer');
isnt($headerdata, '', 'http::curl_easy_setopt() return CURLE_OK header buffer');
like($headerdata, qr/HTTP\/1\.1 200 OK/, 'http::curl_easy_setopt() return CURLE_OK header buffer');

is_deeply(\@warn, [], 'no warnings');
