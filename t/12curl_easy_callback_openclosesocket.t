use Test::More tests => 28;
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
    $userp //= "";
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
            return fileno($curlfh);
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
    $::c_cnt++;
    print "# CLOSE $curlfh, $userp\n";
    close($curlfh) or $::c_err_nr++;
    return 0; # 0 means SUCCESS
}

sub real_open_sock_sub {
    my ($curlfh, $purpose, $userp) = @_;
    $::o_cnt++;
    return http::CURLE_OK();
}

sub real_close_sock_sub {
    my ($curlfh, $userp) = @_;
    $::c_cnt++;
    close($curlfh) or $::c_err_nr++;
    return 0; # 0 means SUCCESS
}

sub fn_write {
    my ($curl_e, $buffer, $output) = @_;
    $$output .= $buffer;
    return length($buffer);
}

my $k;
my $e = http::curl_easy_init();
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
$k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
$k |= http::curl_easy_perform($e);
is($k, http::CURLE_COULDNT_CONNECT(), 'http::curl_easy_perform() return CURLE_COULDNT_CONNECT');
is($::o_err_nr, 0, 'error number: '.$::o_err_nr);
is($::c_err_nr, 0, 'error number: '.$::c_err_nr);
is($::o_cnt, 2, 'callback function called: ok open:'.$::o_cnt);
is($::c_cnt, 2, 'callback function called: ok close:'.$::c_cnt);
$k = 0;
print "# SET OPENSOCKETFUNCTION\n";
$k |= http::curl_easy_setopt($e, http::CURLOPT_OPENSOCKETFUNCTION(), \&real_open_sock_sub);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_OPENSOCKETDATA());
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK EMPTY OPENSOCKETDATA');
print "# SET CLOSESOCKETFUNCTION\n";
$k |= http::curl_easy_setopt($e, http::CURLOPT_CLOSESOCKETFUNCTION(), \&real_close_sock_sub);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
$k |= http::curl_easy_setopt($e, http::CURLOPT_CLOSESOCKETDATA());
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK EMPTY CLOSESOCKETDATA');
$k |= http::curl_easy_perform($e);
is($k, http::CURLE_OK(), 'http::curl_easy_perform() return CURLE_OK');
is($::o_cnt, 2, 'callback function called: ok open:'.$::o_cnt);
is($::c_cnt, 2, 'callback function called: ok close:'.$::c_cnt);
is($out, '', 'no body: '.$out);
$k |= http::curl_easy_setopt($e, http::CURLOPT_SOCKOPTDATA(), \(my $up = ''));
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
is($::o_cnt, 2, 'callback function called: ok open:'.$::o_cnt);
is($::c_cnt, 2, 'callback function called: ok close:'.$::c_cnt);
$k |= http::curl_easy_setopt($d, http::CURLOPT_SOCKOPTDATA(), \(my $ru = ''));
$k |= http::curl_easy_perform($d);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK, on dup, after https, perform');
isnt($out, '', 'body');
like($out, qr/<!doctype html>/, 'body');
my $nz = length($out);
ok($nz > $sz, 'body size increased');
is($warn, 0, 'no warnings: '.join(',',@warns));
http::curl_easy_cleanup($d);
