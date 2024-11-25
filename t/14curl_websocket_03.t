use Test::More tests => 4;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

my $ws_key = `openssl rand -base64 32`;
chomp $ws_key;
my $r = http::curl_easy_init();
my $k;
$k |= http::curl_easy_setopt($r, http::CURLOPT_URL(), 'ws://example.com');
$k |= http::curl_easy_setopt($r, http::CURLOPT_CONNECT_ONLY(), 2);
$k |= http::curl_easy_setopt($r, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($r, http::CURLOPT_HTTPHEADER(), [
    'Sec-WebSocket-Protocol: chat, superchat',
]);
$k |= http::curl_easy_setopt($r, http::CURLOPT_WRITEFUNCTION(), sub {
    my ($buf) = @_;
    my $ws_frame = http::curl_ws_meta($r);
    if($ws_frame){
        is_deeply($ws_frame, {flags => 1, bytesleft => 0, age => 0, offset => 0}, 'ws_frame OK');
    }
    return length($buf);
});
is($k, http::CURLE_OK(), 'curl_easy_setopt');
$k |= http::curl_easy_perform($r);
is($k, http::CURLE_HTTP_RETURNED_ERROR(), 'curl_easy_perform: '.http::curl_easy_strerror($k));

http::curl_easy_cleanup($r);

is_deeply(\@warn, [], 'no warnings');
