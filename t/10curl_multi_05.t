use Test::More tests => 5;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

http::curl_global_trace();
http::curl_global_init(http::CURL_GLOBAL_ALL());

my $k;
my $s = http::curl_easy_init();
$k |= http::curl_easy_setopt($s, http::CURLOPT_URL(), 'http://www.example.com');
$k  = http::curl_easy_setopt($s, http::CURLOPT_NOBODY(), 1);
$k  = http::curl_easy_setopt($s, http::CURLOPT_VERBOSE(), 0);

my $t = http::curl_easy_init();
$k |= http::curl_easy_setopt($t, http::CURLOPT_URL(), 'http://www.example.com');
$k |= http::curl_easy_setopt($t, http::CURLOPT_NOBODY(), 1);
$k |= http::curl_easy_setopt($t, http::CURLOPT_VERBOSE(), 0);

my $r = http::curl_multi_init();
$k |= http::curl_multi_add_handle($r, $s);
$k |= http::curl_multi_add_handle($r, $t);
my $handles = http::curl_multi_get_handles($r);
is_deeply($handles, [$s, $t], 'http::curl_multi_get_handles(): return value ok: handles added');
$k |= http::curl_multi_cleanup($r);
is($k, http::CURLE_OK(), 'no errors');
is($r, undef, 'http::curl_multi_cleanup(): return ok: cleanup undef');

is_deeply(\@warn, [], 'no warnings');
