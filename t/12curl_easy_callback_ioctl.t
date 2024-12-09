use Test::More tests => 20;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my $warn = 0;
$SIG{__WARN__} = sub {$warn++};

{
    my $k;
    my $e = http::curl_easy_init();
    is(ref($e), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$e));
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION(), my $abc = "");
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT string');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION(), my $abc = \(""));
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT string ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION(), my $abc = {});
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT hash ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION(), my $abc = []);
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT hash ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION(), my $abc = sub{});
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref');
    http::curl_easy_cleanup($e);
}

{
    my $e_cnt = 0;
    my $e_url = '';
    sub code_sub {
        my ($c_e, $cmd, $userp) = @_;
        $e_cnt++ unless defined $c_e and ref($c_e) eq 'http::curl::easy' and !defined $userp;
        $e_url = http::curl_easy_getinfo($c_e, http::CURLINFO_EFFECTIVE_URL());
        return http::CURLIOE_OK();
    };
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION(), \&code_sub);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PUT(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($e_cnt, 0, 'callback function called: no errors');
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code sub, no var, no closure');
    is($e_url, '', 'http::curl_easy_getinfo() return URL still empty, not called, difficult to test');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e_url = '';
    my $e_cnt = 0;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION(), my $abc = sub {
        my ($c_e, $cmd, $userp) = @_;
        $e_cnt++ unless defined $c_e and ref($c_e) eq 'http::curl::easy' and "$c_e" eq "$e" and !defined $userp;
        $e_url = http::curl_easy_getinfo($e, http::CURLINFO_EFFECTIVE_URL());
        return http::CURLIOE_OK();
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PUT(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($e_cnt, 0, 'callback function called: no errors');
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, var, closure');
    is($e_url, '', 'http::curl_easy_getinfo() return URL still empty, not called, difficult to test');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e_url = '';
    my $e_cnt = 0;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION(), sub {
        my ($c_e, $cmd, $userp) = @_;
        $e_cnt++ unless defined $c_e and ref($c_e) eq 'http::curl::easy' and "$c_e" eq "$e" and !defined $userp;
        $e_url = http::curl_easy_getinfo($c_e, http::CURLINFO_EFFECTIVE_URL());
        return http::CURLIOE_OK();
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PUT(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION(), undef);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION(), sub {});
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION());
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLDATA(), my $dt = []);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLDATA(), undef);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLDATA(), my $dh = []);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLDATA());
    $k |= http::curl_easy_perform($e);
    is($e_cnt, 0, 'callback function called: no errors');
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, no var, no closure');
    is($e_url, '', 'http::curl_easy_getinfo() return URL still empty, not called, difficult to test');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e_url = '';
    my $e_cnt = 0;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLFUNCTION(), sub {
        my ($c_e, $cmd, $userp) = @_;
        $e_cnt++ unless defined $c_e and ref($c_e) eq 'http::curl::easy' and "$c_e" eq "$e" and defined $userp and ref($userp) eq 'ARRAY';
        $e_url = http::curl_easy_getinfo($c_e, http::CURLINFO_EFFECTIVE_URL());
        push @{$userp //= []}, $e_url;
        return http::CURLIOE_OK();
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_IOCTLDATA(), my $dt = []);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_PUT(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($e_cnt, 0, 'callback function called: no errors');
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, no var, no closure: '.http::curl_easy_strerror($k));
    is($e_url, '', 'http::curl_easy_getinfo() return URL still empty, not called, difficult to test');
    http::curl_easy_cleanup($e);
}

is($warn, 0, 'no warnings');
