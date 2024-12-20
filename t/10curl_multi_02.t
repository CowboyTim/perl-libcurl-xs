use Test::More tests => 33;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

http::curl_global_trace();
http::curl_global_init(http::CURL_GLOBAL_ALL());

my $s = http::curl_easy_init();
isnt($s, undef, 'http::curl_easy_init(): return ok: s not undef: s='.sprintf("0x%x",$$s));
my $so1 = http::curl_easy_setopt($s, http::CURLOPT_URL(), 'http://www.example.com');
is($so1, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok URL');
my $so3 = http::curl_easy_setopt($s, http::CURLOPT_NOBODY(), 1);
is($so3, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok NOBODY');
my $so2 = http::curl_easy_setopt($s, http::CURLOPT_VERBOSE(), 0);
is($so2, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok VERBOSE');
my $so4 = http::curl_easy_setopt($s, http::CURLOPT_HEADER(), 0);
is($so4, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok HEADER');
my $so5 = http::curl_easy_setopt($s, http::CURLOPT_DNS_SERVERS(), "8.8.8.8,1.1.1.1");
is($so5, 48, 'http::curl_easy_setopt(): return value NOT SET DNS_SERVERS');

my $t = http::curl_easy_init();
isnt($t, undef, 'http::curl_easy_init(): return ok: s not undef: t='.sprintf("0x%s",$$t));
{
    my $so1 = http::curl_easy_setopt($t, http::CURLOPT_URL(), 'http://www.example.com');
    is($so1, http::CURLE_OK(), 'http::turl_easy_setopt(): return value ok URL');
    my $so3 = http::curl_easy_setopt($t, http::CURLOPT_NOBODY(), 1);
    is($so3, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok NOBODY');
    my $so2 = http::curl_easy_setopt($t, http::CURLOPT_VERBOSE(), 0);
    is($so2, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok VERBOSE');
    my $so4 = http::curl_easy_setopt($t, http::CURLOPT_HEADER(), 0);
    is($so4, http::CURLE_OK(), 'http::curl_easy_setopt(): return value ok HEADER');
    my $so5 = http::curl_easy_setopt($t, http::CURLOPT_DNS_SERVERS(), "8.8.8.8,1.1.1.1");
    is($so5, 48, 'http::curl_easy_setopt(): return value not set DNS_SERVERS');
    is(http::curl_easy_strerror($so5), 'An unknown option was passed in to libcurl', 'http::curl_easy_strerror(): return value not set DNS_SERVERS');
}

my $r = http::curl_multi_init();
isnt($r, undef, 'http::curl_multi_init(): return ok: r not undef: r='.sprintf("0x%x",$$r));
my $k1 = http::curl_multi_add_handle($r, $s);
is($k1, http::CURLM_OK(), 'http::curl_multi_add_handle(): return value ok: handle added');
my $t1 = http::curl_multi_add_handle($r, $t);
is($t1, http::CURLM_OK(), 'http::curl_multi_add_handle(): return value ok: handle added');
my $handles = http::curl_multi_get_handles($r);
is_deeply($handles, [$s, $t], 'http::curl_multi_get_handles(): return value ok: handles added');
my $ri5 = http::curl_multi_info_read($r, my $msgs_in_queue = 5);
is($ri5, undef, 'http::curl_multi_info_read(): return value ok');
is($msgs_in_queue, 0, 'http::curl_multi_info_read(): return value ok: msgs_in_queue=0');
my $rt2 = http::curl_multi_perform($r, my $still_running = 0);
is($rt2, http::CURLM_OK(), 'http::curl_multi_perform(): return value ok: RUN 1');
is($still_running, 2, 'http::curl_multi_perform(): return value ok: still_running=1');
my $rt3 = http::curl_multi_perform($r, $still_running);
is($rt3, http::CURLM_OK(), 'http::curl_multi_perform(): return value ok: RUN 2');
is($still_running, 2, 'http::curl_multi_perform(): return value ok: still_running=1');
my $ri3 = http::curl_multi_info_read($r);
is($ri3, undef, 'http::curl_multi_info_read(): return value ok');
my $nrloop = 0;
my $numfds = 0;
while($still_running and $nrloop <100) {
    $nrloop++;
    $still_running = 0;
    my $w1 = http::curl_multi_poll($r, undef, 30*1000, $numfds);
    if($w1 != http::CURLM_OK()) {
        last;
    }
    $ri3 = http::curl_multi_perform($r, $still_running);
    if($ri3 != http::CURLM_OK()) {
        last;
    }
    #print STDERR "# nrloop=$nrloop still_running=$still_running, numfds=$numfds\n";
}
my %info = ();
is($still_running, 0, 'http::curl_multi_perform(): return value ok: still_running=0');
my $ri4 = http::curl_multi_info_read($r, my $nr_left);
$info{$ri4->{easy_handle}} = $ri4;
is($nr_left, 1, 'http::curl_multi_info_read(): return value ok: nr_left=1');
my $ri7 = http::curl_multi_info_read($r, $nr_left);
$info{$ri7->{easy_handle}} = $ri7;
is($nr_left, 0, 'http::curl_multi_info_read(): return value ok: nr_left=0');
my $handles_2 = http::curl_multi_get_handles($r);
is_deeply($handles_2, [], 'http::curl_multi_get_handles(): return value ok: empty');
my $e = http::curl_multi_cleanup($r);
is($e, http::CURLM_OK(), 'http::curl_multi_cleanup(): return value ok');
is($r, undef, 'http::curl_multi_cleanup(): return ok: cleanup undef');
is_deeply(\%info, {
$s => {
    msg => http::CURLMSG_DONE(),
    easy_handle => $s,
    result => http::CURLE_OK(),
},
$t => {
    msg => http::CURLMSG_DONE(),
    easy_handle => $t,
    result => http::CURLE_OK(),
}
}, 'http::curl_multi_info_read(): return value ok');

is_deeply(\@warn, [], 'no warnings');
