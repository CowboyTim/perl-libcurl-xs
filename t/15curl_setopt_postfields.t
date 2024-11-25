use Test::More tests => 26;

use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub {push @warn, $_[0]};

my $e = http::curl_easy_init();
is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
my $k;
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'https://www.example.com/');
$k = 0;
$k |= http::curl_easy_setopt($e, http::CURLOPT_POSTFIELDS(), my $def = "{\"name\": \"daniel\"}");
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_WRITEFUNCTION(), sub {length($_[1])});
$k |= http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYPEER(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYHOST(), 0);
$k |= http::curl_easy_perform($e) if $k == http::CURLE_OK();
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, init');

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
$k |= http::curl_easy_setopt($d, http::CURLOPT_POSTFIELDS(), $def = "");
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, empty string');

$k = 0;
$k |= http::curl_easy_setopt($d, http::CURLOPT_POSTFIELDS(), $def = {abc => "def"});
is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_perform() return CURLE_BAD_FUNCTION_ARGUMENT, we gave a hash ref');


$k = 0;
$k |= http::curl_easy_setopt($d, http::CURLOPT_POSTFIELDS(), undef);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, set undef');

$k = 0;
$k |= http::curl_easy_setopt($d, http::CURLOPT_POSTFIELDS());
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, set empty');

$k = 0;
$k |= http::curl_easy_setopt($d, http::CURLOPT_POSTFIELDS(), my $abc = "x"x10_000);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, set 1MB');
$abc = undef;
my $uuu = "y"x2_000_000;
$k |= http::curl_easy_perform($d) if $k == http::CURLE_OK();
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, perform 1MB');

$::AUTH = "&auth=123";
$::SC_DESTROY = 0;
$::SC_FETCH = 0;
$::SC_STORE = 0;
{
    $k = 0;
    my $t = tie my $xyz, 'NS';
    $xyz = "a=b";
    $k |= http::curl_easy_setopt($d, http::CURLOPT_POSTFIELDS(), "$xyz");
    is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, set tied scalar, "" overload');
    $xyz = undef;
    undef($xyz);
}
is($::SC_DESTROY, 1, 'DESTROY not yet called');
is($::SC_FETCH, 1, 'FETCH called once');
is($::SC_STORE, 3, 'STORE called once, 1 real, 2 undef');
{
    $k |= http::curl_easy_perform($d) if $k == http::CURLE_OK();
    is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, perform tied scalar');
}
is($::SC_DESTROY, 1, 'DESTROY called once, last ref should be gone');

$::SC_DESTROY = 0;
$::SC_FETCH = 0;
$::SC_STORE = 0;
{
    $k = 0;
    my $t = tie my $xyz, 'NS';
    $xyz = "a=b";
    $k |= http::curl_easy_setopt($d, http::CURLOPT_POSTFIELDS(), $xyz);
    is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, set tied scalar');
    $xyz = undef;
    undef($xyz);
}
is($::SC_DESTROY, 0, 'DESTROY not yet called');
is($::SC_FETCH, 1, 'FETCH called once');
is($::SC_STORE, 3, 'STORE called once, 1 real, 2 undef');
{
    $k |= http::curl_easy_perform($d) if $k == http::CURLE_OK();
    is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK, perform tied scalar');
}
is($::SC_DESTROY, 0, 'DESTROY not yet called BIS');
{
    http::curl_easy_cleanup($d);
}
is($::SC_DESTROY, 1, 'DESTROY called once, last ref should be gone');


is_deeply(\@warn, [], 'no warnings');

package NS;
require Tie::Scalar;
our @ISA = qw(Tie::StdScalar);
sub TIESCALAR {bless \my $s, shift}
sub FETCH {$::SC_FETCH++;print "# FETCH \n";${$_[0]}.$::AUTH}
sub STORE {$::SC_STORE++;print "# STORE ".($_[1]//'undef')."\n";${$_[0]} = $_[1]}
sub DESTROY {$::SC_DESTROY++;print "# DESTROY \n"}
