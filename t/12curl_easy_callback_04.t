use Test::More tests => 13;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

{
    my $e = http::curl_easy_init();
    is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
    my $so1 = http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    is($so1, http::CURLE_OK(), 'http::curl_easy_setopt() return');
    my $so2 = http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 1);
    is($so2, http::CURLE_OK(), 'http::curl_easy_setopt() return');
    my $so3 = http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
    is($so3, http::CURLE_OK(), 'http::curl_easy_setopt() return');
    my $so4 = http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    is($so4, http::CURLE_OK(), 'http::curl_easy_setopt() return');
    my $so5 = http::curl_easy_setopt($e, http::CURLOPT_FOLLOWLOCATION(), 1);
    is($so5, http::CURLE_OK(), 'http::curl_easy_setopt() return');
    my $cnt = 0;
    sub abc {
        my ($type, $data, $size, $userp) = @_;
        $cnt++;
        return 0; 
    }
    my $sod = http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), \&abc);
    is($sod, http::CURLE_OK(), 'http::curl_easy_setopt() return');
    is($cnt, 0, 'http::curl_easy_setopt() return: cnt=0');
    my $rok = http::curl_easy_perform($e);
    is($rok, 0, 'http::curl_easy_perform() return');
    isnt($cnt, 0, 'http::curl_easy_perform() return: cnt>0, cnt='.$cnt);
    my $r = http::curl_easy_cleanup($e);
    is($r, undef, 'http::curl_easy_cleanup() return');
}

is_deeply(\@warn, [], 'no warnings');
