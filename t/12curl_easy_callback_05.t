use Test::More tests => 6;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

{
    my $e = http::curl_easy_init();
    is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
    http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
    http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    my $sod = http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), my $abc = "");
    is($sod, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT');
    my $r = http::curl_easy_cleanup($e);
    is($r, undef, 'http::curl_easy_cleanup() return undef');
}

{
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
    http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
    http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    my $sod = http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), my $abc = \(""));
    is($sod, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT');
    my $r = http::curl_easy_cleanup($e);
    is($r, undef, 'http::curl_easy_cleanup() return undef');
}
