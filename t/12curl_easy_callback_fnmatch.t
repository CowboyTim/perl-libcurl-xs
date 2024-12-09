use Test::More tests => 8;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my $warn = 0;
$SIG{__WARN__} = sub {$warn++};

{
    my $k;
    my $e = http::curl_easy_init();
    is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'ftp://ftp.example.com/file*/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_FNMATCH_FUNCTION(), my $abc = "");
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT string');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'ftp://ftp.example.com/file*/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_FNMATCH_FUNCTION(), my $abc = \(""));
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT string ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'ftp://ftp.example.com/file*/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_FNMATCH_FUNCTION(), my $abc = {});
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT hash ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'ftp://ftp.example.com/file*/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_FNMATCH_FUNCTION(), my $abc = []);
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT hash ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'ftp://ftp.example.com/file*/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_FNMATCH_FUNCTION(), my $abc = sub{});
    is($k, http::CURLE_UNKNOWN_OPTION(), 'http::curl_easy_setopt() return CURLE_UNKNOWN_OPTION code ref');
    http::curl_easy_cleanup($e);
}

is($warn, 0, 'no warnings');
