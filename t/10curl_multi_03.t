use Test::More tests => 18;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl');

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

my $s = http::curl_easy_init();
isnt($s, undef, 'http::curl_easy_init(): return ok: s not undef: s='.sprintf("0x%x",$$s));
http::curl_easy_setopt($s, http::CURLOPT_URL(), 'http://www.example.com');
http::curl_easy_setopt($s, http::CURLOPT_NOBODY(), 1);
http::curl_easy_setopt($s, http::CURLOPT_VERBOSE(), 0);
http::curl_easy_setopt($s, http::CURLOPT_HEADER(), 0);

my $t = http::curl_easy_init();
isnt($t, undef, 'http::curl_easy_init(): return ok: s not undef: t='.sprintf("0x%s",$$t));
http::curl_easy_setopt($t, http::CURLOPT_URL(), 'http://www.example.com');
http::curl_easy_setopt($t, http::CURLOPT_NOBODY(), 1);
http::curl_easy_setopt($t, http::CURLOPT_VERBOSE(), 0);
http::curl_easy_setopt($t, http::CURLOPT_HEADER(), 0);

my $r = http::curl_multi_init();
isnt($r, undef, 'http::curl_multi_init(): return ok: r not undef: r='.sprintf("0x%x",$$r));
my $k1 = http::curl_multi_add_handle($r, $s);
is($k1, http::CURLM_OK(), 'http::curl_multi_add_handle(): return value ok: handle added');
my $t1 = http::curl_multi_add_handle($r, $t);
is($t1, http::CURLM_OK(), 'http::curl_multi_add_handle(): return value ok: handle added');

# cleanup before curl_multi_perform
eval {
    undef $s;
    undef $t;
};
is($@, '', 'http::curl_multi_add_handle(): cleanup before curl_multi_perform');

my $rt2 = http::curl_multi_perform($r, my $still_running);
is($rt2, http::CURLM_OK(), 'http::curl_multi_perform(): return value ok: RUN 1');
is($still_running, 2, 'http::curl_multi_perform(): return value ok: still_running=0');
my $ri4 = http::curl_multi_info_read($r, my $nr_left);
is_deeply($ri4, undef, 'http::curl_multi_info_read(): return value ok: undef');
is($nr_left, 0, 'http::curl_multi_info_read(): return value ok: nr_left=0');
my $nrloop = 0;
my $numfds = 0;
my $ri3;
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
{
    my $ri5 = http::curl_multi_info_read($r, my $nr_left_bis);
    is_deeply($ri5, {msg => 1, result => 0}, 'http::curl_multi_info_read(): return value ok: undef');
    is($nr_left_bis, 1, 'http::curl_multi_info_read(): return value ok: nr_left=1');
}
{
    my $ri5 = http::curl_multi_info_read($r, my $nr_left_bis);
    is_deeply($ri5, {msg => 1, result => 0}, 'http::curl_multi_info_read(): return value ok: undef');
    is($nr_left_bis, 0, 'http::curl_multi_info_read(): return value ok: nr_left=0');
}
my $e = http::curl_multi_cleanup($r);
is($e, http::CURLM_OK(), 'http::curl_multi_cleanup(): return value ok');
is($r, undef, 'http::curl_multi_cleanup(): return ok: cleanup undef');

is_deeply(\@warn, [], 'no warnings');
