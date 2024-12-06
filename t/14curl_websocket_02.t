use Test::More tests => 3;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my $ws_key = `openssl rand -base64 32`;
chomp $ws_key;
my $r = http::curl_easy_init();
my $k;
$k |= http::curl_easy_setopt($r, http::CURLOPT_URL(), 'https://echo.websocket.org');
$k |= http::curl_easy_setopt($r, http::CURLOPT_CONNECT_ONLY(), 0);
$k |= http::curl_easy_setopt($r, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($r, http::CURLOPT_CUSTOMREQUEST(), "GET");
$k |= http::curl_easy_setopt($r, http::CURLOPT_HEADER(), 0);
$k |= http::curl_easy_setopt($r, http::CURLOPT_HTTPHEADER(), [
    'Upgrade: websocket',
    'Connection: Upgrade',
    'Sec-WebSocket-Key: '.$ws_key,
    'Sec-WebSocket-Version: 13',
    'Sec-WebSocket-Protocol: chat, superchat',
]);
$k |= http::curl_easy_setopt($r, http::CURLOPT_WRITEFUNCTION(), sub {
    my ($buf) = @_;
    if($buf =~ /^HTTP\/1.1 101 Switching Protocols/){
        print "SWITCHING PROTOCOLS\n";
        $k |= http::curl_easy_setopt($r, http::CURLOPT_URL(), 'wss://echo.websocket.org');
        $k |= http::curl_easy_setopt($r, http::CURLOPT_CONNECT_ONLY(), 2);
        croak("curl_easy_setopt: ".http::curl_easy_strerror($k)) if $k != http::CURLE_OK();
    }
    return length($buf);
});
$k |= http::curl_easy_setopt($r, http::CURLOPT_UPLOAD(), 1);
$k |= http::curl_easy_setopt($r, http::CURLOPT_READFUNCTION(), sub {
    my ($sz) = @_;
    $k |= http::curl_easy_setopt($r, http::CURLOPT_UPLOAD(), 0);
    die "curl_easy_setopt 1: ".http::curl_easy_strerror($k) if $k != http::CURLE_OK();
    $k |= http::curl_easy_setopt($r, http::CURLOPT_READFUNCTION(), undef);
    die "curl_easy_setopt 2: ".http::curl_easy_strerror($k) if $k != http::CURLE_OK();
    return "Hello, world! ".time()."\n";
});
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
my $m = http::curl_multi_init();
$k |= http::curl_multi_add_handle($m, $r);
is($k, http::CURLE_OK(), 'curl_easy_setopt');
$k |= http::curl_multi_perform($m, my $running);
while($running){
    my $mc = http::curl_multi_wait($m, 0, 1000);
    if($mc != http::CURLM_OK()){
        last;
    }
    my $l = http::curl_multi_perform($m, $running);
    croak("curl_multi_perform: ".http::curl_easy_strerror($l)) if $l != http::CURLE_OK();
}
is($k, http::CURLE_OK(), 'curl_easy_perform: '.http::curl_easy_strerror($k));

http::curl_easy_cleanup($r);
