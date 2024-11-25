use Test::More tests => 9;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my $warn = 0;
$SIG{__WARN__} = sub {$warn++};

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
my $nr_of_calls = 0;
my $nr_err = 0;
my $ws_frame;
$k |= http::curl_easy_setopt($r, http::CURLOPT_WRITEDATA(), my $def = "");
$k |= http::curl_easy_setopt($r, http::CURLOPT_WRITEFUNCTION(), sub {
    my ($c_e, $buf, $userp) = @_;
    $nr_err++ unless "$c_e" eq "$r" and defined $userp;
    $nr_of_calls++;
    my $ws_f = http::curl_ws_meta($c_e);
    $ws_frame ||= $ws_f if $ws_f;
    if($buf =~ /^HTTP\/1.1 101 Switching Protocols/){
        print "SWITCHING PROTOCOLS\n";
        $k |= http::curl_easy_setopt($r, http::CURLOPT_URL(), 'wss://echo.websocket.org');
        $k |= http::curl_easy_setopt($r, http::CURLOPT_CONNECT_ONLY(), 2);
        croak("curl_easy_setopt: ".http::curl_easy_strerror($k)) if $k != http::CURLE_OK();
    }
    return length($buf);
});
$k |= http::curl_easy_setopt($r, http::CURLOPT_UPLOAD(), 1);
my $nr_read_err = 0;
my $nr_reads = 0;
$k |= http::curl_easy_setopt($r, http::CURLOPT_READDATA(), my $abc = "");
is($k, http::CURLE_OK(), 'curl_easy_setopt');
$k = 0;
$k |= http::curl_easy_setopt($r, http::CURLOPT_READFUNCTION(), sub {
    my ($c_e, $sz, $userp) = @_;
    $nr_read_err++ unless "$c_e" eq "$r" and defined $userp and "$userp" eq "$abc";
    $nr_reads++;
    $k |= http::curl_easy_setopt($r, http::CURLOPT_UPLOAD(), 0);
    die "curl_easy_setopt 1: ".http::curl_easy_strerror($k) if $k != http::CURLE_OK();
    print "CLEAR\n";
    $k |= http::curl_easy_setopt($r, http::CURLOPT_READFUNCTION());
    die "curl_easy_setopt 2: ".http::curl_easy_strerror($k) if $k != http::CURLE_OK();
    $k |= http::curl_easy_setopt($r, http::CURLOPT_READDATA());
    die "curl_easy_setopt 3: ".http::curl_easy_strerror($k) if $k != http::CURLE_OK();
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
is($k, http::CURLE_OK(), 'curl_easy_setopt, running curl_multi_perform');
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
is($nr_err, 0, 'writefunction called with correct arguments');
is($nr_of_calls, 2, 'writefunction called once');
is($nr_read_err, 0, 'readfunction called with correct arguments');
is($nr_reads, 1, 'readfunction called once');
is($warn, 0, 'no warnings');
