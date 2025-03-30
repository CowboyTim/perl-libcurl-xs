use Test::More tests => 17;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my $warn = 0;
$SIG{__WARN__} = sub {$warn++};

my $do_ws = (http::curl_version() =~ s/.*libcurl\/(\d+)\.(\d+)\.\d+.*//gr and $1>=7 and $2>=78)?1:0;
SKIP: {
skip "libcurl < 7.86.0 does not support websocket meta data", 15
    unless $do_ws;

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
$k |= http::curl_easy_setopt($r, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($r, http::CURLOPT_HEADER(), 0);
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
is($k, http::CURLE_OK(), 'curl_easy_setopt');
$k |= http::curl_easy_setopt($r, http::CURLOPT_WRITEDATA(), my $abc = "");
is($k, http::CURLE_OK(), 'curl_easy_setopt: '.http::curl_easy_strerror($k));
my $nr_of_calls = 0;
my $nr_err = 0;
my $ws_frame;
$k |= http::curl_easy_setopt($r, http::CURLOPT_WRITEFUNCTION(), sub {
    my ($c_e, $buf, $userp) = @_;
    $nr_err++ unless "$c_e" eq "$r" and defined $userp;
    $nr_of_calls++;
    my $ws_f = http::curl_ws_meta($c_e);
    $ws_frame ||= $ws_f if $ws_f;
    return length($buf);
});
is($k, http::CURLE_OK(), 'curl_easy_setopt: '.http::curl_easy_strerror($k));
is($nr_err, 0, 'writefunction called with correct arguments');
is($nr_of_calls, 0, 'writefunction not called yet');
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
is_deeply($ws_frame, undef, 'ws_frame OK: not set as writefunction not called');
is($nr_err, 0, 'writefunction called with correct arguments');
is($nr_of_calls, 0, 'writefunction not called yet');
http::curl_easy_cleanup($r);
}
is($warn, 0, 'no warnings');
