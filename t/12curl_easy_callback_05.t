use Test::More tests => 10;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

{
    my $e = http::curl_easy_init();
    is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
    my $so1 = http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    is($so1, http::CURLE_OK(), 'http::curl_easy_setopt() return URL');
    my $so2 = http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
    is($so2, http::CURLE_OK(), 'http::curl_easy_setopt() return VERBOSE');
    my $so3 = http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
    is($so3, http::CURLE_OK(), 'http::curl_easy_setopt() return HEADER');
    my $so4 = http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    is($so4, http::CURLE_OK(), 'http::curl_easy_setopt() return NOBODY');
    my $so5 = http::curl_easy_setopt($e, http::CURLOPT_FOLLOWLOCATION(), 1);
    is($so5, http::CURLE_OK(), 'http::curl_easy_setopt() return FOLLOWLOCATION');
    my $sod = http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), my $abc = "");
    is($sod, undef, 'http::curl_easy_setopt() return undef, we didnt provide a sub');
    my $rok = http::curl_easy_perform($e);
    is($rok, 0, 'http::curl_easy_perform() return HTTP_OK');
    my $r = http::curl_easy_cleanup($e);
    is($r, undef, 'http::curl_easy_cleanup() return undef');
}
