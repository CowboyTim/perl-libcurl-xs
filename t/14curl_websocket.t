use Test::More tests => 8;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my $ws_key = `openssl rand -base64 32`;
chomp $ws_key;
my $r = http::curl_easy_init();
my $k;
$k |= http::curl_easy_setopt($r, http::CURLOPT_URL(), 'wss://echo.websocket.org');
$k |= http::curl_easy_setopt($r, http::CURLOPT_CONNECT_ONLY(), 2);
$k |= http::curl_easy_setopt($r, http::CURLOPT_HTTPHEADER(), [
    'Upgrade: websocket',
    'Connection: Upgrade',
    'Sec-WebSocket-Key: '.$ws_key,
    'Sec-WebSocket-Version: 13',
    'Sec-WebSocket-Protocol: chat, superchat',
]);
$k |= http::curl_easy_setopt($r, http::CURLOPT_VERBOSE(), 1);
$k |= http::curl_easy_setopt($r, http::CURLOPT_HEADER(), 1);
$k |= http::curl_easy_setopt($r, http::CURLOPT_NOPROGRESS(), 1);
$k |= http::curl_easy_setopt($r, http::CURLOPT_NOBODY(), 0);
$k |= http::curl_easy_setopt($r, http::CURLOPT_FOLLOWLOCATION(), 1);
$k |= http::curl_easy_setopt($r, http::CURLOPT_SSL_VERIFYPEER(), 0);
$k |= http::curl_easy_setopt($r, http::CURLOPT_SSL_VERIFYHOST(), 0);
$k |= http::curl_easy_setopt($r, http::CURLOPT_CONNECTTIMEOUT(), 10);
$k |= http::curl_easy_setopt($r, http::CURLOPT_TIMEOUT(), 10);
$k |= http::curl_easy_setopt($r, http::CURLOPT_TCP_NODELAY(), 1);
$k |= http::curl_easy_setopt($r, http::CURLOPT_TCP_KEEPALIVE(), 1);
$k |= http::curl_easy_setopt($r, http::CURLOPT_TCP_KEEPIDLE(), 120);
$k |= http::curl_easy_setopt($r, http::CURLOPT_TCP_KEEPINTVL(), 60);
$k |= http::curl_easy_setopt($r, http::CURLOPT_TCP_KEEPIDLE(), 120);
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
is($k, http::CURLE_OK(), 'curl_easy_perform: '.http::curl_easy_strerror($k));

{
    $k |= http::curl_ws_recv($r, my $recv_data, 100, my $ws_frame);
    is($k, http::CURLE_OK(), 'curl_ws_recv: '.http::curl_easy_strerror($k));
    like($recv_data, qr/^Request served by \d+/, 'recv_data: '.($recv_data//"undef"));
    is_deeply($ws_frame, {flags => 1, bytesleft => 0, age => 0, offset => 0}, 'ws_frame');
}
{
    $k |= http::curl_ws_send($r, 'Hello, world! '.time()."\n", 1);
    is($k, http::CURLE_OK(), 'curl_ws_send: '.http::curl_easy_strerror($k));
    my $recv_data;
    foreach my $i (0..9){
        my $l = http::curl_ws_recv($r, $recv_data, 100);
        if($l == http::CURLE_AGAIN()){
            select undef, undef, undef, 0.2;
            next;
        }
    }
    like($recv_data, qr/^Hello, world! \d+/, 'recv_data: '.do{my $s = ($recv_data//"undef"); chomp $s; $s});
}

http::curl_easy_cleanup($r);
