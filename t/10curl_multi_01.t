use Test::More tests => 39;

use strict; use warnings;

use Data::Dumper;

use_ok('utils::curl');

{
    my $r = http::curl_multi_init();
    isnt($r, undef, 'http::curl_multi_init(): return ok');
    is(ref($r), 'http::curl::multi', 'http::curl_multi_init(): return type ok');
    isnt($$r, undef, 'http::curl_multi_init(): return value ok');

    my $e = http::curl_multi_cleanup($r);
    is($e, http::CURLM_OK(), 'http::curl_multi_cleanup(): return value ok');
    isnt($r, undef, 'http::curl_multi_init(): return ok');
    is(ref($r), 'SCALAR', 'http::curl_multi_init(): return type ok');
    is($$r, undef, 'http::curl_multi_init(): return value ok');
}

{
    my $r = http::curl_multi_init();
    isnt($r, undef, 'http::curl_multi_init(): return ok');
    is(ref($r), 'http::curl::multi', 'http::curl_multi_init(): return type ok');
    isnt($$r, undef, 'http::curl_multi_init(): return value ok');

    my $s = http::curl_easy_init();
    my $k1 = http::curl_multi_add_handle($r, $s);
    is($k1, http::CURLM_OK(), 'http::curl_multi_add_handle(): return value ok: handle added');

    my $k2 = http::curl_multi_add_handle($r);
    is($k2, undef, 'http::curl_multi_add_handle(): return value ok: undef');

    my $k3 = http::curl_multi_add_handle($r, $s);
    is($k3, 7, 'http::curl_multi_add_handle(): return value on error/duplicate handle add');
    is($k3, http::CURLM_ADDED_ALREADY(), 'http::curl_multi_add_handle(): return value on error/duplicate handle add');
    is(http::curl_multi_strerror($k3), 'The easy handle is already added to a multi handle', 'http::curl_multi_strerror(): return value on error/duplicate handle add');
    eval{http::curl_multi_strerror()};
    like($@, qr/Usage: http::curl_multi_strerror\(code\)/, 'http::curl_multi_strerror(): return value on error/duplicate handle add');
    is(http::curl_multi_strerror(99999), 'Unknown error', 'http::curl_multi_strerror(): return value on error/duplicate handle add');

    my $t = http::curl_multi_timeout($r, my $to);
    is($t, http::CURLM_OK(), 'http::curl_multi_timeout(): return value ok: CURLM_OK');
    is($to, 0, 'http::curl_multi_timeout(): return value ok: 0');

    my $l1 = http::curl_multi_remove_handle($r);
    is($l1, undef, 'http::curl_multi_remove_handle(): return value ok: undef');

    my $l2 = http::curl_multi_remove_handle($r, $s);
    is($l2, http::CURLM_OK(), 'http::curl_multi_remove_handle(): return value ok');

    my $s2 = http::curl_easy_init();
    my $k4 = http::curl_multi_remove_handle($r, $s2);
    is($k4, http::CURLM_OK(), 'http::curl_multi_remove_handle(): return value ok: handle removed for NOT added handle');

    my $e = http::curl_multi_cleanup($r);
    is($e, http::CURLM_OK(), 'http::curl_multi_cleanup(): return value ok');
    isnt($r, undef, 'http::curl_multi_init(): return ok');
    is(ref($r), 'SCALAR', 'http::curl_multi_init(): return type ok');
    is($$r, undef, 'http::curl_multi_init(): return value ok');
}

{
    my $r = http::curl_multi_init();
    my $s = http::curl_easy_init();
    my $k1 = http::curl_multi_add_handle($r, $s);
    is($k1, http::CURLM_OK(), 'http::curl_multi_add_handle(): return value ok: handle added');
    my $rt1 = http::curl_multi_perform($r);
    is($rt1, http::CURLM_OK(), 'http::curl_multi_perform(): return value ok');
    my $ri1 = http::curl_multi_info_read($r);
    is_deeply($ri1, {
        msg => http::CURLMSG_DONE(),
        result => http::CURLE_URL_MALFORMAT(),
        easy_handle => $s,
    }, 'http::curl_multi_info_read(): return value ok') or do {diag(Dumper($ri1)); diag(Dumper($s));};
    my $ri2 = http::curl_multi_info_read($r);
    is($ri2, undef, 'http::curl_multi_info_read(): return value ok: undef');
    my $so1 = http::curl_easy_setopt($s, http::CURLOPT_URL(), 'http://www.example.com');
    is($so1, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok');
    my $rt2 = http::curl_multi_perform($r);
    is($rt2, http::CURLM_OK(), 'http::curl_multi_perform(): return value ok');
    my $ri3 = http::curl_multi_info_read($r);
    is($ri3, undef,'http::curl_multi_info_read(): return value ok') or do {diag(Dumper($ri3)); diag(Dumper($s));};
}

{
    my $r = http::curl_multi_init();
    my $s = http::curl_easy_init();
    my $so1 = http::curl_easy_setopt($s, http::CURLOPT_URL(), 'http://www.example.com');
    is($so1, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok');
    my $k1 = http::curl_multi_add_handle($r, $s);
    is($k1, http::CURLM_OK(), 'http::curl_multi_add_handle(): return value ok: handle added');
    my $rt2 = http::curl_multi_perform($r, my $still_running = 0);
    is($rt2, http::CURLM_OK(), 'http::curl_multi_perform(): return value ok');
    is($still_running, 0, 'http::curl_multi_perform(): return value ok: still_running=0');
    my $ri3 = http::curl_multi_info_read($r);
    is_deeply($ri3, {
        msg => http::CURLMSG_DONE(),
        result => http::CURLE_URL_MALFORMAT(),
        easy_handle => $s,
    }, 'http::curl_multi_info_read(): return value ok') or do {diag(Dumper($ri3)); diag(Dumper($s));};
}
