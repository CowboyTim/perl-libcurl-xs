use Test::More tests => 23;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub {push @warn, $_[0]};

open(STDIN, "<", "/dev/null");

my $e = http::curl_easy_init();
is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
my $k;
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_PUT(), 1);
$k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
$k |= http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_UPLOAD(), 1);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK string');
$k |= http::curl_easy_perform($e);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_READDATA(), my $abc = "");
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK string');
$k = 0;
$k |= http::curl_easy_setopt($e, http::CURLOPT_READDATA(), my $def = "");
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK string');
$k = 0;
$k |= http::curl_easy_setopt($e, http::CURLOPT_READDATA());
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK string');
$k = 0;
$k |= http::curl_easy_setopt($e, http::CURLOPT_READDATA(), undef);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK string');
$k = 0;
$k |= http::curl_easy_setopt($e, http::CURLOPT_READDATA(), my $def = {abc => "def"});
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK hash ref');
$k = 0;
open(my $rfh, "<", "/dev/null");
$k |= http::curl_easy_setopt($e, http::CURLOPT_READDATA(), $rfh);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK string');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYPEER(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYHOST(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSLVERSION(), http::CURL_SSLVERSION_TLSv1());
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_CIPHER_LIST(), "DEFAULT");
$k |= http::curl_easy_perform($e) if $k == 0;
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, initial run');
$k |= http::curl_easy_perform($e) if $k == 0;
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, second run');

#my $d = http::curl_easy_duphandle($e);
## old
#$k |= http::curl_easy_perform($e);
#is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after duphandle, on original');
#
# new
#$k |= http::curl_easy_perform($d);
#is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after duphandle');
undef $rfh;
open(my $ufh, "<", "/dev/null");
$k |= http::curl_easy_setopt($e, http::CURLOPT_READDATA(), $ufh);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK after reset same UFH 1');
#$ufh = undef;
$k |= http::curl_easy_perform($e) if $k == 0;
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after undef handle');

$k |= http::curl_easy_setopt($e, http::CURLOPT_READDATA(), undef);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after reset same UFH 2');
$k |= http::curl_easy_perform($e) if $k == 0;
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK undef READDATA');

open(my $kfh, "<", "/dev/null");
$k |= http::curl_easy_setopt($e, http::CURLOPT_READDATA(), $kfh);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after reset same KFH 1');
$k |= http::curl_easy_perform($e) if $k == 0;
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after reset same KFH 2');

$k |= http::curl_easy_setopt($e, http::CURLOPT_READDATA());
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after empty list 1');
$k |= http::curl_easy_perform($e) if $k == 0;
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after empty list 2');

open(BARETEST, "<", "/dev/null");
$k |= http::curl_easy_setopt($e, http::CURLOPT_READDATA(), \*BARETEST);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after BARETEST 1');
$k |= http::curl_easy_perform($e) if $k == 0;
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK after BARETEST 2');

is_deeply(\@warn, [], 'no warnings');
