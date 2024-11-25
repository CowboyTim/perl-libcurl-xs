use Test::More tests => 19;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

my $st = http::getrusage();
my $sz_min = $st->{ru_maxrss};
my $sz_max = $sz_min + 1000;

{
    foreach my $i (1..1000){
        my $e = http::curl_easy_init();
        http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
        http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
        http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
        http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
        http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), sub {});
    }

    my $en = http::getrusage();
    ok($en->{ru_maxrss} >= $sz_min, 'http::getrusage() >min after 1000 curl_easy_init() + destroy: >rss, rss='.($en->{ru_maxrss}-$st->{ru_maxrss}));
    ok($en->{ru_maxrss} < $sz_max, 'http::getrusage() <max after 1000 curl_easy_init() + destroy: <rss, rss='.($en->{ru_maxrss}-$st->{ru_maxrss}));
    ok($en->{ru_maxrss} >= $st->{ru_maxrss}, 'http::getrusage() > http::getrusage(): >= rss, rss='.($en->{ru_maxrss}-$st->{ru_maxrss}));
}

{
    my $st = http::getrusage();
    ok($st->{ru_maxrss} >= $sz_min, 'http::getrusage() >min, s='.$st->{ru_maxrss});
    ok($st->{ru_maxrss} < $sz_max, 'http::getrusage() <max, s='.$st->{ru_maxrss});
    eval {
        foreach my $i (0..100){
            my $m = http::curl_multi_init();
            foreach my $j (0..100){
                my $e = http::curl_easy_init();
                http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
                http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
                http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
                http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
                my $cnt = 0;
                http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), sub {
                    $cnt++;
                });
                my $r = http::curl_multi_add_handle($m, $e);
                if($r != http::CURLM_OK()) {
                    die 'http::curl_multi_add_handle() failed';
                }
            }
        }
    };
    is($@, '', 'http::curl_multi_add_handle() didnt fail');
    my $en = http::getrusage();
    ok($en->{ru_maxrss} >= $sz_min, 'http::getrusage() multi s='.$en->{ru_maxrss});
    ok($en->{ru_maxrss} < $sz_max+1000, 'http::getrusage() multi <1000 s='.$en->{ru_maxrss});
    ok($en->{ru_maxrss} >= $st->{ru_maxrss}, 'multi >= rss, rss='.($en->{ru_maxrss}-$st->{ru_maxrss}));
}

{
    $sz_max += 1000;
    my $st = http::getrusage();
    ok($st->{ru_maxrss} >= $sz_min, 'http::getrusage() >min s='.$st->{ru_maxrss});
    ok($st->{ru_maxrss} < $sz_max, 'http::getrusage() <max s='.$st->{ru_maxrss});

    my @lst;
    foreach my $i (1..100){
        my $e = http::curl_easy_init();
        http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
        http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 0);
        http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
        http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
        my $cnt = 0;
        http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), sub {
            $cnt++;
        });
        push @lst, $e;
    }

    ok($st->{ru_maxrss} > $sz_min, 'http::getrusage() >min same, kept list, s='.$st->{ru_maxrss});
    ok($st->{ru_maxrss} < $sz_max, 'http::getrusage() <max same, kept list, s='.$st->{ru_maxrss});

    eval {
        foreach my $i (1..100){
            my $m = http::curl_multi_init();
            foreach my $e (@lst){
                my $c = http::curl_easy_duphandle($e)
                    or die 'http::curl_easy_duphandle() failed'; 
                my $r = http::curl_multi_add_handle($m, $c);
                $r == http::CURLM_OK()
                    or die 'http::curl_multi_add_handle() failed:'.$r;
            }
        }
    };
    is($@, '', 'http::curl_easy_init() didnt fail');

    my $en = http::getrusage();
    ok($en->{ru_maxrss} >= $sz_min, 'http::getrusage() >min after 1000 curl_easy_init() + keep, size='.$en->{ru_maxrss});
    ok($en->{ru_maxrss} < $sz_max+1000, 'http::getrusage() <max after 1000 curl_easy_init() + keep, size='.$en->{ru_maxrss});
    ok($en->{ru_maxrss} >= $st->{ru_maxrss}, 'http::getrusage() > http::getrusage(): >= rss, rss='.($en->{ru_maxrss}-$st->{ru_maxrss}));
}

is_deeply(\@warn, [], 'no warnings');
