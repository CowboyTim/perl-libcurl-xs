use Test::More tests => 14;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

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
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = \(""));
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT string ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = {});
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT hash ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = []);
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT hash ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = sub{});
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref');
    http::curl_easy_cleanup($e);
}

{
    my $k_cnt = 0;
    sub code_sub {
        my ($p_ip, $l_ip, $p_port, $l_port) = @_;
        $k_cnt++;
        return http::CURL_PREREQFUNC_OK();
    };
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), \&code_sub);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code sub, no var, no closure');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = sub {
        my ($p_ip, $l_ip, $p_port, $l_port) = @_;
        return http::CURL_PREREQFUNC_OK();
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, var, closure');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), sub {
        my ($p_ip, $l_ip, $p_port, $l_port) = @_;
        return http::CURL_PREREQFUNC_OK();
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, no var, no closure');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), sub {
        return http::CURL_PREREQFUNC_OK();
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    my $t = http::curl_easy_setopt($e, http::CURLOPT_PREREQDATA(), 'abc');
    is($t, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT: '.http::curl_easy_strerror($t));
    $k |= http::curl_easy_perform($e);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, no var, no closure: '.http::curl_easy_strerror($k));
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $k_cnt = 0;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), my $abc = sub {
        my ($p_ip, $l_ip, $p_port, $l_port) = @_;
        die;
        return http::CURL_PREREQFUNC_OK();
    });
    $abc = undef;
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PREREQFUNCTION(), sub {
        my ($p_ip, $l_ip, $p_port, $l_port) = @_;
        $k_cnt+=1;
        return http::CURL_PREREQFUNC_OK();
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($k_cnt, 1, 'callback function called: ok successes:'.$k_cnt);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, no var, no closure: '.http::curl_easy_strerror($k));
    http::curl_easy_cleanup($e);
}
