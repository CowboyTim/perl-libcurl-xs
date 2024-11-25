use Test::More tests => 15;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

{
    my $r = http::curl_multi_init();
    is(ref($r), 'http::curl::multi', 'http::curl_multi_init(): return type ok r=0x'.sprintf("%x",$$r));
    my $s = http::curl_easy_init();
    is(ref($s), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$s));
    my $k = http::curl_multi_remove_handle($r, $s);
    if($k == 2){
        isnt($k, http::CURLM_OK(), 'http::curl_multi_remove_handle(): return value ok: handle removed for NOT added handle');
        is(http::curl_easy_strerror($k), 'Failed initialization', 'http::curl_easy_strerror(): return value ok: handle removed for NOT added handle');
    } else {
        is($k, http::CURLM_OK(), 'http::curl_multi_remove_handle(): return value ok: handle removed for NOT added handle');
        is(http::curl_easy_strerror($k), 'No error', 'http::curl_easy_strerror(): return value ok: handle removed for NOT added handle');
    }

    my $e = http::curl_multi_cleanup($r);
    is($e, http::CURLM_OK(), 'http::curl_multi_cleanup(): return value ok');
    is($r, undef, 'http::curl_multi_init(): return value ok');

    my $abbr = "s=0x".sprintf("%x",$$s);
    eval {
        $s = undef;
    };
    is($s, undef, "http::curl_easy_cleanup(): DESTROY $abbr");
}

{
    my $r = http::curl_multi_init();
    is(ref($r), 'http::curl::multi', 'http::curl_multi_init(): return type ok r=0x'.sprintf("%x",$$r));
    my $l;
    {
        my $s = http::curl_easy_init();
        is(ref($s), 'http::curl::easy', 'http::curl_easy_init() return: s=0x'.sprintf("%x",$$s));
        my $k = http::curl_multi_add_handle($r, $s);
        is($k, http::CURLM_OK(), 'http::curl_multi_add_handle(): return value ok: handle added');
        $l = $s;
    }

    my $e = http::curl_multi_cleanup($r);
    is($e, http::CURLM_OK(), 'http::curl_multi_cleanup(): return value ok');
    is($r, undef, 'http::curl_multi_init(): return value ok');

    my $abbr = "s=0x".sprintf("%x",$$l);
    eval {
        $l = undef;
    };
    is($l, undef, 'http::curl_easy_cleanup(): DESTROY '.$abbr);
}

is_deeply(\@warn, [], 'no warnings');
