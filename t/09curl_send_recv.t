use Test::More tests => 46;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

my $r = http::curl_easy_init();
isnt($r, undef, 'http::curl_easy_init(): return ok');
is(ref($r), 'http::curl::easy', 'http::curl_easy_init(): return type ok');
isnt($$r, undef, 'http::curl_easy_init(): return value ok');

{
    my $e1 = http::curl_easy_setopt($r, http::CURLOPT_URL(), 'http://www.example.com');
    is($e1, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok');
    my $e2 = http::curl_easy_setopt($r, http::CURLOPT_CONNECT_ONLY(), 1);
    is($e2, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok');
    my $res = http::curl_easy_perform($r);
    is($res, http::CURLE_OK(), 'http::curl_easy_perform(): return value ok');
}
my $r_s = http::curl_easy_getinfo($r, http::CURLINFO_ACTIVESOCKET());
like($r_s, qr/\d+/, 'http::curl_easy_getinfo(): return value ok: FD='.$r_s);
my $rin = '';
vec($rin, $r_s, 1) = 1;
{
    my $ok = select my $rout = $rin, my $wout = $rin, undef, 5;
    is($ok, 1, 'select(): return value ok');
    is(vec($rout, $r_s, 1), 0, 'select(): return value ok 1: NO ROUT='.$r_s);
    is(vec($wout, $r_s, 1), 1, 'select(): return value ok 1: OK WOUT='.$r_s);
    my $rv = http::curl_easy_send($r, "GET / HTTP/1.1\r\nAccept: */*\r\nHost: www.example.com\r\nAccept-Encoding: identity\r\n\r\n");
    is($rv, http::CURLE_OK(), 'http::curl_easy_send(): return value ok: rv='.$rv);
}
{
    my $ok = select my $rout = $rin, my $wout = $rin, undef, 5;
    is($ok, 1, 'select(): return value ok');
    is(vec($rout, $r_s, 1), 0, 'select(): return value ok 2: NO ROUT='.$r_s);
    is(vec($wout, $r_s, 1), 1, 'select(): return value ok 2: OK WOUT='.$r_s);
    my $rt = http::curl_easy_recv($r, my $data = "", 1024);
    is($rt, http::CURLE_AGAIN(), 'http::curl_easy_recv(): return EAGAIN: rt='.$rt);
    is(http::curl_easy_strerror($rt), 'Socket not ready for send/recv', 'http::curl_easy_strerror(): Socket not ready for send/recv');
}
{
    my $ok = select my $rout = $rin, undef, undef, 5;
    is($ok, 1, 'select(): return value ok');
    is(vec($rout, $r_s, 1), 1, 'select(): return value ok 3: OK ROUT='.$r_s);
    my $rt = http::curl_easy_recv($r, my $data = "", 17);
    print "# rt=$rt\n";
    is($rt, 0, 'http::curl_easy_recv(): return value ok 3: rt='.$rt)
        or diag(http::curl_easy_strerror($rt));
    like($data, qr/HTTP\/1.1 200 OK/, 'http::curl_easy_recv(): return value ok: OK HTTP 200');
}
{
    my $ok = select my $rout = $rin, undef, undef, 5;
    is($ok, 1, 'select(): return value ok');
    is(vec($rout, $r_s, 1), 1, 'select(): return value ok 3: OK ROUT='.$r_s);
    my $rt = http::curl_easy_recv($r, my $data, 2048);
    print "# rt=$rt\n";
    is($rt, 0, 'http::curl_easy_recv(): return value ok 3: rt='.$rt)
        or diag(http::curl_easy_strerror($rt));
    like($data, qr/Content-Type: text\/html/, 'http::curl_easy_recv(): return value ok: OK BODY');
}
{
    my $d = http::curl_easy_duphandle($r);
    my $res = http::curl_easy_perform($d);
    is($res, http::CURLE_OK(), 'http::curl_easy_perform(): return value ok');
    my $r_s = http::curl_easy_getinfo($d, http::CURLINFO_ACTIVESOCKET());
    like($r_s, qr/\d+/, 'http::curl_easy_getinfo(): return value ok: FD='.$r_s);
    my $rin = '';
    vec($rin, $r_s, 1) = 1;
    {
        my $ok = select my $rout = $rin, my $wout = $rin, undef, 5;
        is($ok, 1, 'select(): return value ok');
        is(vec($rout, $r_s, 1), 0, 'select(): return value ok 4: OK ROUT='.$r_s);
        is(vec($wout, $r_s, 1), 1, 'select(): return value ok 4: OK WOUT='.$r_s);
        my $rv = http::curl_easy_send($d, "GET / HTTP/1.0\r\nAccept: */*\r\nHost: www.example.com\r\nAccept-Encoding: identity\r\n\r\n");
        is($rv, http::CURLE_OK(), 'http::curl_easy_send(): return value ok: rv='.$rv);
    }
    {
        my $ok = select my $rout = $rin, undef, undef, 5;
        is($ok, 1, 'select(): return value ok');
        is(vec($rout, $r_s, 1), 1, 'select(): return value ok 5: OK ROUT='.$r_s);
        my $rt = http::curl_easy_recv($d, my $data, 17);
        is($rt, http::CURLE_OK(), 'http::curl_easy_recv(): return value ok 5: rt='.$rt);
        is(http::curl_easy_strerror($rt), 'No error', 'http::curl_easy_strerror(): No error');
        like($data, qr/HTTP\/1.0 200 OK/, 'http::curl_easy_recv(): return value ok: OK HTTP 200');
    }
    {
        my $ok = select my $rout = $rin, undef, undef, 5;
        is($ok, 1, 'select(): return value ok');
        is(vec($rout, $r_s, 1), 1, 'select(): return value ok 5: OK ROUT='.$r_s);
        my $rt = http::curl_easy_recv($d, my $data, 2048);
        is($rt, http::CURLE_OK(), 'http::curl_easy_recv(): return value ok 5: rt='.$rt);
        is(http::curl_easy_strerror($rt), 'No error', 'http::curl_easy_strerror(): No error');
        like($data, qr/Content-Type: text\/html/, 'http::curl_easy_recv(): return value ok: OK BODY');
    }
    is(http::curl_easy_cleanup($d), undef, 'http::curl_easy_cleanup(): return value ok');
    is($$d, undef, 'http::curl_easy_cleanup(): return value ok: r='.$d);
}
is(http::curl_easy_cleanup($r), undef, 'http::curl_easy_cleanup(): return value ok');
is($$r, undef, 'http::curl_easy_cleanup(): return value ok: r='.$r);

is_deeply(\@warn, [], 'no warnings');
