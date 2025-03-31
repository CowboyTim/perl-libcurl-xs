use Test::More tests => 9;

use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub {push @warn, $_[0]};

my $do_ws = (http::curl_version() =~ s/.*libcurl\/(\d+)\.(\d+)\.\d+.*//gr and $1>=7 and $2>=84)?1:0;
SKIP: {
skip "libcurl < 7.84.0 does not support websocket meta data", 7
    unless $do_ws;

my $k;
my $e = http::curl_easy_init();
is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'https://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSH_KEYFUNCTION(), undef);
is($k, http::CURLE_NOT_BUILT_IN(), 'http::curl_easy_setopt() return CURLE_NOT_BUILT_IN');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSH_KEYFUNCTION());
is($k, http::CURLE_NOT_BUILT_IN(), 'http::curl_easy_setopt() return CURLE_NOT_BUILT_IN');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSH_KEYFUNCTION(), \my $ssh_key);
is($k, http::CURLE_NOT_BUILT_IN(), 'http::curl_easy_setopt() return CURLE_NOT_BUILT_IN');

$k |= http::curl_easy_setopt($e, http::CURLOPT_SSH_HOSTKEYFUNCTION(), undef);
is($k, http::CURLE_NOT_BUILT_IN(), 'http::curl_easy_setopt() return CURLE_NOT_BUILT_IN');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSH_HOSTKEYFUNCTION());
is($k, http::CURLE_NOT_BUILT_IN(), 'http::curl_easy_setopt() return CURLE_NOT_BUILT_IN');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSH_HOSTKEYFUNCTION(), \my $ssh_hostkey);
is($k, http::CURLE_NOT_BUILT_IN(), 'http::curl_easy_setopt() return CURLE_NOT_BUILT_IN');
}
is_deeply(\@warn, [], 'no warnings');
