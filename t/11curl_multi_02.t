use Test::More tests => 11;
use strict; use warnings;

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

{
    my $r = http::curl_multi_init();
    my $s = http::curl_easy_init();
    my $so1 = http::curl_easy_setopt($s, http::CURLOPT_URL(), 'http://www.example.com');
    is($so1, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok URL');
    my $so2 = http::curl_easy_setopt($s, http::CURLOPT_VERBOSE(), 1);
    is($so2, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok VERBOSE');
    my $k1 = http::curl_multi_add_handle($r, $s);
    is($k1, http::CURLM_OK(), 'http::curl_multi_add_handle(): return value ok: handle added');
    my $rt2 = http::curl_multi_perform($r, my $still_running = 0);
    is($rt2, http::CURLM_OK(), 'http::curl_multi_perform(): return value ok');
    is($still_running, 1, 'http::curl_multi_perform(): return value ok: still_running=1');
    my $ri3 = http::curl_multi_info_read($r);
    is_deeply($ri3, undef, 'http::curl_multi_info_read(): return value ok') or do {diag(Dumper($ri3)); diag(Dumper($s));};
    my $nrloop = 0;
    while($still_running and $nrloop <10) {
        $nrloop++;
        $still_running = 0;
        my $w1 = http::curl_multi_poll($r); 
        if($w1 != http::CURLM_OK()) {
            last;
        }
        $ri3 = http::curl_multi_perform($r, $still_running);
        if($ri3 != http::CURLM_OK()) {
            last;
        }
        print STDERR "# nrloop=$nrloop still_running=$still_running\n";
    }
    is($still_running, 0, 'http::curl_multi_perform(): return value ok: still_running=0');
    my $ri4 = http::curl_multi_info_read($r);
    is_deeply($ri4, undef, 'http::curl_multi_info_read(): return value ok');
    my $e = http::curl_multi_cleanup($r);
    is($e, http::CURLM_OK(), 'http::curl_multi_cleanup(): return value ok');
    is($r, undef, 'http::curl_multi_cleanup(): return ok: cleanup undef');
}
