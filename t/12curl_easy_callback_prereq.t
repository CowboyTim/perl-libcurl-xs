use Test::More tests => 29;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

{
    my $k;
    my $e = http::curl_easy_init();
    is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = "");
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT string');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = \(""));
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT string ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = {});
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT hash ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = []);
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT hash ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = sub{});
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref');
    http::curl_easy_cleanup($e);
}

{
    my $k_cnt = 0;
    my $info;
    sub code_sub {
        my ($p_ip, $l_ip, $p_port, $l_port, $userp) = @_;
        $k_cnt++;
        $info //= "$l_ip/$l_port->$p_ip/$p_port OK";
        push @{$userp //= []}, $info;
        return http::CURL_PREREQFUNC_OK();
    };
    my $k;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), \&code_sub);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQDATA(), my $rt = []);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code sub, no var, no closure');
    is($k_cnt, 1, 'callback function called: ok successes:'.$k_cnt);
    isnt($info, '', 'callback function called: ok info:'.$info);
    is_deeply($rt, [$info], 'callback function called: ok data:'.join(',',@$rt));
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQDATA(), my $up = []);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code sub, no var, no closure');
    http::curl_easy_cleanup($e);
    is($k_cnt, 2, 'callback function called: ok successes:'.$k_cnt);
    isnt($info, '', 'callback function called: ok info:'.$info);
    is_deeply($up, [$info], 'callback function called: ok data:'.join(',',@$up));
    is_deeply($rt, [$info], 'callback function called: ok data:'.join(',',@$rt));
}

{
    my $k;
    my $n = 0;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = sub {
        my ($p_ip, $l_ip, $p_port, $l_port, $userp) = @_;
        $n++ if defined $userp;
        return http::CURL_PREREQFUNC_OK();
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, var, closure');
    http::curl_easy_cleanup($e);
    is($n, 0, 'callback function called: no errors');
}

{
    my $k;
    my $n = 0;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), sub {
        my ($p_ip, $l_ip, $p_port, $l_port, $userp) = @_;
        $n++ if defined $userp;
        if($userp eq 'abc') {
            $userp = "def";
        }
        return http::CURL_PREREQFUNC_OK();
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQDATA(), my $data = 'abc');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, no var, no closure');
    http::curl_easy_cleanup($e);
    is($n, 1, 'callback function called: no errors');
    is($data, 'abc', 'callback function called: no errors');
}

{
    my $k;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), sub {
        return http::CURL_PREREQFUNC_OK();
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    my $t = http::curl_easy_setopt($e, http::CURLOPT_PREREQDATA(), 'abc');
    $k |= http::curl_easy_perform($e);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, no var, no closure: '.http::curl_easy_strerror($k));
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $k_cnt = 0;
    my $e = http::curl_easy_init();
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = sub {
        my ($p_ip, $l_ip, $p_port, $l_port) = @_;
        die;
        return http::CURL_PREREQFUNC_OK();
    });
    $abc = undef;
    my $info;
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), sub {
        my ($p_ip, $l_ip, $p_port, $l_port, $userp) = @_;
        $info = "$l_ip/$l_port->$p_ip/$p_port OK";
        $k_cnt+=1;
        push @{$userp //= []}, $info;
        return http::CURL_PREREQFUNC_OK();
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQDATA(), my $rt = []);
    $k |= http::curl_easy_perform($e);
    is($k_cnt, 1, 'callback function called: ok successes:'.$k_cnt);
    isnt($info, '', 'callback function called: ok info:'.$info);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, no var, no closure: '.http::curl_easy_strerror($k));
    http::curl_easy_cleanup($e);
    is_deeply($rt, [$info], 'callback function called: ok data:'.join(',',@$rt));
}

{
    my $k;
    my $e = http::curl_easy_init();
    my $info;
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), sub {
        my ($p_ip, $l_ip, $p_port, $l_port) = @_;
        $info = "$l_ip/$l_port->$p_ip/$p_port ABORT";
        return http::CURL_PREREQFUNC_ABORT();
    });
    $k |= http::curl_easy_perform($e);
    isnt($info, '', 'callback function called: ok info:'.$info);
    is($k, http::CURLE_ABORTED_BY_CALLBACK(), 'http::curl_easy_setopt() return CURLE_ABORTED_BY_CALLBACK code ref, no var, no closure: '.http::curl_easy_strerror($k));
    http::curl_easy_cleanup($e);
}

is_deeply(\@warn, [], 'no warnings');
