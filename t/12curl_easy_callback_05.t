use Test::More tests => 25;
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
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), my $abc = "");
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT string');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), my $abc = \(""));
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT string ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), my $abc = {});
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT hash ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), my $abc = []);
    is($k, http::CURLE_BAD_FUNCTION_ARGUMENT(), 'http::curl_easy_setopt() return CURLE_BAD_FUNCTION_ARGUMENT hash ref');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), my $abc = sub{});
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref');
    http::curl_easy_cleanup($e);
}

{
    my $e_cnt = 0;
    my $e_url = '';
    sub code_sub {
        my ($c_e, $type, $info, $userp) = @_;
        $e_cnt++ unless defined $c_e and ref($c_e) eq 'http::curl::easy';
        $e_cnt++ if defined $userp;
        $e_url = http::curl_easy_getinfo($c_e, http::CURLINFO_EFFECTIVE_URL());
    };
    my $k;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), \&code_sub);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($e_cnt, 0, 'callback function called: no errors: '.$e_cnt);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code sub, no var, no closure');
    is($e_url, 'http://www.example.com/', 'http::curl_easy_getinfo() return URL');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e_url = '';
    my $e_cnt = 0;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), my $abc = sub {
        my ($c_e, $type, $info, $userp) = @_;
        $e_cnt++ unless defined $c_e and ref($c_e) eq 'http::curl::easy' and "$c_e" eq "$e" and !defined $userp;
        $e_url = http::curl_easy_getinfo($e, http::CURLINFO_EFFECTIVE_URL());
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($e_cnt, 0, 'callback function called: no errors');
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, var, closure');
    is($e_url, 'http://www.example.com/', 'http::curl_easy_getinfo() return URL');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e_url = '';
    my $e_cnt = 0;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), sub {
        my ($c_e, $type, $info, $userp) = @_;
        $e_cnt++ unless defined $c_e and ref($c_e) eq 'http::curl::easy' and "$c_e" eq "$e" and !defined $userp;
        $e_url = http::curl_easy_getinfo($c_e, http::CURLINFO_EFFECTIVE_URL());
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($e_cnt, 0, 'callback function called: no errors');
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, no var, no closure');
    is($e_url, 'http://www.example.com/', 'http::curl_easy_getinfo() return URL');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e_url = '';
    my $e_cnt = 0;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), sub {
        my ($c_e, $type, $info, $userp) = @_;
        $e_cnt++ unless defined $c_e and ref($c_e) eq 'http::curl::easy' and "$c_e" eq "$e" and defined $userp and ref($userp) eq 'ARRAY';
        $e_url = http::curl_easy_getinfo($c_e, http::CURLINFO_EFFECTIVE_URL());
        push @{$userp //= []}, $e_url;
    });
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGDATA(), my $dt = []);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($e_cnt, 0, 'callback function called: no errors');
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, no var, no closure: '.http::curl_easy_strerror($k));
    is($e_url, 'http://www.example.com/', 'http::curl_easy_getinfo() return URL');
    http::curl_easy_cleanup($e);
}

{
    my $k;
    my $e_url = '';
    my $e_cnt = 0;
    my $k_cnt = 0;
    my $e = http::curl_easy_init();
    http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), my $abc = sub {
        my ($c_e, $type, $info, $userp) = @_;
        $k_cnt+=1;
    });
    $abc = undef;
    my $dt = [];
    foreach my $i (1..100){
        $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), sub {
            my ($c_e, $type, $info, $userp) = @_;
            $e_cnt+=1 unless defined $c_e and ref($c_e) eq 'http::curl::easy' and "$c_e" eq "$e" and defined $userp and ref($userp) eq 'ARRAY';
            $e_url = http::curl_easy_getinfo($c_e, http::CURLINFO_EFFECTIVE_URL());
            $k_cnt+=2;
            push @{$userp //= []}, $e_url;
        });
        $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGDATA(), $dt);
    }
    $k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    $k |= http::curl_easy_perform($e);
    is($e_cnt, 0, 'callback function called: no errors');
    ok($k_cnt > 20, 'callback function called: called >20, got:'.$k_cnt);
    is($k, http::CURLE_OK(), 'http::curl_easy_setopt() return CURLE_OK code ref, no var, no closure: '.http::curl_easy_strerror($k));
    is($e_url, 'http://www.example.com/', 'http::curl_easy_getinfo() return URL ok');
    ok(scalar(@$dt) > 10, 'got array size >10, got:'.scalar(@$dt));
    http::curl_easy_cleanup($e);
}

is_deeply(\@warn, [], 'no warnings');
