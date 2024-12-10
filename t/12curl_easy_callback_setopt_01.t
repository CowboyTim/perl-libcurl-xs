use Test::More tests => 31;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warns;
my $warn = 0;
$SIG{__WARN__} = sub {$warn++; push @warns, $_[0]};

$::fh = undef;
$::k_cnt = 0;
sub setsock_sub {
    my ($curlfd, $purpose, $userp) = @_;
    print "# $curlfd, $purpose, $userp\n";
    if($curlfd){
        $::fh //= do{open(my $fh, "+<&=$curlfd") or die "open: $!"; $fh};
    }
    if(ref($userp) 
            and $$userp eq 'ABC'
            and $::k_cnt >= 1
            and $purpose == http::CURLSOCKTYPE_IPCXN()) {
        $::k_cnt++;
        return http::CURL_SOCKOPT_ERROR();
    }
    $::k_cnt++;
    return http::CURL_SOCKOPT_OK();
}

$::o_cnt = 0;
sub open_sock_sub {
    my ($curlfd, $purpose, $userp) = @_;
    $::o_cnt++;
    return http::CURLE_OK();
}

$::c_cnt = 0;
sub close_sock_sub {
    my ($curlfd, $userp) = @_;
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
is($k, http::CURLE_ABORTED_BY_CALLBACK(), 'http::curl_easy_perform() return CURLE_OK');
is($::k_cnt, 4, 'callback function called: ok sockopt:'.$::k_cnt);
is($::o_cnt, 2, 'callback function called: ok open:'.$::o_cnt);
is($::c_cnt, 2, 'callback function called: ok close:'.$::c_cnt);
is($out, '', 'no body: '.$out);
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
is($::k_cnt, 1, 'callback function called: ok sockopt:'.$::k_cnt);
is($::o_cnt, 2, 'callback function called: ok open:'.$::o_cnt);
is($::c_cnt, 2, 'callback function called: ok close:'.$::c_cnt);
$k |= http::curl_easy_setopt($d, http::CURLOPT_SOCKOPTDATA(), \(my $ru = ''));
$::k_cnt = 0;
$k |= http::curl_easy_perform($d);
is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK, on dup, after https');
http::curl_easy_cleanup($d);
is($::k_cnt, 1, 'callback function called: ok successes, 2x:'.$::k_cnt);
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
