use Test::More tests => 38;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

use Fcntl;
use Fcntl ':mode';
use Socket;
use Socket6;

my @warns;
my $warn = 0;
$SIG{__WARN__} = sub {$warn++; push @warns, $_[0]};

$::o_err_nr = 0;
$::o_cnt = 0;
sub open_sock_sub {
    my ($purpose, $s_family, $s_type, $s_protocol, $addr, $userp) = @_;
    $userp //= {};
    $::o_cnt++;
    print "# OPEN $purpose, $s_family, $s_type, $s_protocol, $userp\n";
    if($purpose == http::CURLSOCKTYPE_IPCXN()){
        my ($port, $ip_address);
        if(length($addr) == 16){
            ($port, $ip_address) = unpack_sockaddr_in($addr);
        } else {
            ($port, $ip_address) = unpack_sockaddr_in6($addr);
        }
        $ip_address = inet_ntop($s_family, $ip_address);
        print "# $purpose, $s_family, $s_type, $s_protocol, $ip_address, $port\n";
        if(socket(my $curlfh, $s_family, $s_type, $s_protocol)){
            # ok!
            print "# OPEN: $curlfh FD=".fileno($curlfh)."\n";
            $userp->{fileno($curlfh)} = $curlfh;
            return $curlfh;
        }
        $::o_err_nr++;
        return http::CURL_SOCKET_BAD();
    }
    return http::CURL_SOCKET_BAD();
}

$::c_err_nr = 0;
$::c_cnt = 0;
sub close_sock_sub {
    my ($curlfh, $userp) = @_;
    my $userfh = $userp->{fileno($curlfh)};
    return 1 unless defined $userfh;
    $::c_cnt++;
    print "# CLOSE $userfh != $curlfh\n";
    close($userfh) or $::c_err_nr++;
    return 0; # 0 means SUCCESS
}

sub real_open_sock_sub {
    open_sock_sub(@_);
}

sub real_close_sock_sub {
    close_sock_sub(@_);
}

@::s_err = ();
$::s_err_nr = 0;
sub setsock_sub {
    my ($curlfh, $purpose, $userp) = @_;
    my $userfh = $userp->{fileno($curlfh)};
    return http::CURL_SOCKOPT_OK() unless defined $userfh;
    return http::CURL_SOCKOPT_OK() if fileno($userfh) == 0;
    print "# SOCKOPT: $userfh != $curlfh, $purpose, FD=".fileno($userfh)."\n";
    local $! = 0;
    my $m = (stat($userfh))[2] // $::s_err_nr++;
    push @::s_err, $! if $!;
    if($m and $m & S_IFSOCK){
        setsockopt($userfh, SOL_SOCKET, SO_REUSEADDR, 1)
            or $::s_err_nr++;
        setsockopt($userfh, SOL_SOCKET, SO_RCVBUF, 64*1024)
            or $::s_err_nr++;
    }
    return http::CURL_SOCKOPT_OK();
}

sub fn_write {
    my ($curl_e, $buffer, $output) = @_;
    $$output .= $buffer;
    return length($buffer);
}

my $k;
my $e = http::curl_easy_init();
$k |= http::curl_easy_setopt($e, http::CURLOPT_CAPATH(), '/tmp/crltst.'.$<.'.'.$$);
$k |= http::curl_easy_setopt($e, http::CURLOPT_CAINFO(), '/tmp/crltst.'.$<.'.'.$$);
$k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYPEER(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_VERIFYHOST(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'https://www.example.com/');
$k |= http::curl_easy_setopt($e, http::CURLOPT_WRITEFUNCTION(), \&fn_write);
$k |= http::curl_easy_setopt($e, http::CURLOPT_WRITEDATA(), \(my $out = ''));
$k |= http::curl_easy_setopt($e, http::CURLOPT_OPENSOCKETFUNCTION(), \&open_sock_sub);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_OPENSOCKETDATA(), my $fh = {});
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_CLOSESOCKETFUNCTION(), \&close_sock_sub);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_CLOSESOCKETDATA(), $fh);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SOCKOPTFUNCTION(), \&setsock_sub);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_SOCKOPTDATA(), $fh);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
$k |= http::curl_easy_perform($e);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK '.http::curl_easy_strerror($k));
is($::o_err_nr, 0, 'error number: '.$::o_err_nr);
is($::c_err_nr, 0, 'error number: '.$::c_err_nr);
ok($::o_cnt >= 1, 'callback function called: ok open:'.$::o_cnt);
ok($::c_cnt >= 0, 'callback function called: ok close:'.$::c_cnt);
is($::s_err_nr, 0, 'error number: '.$::s_err_nr);
is_deeply(\@::s_err, [], 'no errors: '.join(',',@::s_err));
$k = 0;
print "# SET OPENSOCKETFUNCTION\n";
$k |= http::curl_easy_setopt($e, http::CURLOPT_OPENSOCKETFUNCTION(), \&real_open_sock_sub);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_OPENSOCKETDATA(), $fh);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK EMPTY OPENSOCKETDATA');
print "# SET CLOSESOCKETFUNCTION\n";
$k |= http::curl_easy_setopt($e, http::CURLOPT_CLOSESOCKETFUNCTION(), \&real_close_sock_sub);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_CLOSESOCKETDATA(), $fh);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK EMPTY CLOSESOCKETDATA');
$k |= http::curl_easy_perform($e);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK');
ok($::o_cnt >= 1, 'callback function called: ok open:'.$::o_cnt);
ok($::c_cnt >= 0, 'callback function called: ok close:'.$::c_cnt);
is($::s_err_nr, 0, 'error number: '.$::s_err_nr);
is_deeply(\@::s_err, [], 'no errors: '.join(',',@::s_err));
is($out, '', 'no body: '.$out);
$k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 0);
$k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY());
my $d = http::curl_easy_duphandle($e);
$k = 0;
$k |= http::curl_easy_perform($e);
isnt($out, '', 'body');
like($out, qr/<!doctype html>/, 'body');
my $sz = length($out);
http::curl_easy_cleanup($e);
undef $e;
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK, after https');
ok($::o_cnt >= 1, 'callback function called: ok open:'.$::o_cnt);
ok($::c_cnt >= 1, 'callback function called: ok close:'.$::c_cnt);
is($::s_err_nr, 0, 'error number: '.$::s_err_nr);
is_deeply(\@::s_err, [], 'no errors: '.join(',',@::s_err));
$k |= http::curl_easy_perform($d);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK, on dup, after https, perform');
http::curl_easy_cleanup($d);
undef $d;
ok($::o_cnt >= 2, 'callback function called: ok open:'.$::o_cnt);
ok($::c_cnt >= 2, 'callback function called: ok close:'.$::c_cnt);
isnt($out, '', 'body');
like($out, qr/<!doctype html>/, 'body');
my $nz = length($out);
ok($nz > $sz, 'body size increased');
is($warn, 0, 'no warnings: '.join(',',@warns));
