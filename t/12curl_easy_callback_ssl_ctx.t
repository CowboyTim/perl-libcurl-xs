use Test::More tests => 13;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warns;
my $warn = 0;
$SIG{__WARN__} = sub {$warn++; push @warns, $_[0]};

my $ssl_ctx_ok = 1;
eval {
    require Net::SSLeay;
    Net::SSLeay::load_error_strings();
    Net::SSLeay::ERR_clear_error();
    Net::SSLeay::SSLeay_add_ssl_algorithms();
    Net::SSLeay::randomize();
    Net::SSLeay::ENGINE_load_builtin_engines();
    Net::SSLeay::ENGINE_register_all_complete();
    Net::SSLeay::ERR_clear_error();
};
if($@){
    $ssl_ctx_ok = 0;
}
if($ssl_ctx_ok){
    is($ssl_ctx_ok, 1, 'Net::SSLeay loaded');
} else {
    is($ssl_ctx_ok, 0, 'WARN: Net::SSLeay not loaded, not running SSL_CTX tests');
}

{
    my $k;
    my $e = http::curl_easy_init();
    $::k_cnt = 0;
    $::e_cnt = 0;
    my $check_var_string;
    sub code_sub {
        my ($h, $sslctx, $userp) = @_;
        print "# code_sub called: $check_var_string -> $h, $sslctx\n";
        $::e_cnt++ if !defined $h || !defined $sslctx || !ref($h) || "$h" ne $check_var_string;
        if($ssl_ctx_ok){
        Net::SSLeay::CTX_set_info_callback($sslctx, sub {
            my ($ssl,$where,$ret,$data) = @_;
            my $info_s;
            if($where == Net::SSLeay::CB_LOOP()) {
                $info_s = "HANDSHAKE LOOP: $ret:".Net::SSLeay::state_string_long($ret)." ".sprintf("%x",$ssl);
            } elsif($where == Net::SSLeay::CB_ALERT()) {
                my $alert_type = Net::SSLeay::alert_type_string_long($ret);
                my $alert_desc = Net::SSLeay::alert_desc_string_long($ret);
                $info_s = "ALERT: ".($alert_type//'undef').", ".($alert_desc//'undef');
            } elsif($where == Net::SSLeay::CB_CONNECT_EXIT()){
                $info_s = "CONNECT EXIT: $ret:".Net::SSLeay::state_string_long($ssl);
            } elsif($where == Net::SSLeay::CB_CONNECT_LOOP()){
                $info_s = "CONNECT LOOP: $ret:".Net::SSLeay::state_string_long($ssl);
            } elsif($where == Net::SSLeay::CB_ACCEPT_EXIT()){
                $info_s = "ACCEPT EXIT: $ret:".Net::SSLeay::state_string_long($ssl);
            } elsif($where == Net::SSLeay::CB_ACCEPT_LOOP()){
                $info_s = "ACCEPT LOOP: $ret:".Net::SSLeay::state_string_long($ssl);
            } elsif($where == Net::SSLeay::CB_READ()) {
                $info_s = "READ: $ret:".Net::SSLeay::state_string_long($ssl);
            } elsif($where == Net::SSLeay::CB_READ_ALERT()) {
                $info_s = "READ ALERT: $ret:".Net::SSLeay::state_string_long($ssl);
            } elsif($where == Net::SSLeay::CB_WRITE()) {
                $info_s = "WRITE: $ret:".Net::SSLeay::state_string_long($ssl);
            } elsif($where == Net::SSLeay::CB_WRITE_ALERT()) {
                $info_s = "WRITE ALERT: $ret:".Net::SSLeay::state_string_long($ssl);
            } elsif($where == Net::SSLeay::CB_HANDSHAKE_START()) {
                $info_s = "HANDSHAKE START ".sprintf("%x",$ssl);
            } elsif($where == Net::SSLeay::CB_HANDSHAKE_DONE()) {
                $info_s = "HANDSHAKE DONE ".sprintf("%x",$ssl);
            } else {
                $info_s = "WHERE: $where, RET: $ret";
            }
            push @{$userp //= []}, "$info_s\n";
        });
        } else {
            push @{$userp //= []}, "Net::SSLeay not available, no SSL_CTX info callback";
        }
        $::k_cnt++;
        return http::CURLE_OK();
    };
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_SSL_CTX_FUNCTION(), \&code_sub);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
    $check_var_string = "$e";
    $k |= http::curl_easy_perform($e);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK');
    is($::k_cnt, 0, 'callback function called: ok successes:'.$::k_cnt);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'https://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    my $d = http::curl_easy_duphandle($e);
    $check_var_string = "$e";
    $k |= http::curl_easy_perform($e);
    http::curl_easy_cleanup($e);
    undef $e;
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK, on DUP, after https');
    is($::k_cnt, 1, 'callback function called: ok successes:'.$::k_cnt);
    print "# doing perform on DUP handle\n";
    $check_var_string = "$d";
    $k |= http::curl_easy_perform($d);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK, on DUP, after https');
    http::curl_easy_cleanup($d);
    is($::k_cnt, 2, 'callback function called: ok successes, 2x:'.$::k_cnt);
    is($::e_cnt, 0, 'callback function called: no errors logged:'.$::e_cnt);
}

is($warn, 0, 'no warnings: '.join(',',@warns));
