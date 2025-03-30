use Test::More tests => 36;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

use Fcntl;
use Fcntl ':mode';
use Socket;

my @warns;
my $warn = 0;
$SIG{__WARN__} = sub {$warn++; push @warns, $_[0]};

my $err_nr = 0;
$::fh = undef;
$::k_cnt = 0;
my @flags;
my @scks;
sub setsock_sub {
    my ($curlfh, $purpose, $userp) = @_;
    print "# $curlfh, $purpose, $userp\n";
    $::k_cnt++;
    return http::CURL_SOCKOPT_OK() if fileno($curlfh) == 0;
    print "# $curlfh, $purpose, $userp, FD=".fileno($curlfh)."\n";
    if($curlfh){
        open(my $fh, ">&", $curlfh)
            or do { $err_nr++; return http::CURL_SOCKOPT_ERROR() };
        my $fd = fileno($curlfh);
        $::fh //= do{open(my $fh, "+<&=$fd")
            or do { $err_nr++; return http::CURL_SOCKOPT_ERROR() }; $fh};
        close($fh) or $err_nr++;
    } else {
        $err_nr++;
    }
    my $flags = fcntl($curlfh, F_GETFL, 0) or $err_nr++;
    my $m = (stat($curlfh))[2];
    if($m & S_IFSOCK){
        setsockopt($curlfh, SOL_SOCKET, SO_REUSEADDR, 1)
            or $err_nr++;
        setsockopt($curlfh, SOL_SOCKET, SO_RCVBUF, 64*1024)
            or $err_nr++;
        push @scks, $m;
    }
    push @scks, $m;
    push @flags, $flags if defined $flags;
    if(ref($userp) 
            and $$userp eq 'ABC'
            and $::k_cnt >= 1
            and $purpose == http::CURLSOCKTYPE_IPCXN()) {
        return http::CURL_SOCKOPT_ERROR();
    }
    return http::CURL_SOCKOPT_OK();
}

$::o_cnt = 0;
sub open_sock_sub {
    my ($purpose, $family, $socktype, $protocol, $addr, $userp) = @_;
    print "# $::o_cnt: $purpose, $family, $socktype, $protocol\n";
    $::o_cnt++;
    return http::CURL_SOCKET_BAD() if $::o_cnt <= 2;
    return if $::o_cnt == 3;
    return http::CURL_SOCKET_BAD() if $::o_cnt > 3;
}

$::c_cnt = 0;
sub close_sock_sub {
    my ($curlfh, $userp) = @_;
    $::c_cnt++;
    return 0; # 0 means SUCCESS
}

sub fn_write {
    my ($curl_e, $buffer, $output) = @_;
    $$output .= $buffer;
    return length($buffer);
}

my $k;
my $e = http::curl_easy_init();
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL());
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'https://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), undef);
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'https://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), my $def);
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'https://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_WRITEFUNCTION(), \&fn_write);
$k |= http::curl_easy_setopt($e, http::CURLOPT_WRITEDATA(), \(my $out = ''));
$k |= http::curl_easy_setopt($e, http::CURLOPT_OPENSOCKETFUNCTION(), \&open_sock_sub);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_OPENSOCKETDATA(), {});
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_CLOSESOCKETFUNCTION(), \&close_sock_sub);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_CLOSESOCKETDATA(), {});
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SOCKOPTFUNCTION(), \&setsock_sub);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SOCKOPTDATA(), \(my $rt = 'ABC'));
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
$k |= http::curl_easy_perform($e);
is($k, http::CURLE_COULDNT_CONNECT(), 'http::curl_easy_perform() return CURLE_COULDNT_CONNECT');
is($err_nr, 0, 'error number: '.$err_nr);
$k = 0;
$k |= http::curl_easy_setopt($e, http::CURLOPT_OPENSOCKETFUNCTION());
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_OPENSOCKETDATA());
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_CLOSESOCKETFUNCTION());
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_CLOSESOCKETDATA());
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_perform($e);
is($k, http::CURLE_ABORTED_BY_CALLBACK(), 'http::curl_easy_perform() return CURLE_ABORTED_BY_CALLBACK');
is($::k_cnt, 4, 'callback function called: ok sockopt:'.$::k_cnt);
is($::o_cnt, 4, 'callback function called: ok open:'.$::o_cnt);
is($::c_cnt, 0, 'callback function called: ok close:'.$::c_cnt);
is($out, '', 'no body: '.$out);
$::k_cnt = 0;
$::o_cnt = 0;
$::c_cnt = 0;
$k |= http::curl_easy_setopt($e, http::CURLOPT_SOCKOPTDATA(), \(my $up = ''));
$k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY());
my $d = http::curl_easy_duphandle($e);
$::k_cnt = 0;
$k = 0;
$k |= http::curl_easy_perform($e);
isnt($out, '', 'body');
like($out, qr/<!doctype html>/, 'body');
my $sz = length($out);
http::curl_easy_cleanup($e);
undef $e;
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK, after https');
ok($::k_cnt >= 1, 'callback function called: ok sockopt:'.$::k_cnt);
is($::o_cnt, 0, 'callback function called: ok open:'.$::o_cnt);
is($::c_cnt, 0, 'callback function called: ok close:'.$::c_cnt);
$k |= http::curl_easy_setopt($d, http::CURLOPT_SOCKOPTDATA(), \(my $ru = ''));
$::k_cnt = 0;
$k |= http::curl_easy_perform($d);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK, on dup, after https');
http::curl_easy_cleanup($d);
ok($::k_cnt >= 1, 'callback function called: ok successes, 2x:'.$::k_cnt);
isnt($out, '', 'body');
like($out, qr/<!doctype html>/, 'body');
my $nz = length($out);
ok($nz > $sz, 'body size increased');
is($warn, 0, 'no warnings: '.join(',',@warns));
local $! = 0;
close($::fh);
is($!, '', 'close: '.$!);
local $! = 0;
close($::fh);
is($!, 'Bad file descriptor', 'close: '.$!);
is($err_nr, 0, 'error number: '.$err_nr);
ok(scalar(@flags) >= 4, 'got flags >=4');
is($flags[0] & O_RDWR, O_RDWR, 'flags: O_RDWR');
is($flags[0] & O_NONBLOCK, O_NONBLOCK, 'flags: O_NONBLOCK');
