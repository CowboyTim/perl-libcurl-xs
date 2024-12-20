use Test::More tests => 16;
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
my ($err, $re, $we, $te) = http::curl_multi_fdset($r);
is($err, http::CURLM_OK(), 'no errors');
is_deeply($re, [], 'no read fds');
is_deeply($we, [], 'no write fds');
is_deeply($te, [], 'no exception fds');
$k |= http::curl_multi_add_handle($r, $s);
$k |= http::curl_multi_add_handle($r, $t);
my $handles = http::curl_multi_get_handles($r);
is_deeply($handles, [$s, $t], 'http::curl_multi_get_handles(): return value ok: handles added');
($err, $re, $we, $te) = http::curl_multi_fdset($r);
is($err, http::CURLM_OK(), 'no errors');
is_deeply($re, [], 'still no read fds');
is_deeply($we, [], 'still no write fds');
is_deeply($te, [], 'still no exception fds');
$k |= http::curl_multi_perform($r);
($err, $re, $we, $te) = http::curl_multi_fdset($r);
is($err, http::CURLM_OK(), 'no errors');
ok(scalar @$re > 0, 'read fds');
ok(scalar @$we > 0, 'write fds');
$k |= http::curl_multi_cleanup($r);
is($k, http::CURLE_OK(), 'no errors');
is($r, undef, 'http::curl_multi_cleanup(): return ok: cleanup undef');

is_deeply(\@warn, [], 'no warnings');
