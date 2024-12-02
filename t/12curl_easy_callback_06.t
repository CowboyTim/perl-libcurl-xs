use Test::More tests => 18;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my $st = http::getrusage();
ok($st->{ru_maxrss} > 20000, 'http::getrusage() >20000');
ok($st->{ru_maxrss} < 22000, 'http::getrusage() <22000');

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
    ok($en->{ru_maxrss} > 20000, 'http::getrusage() >20000 after 1000 curl_easy_init() + destroy');
    ok($en->{ru_maxrss} < 22000, 'http::getrusage() <22000 after 1000 curl_easy_init() + destroy');
    ok($en->{ru_maxrss} >= $st->{ru_maxrss}, 'http::getrusage() > http::getrusage(): >= rss, rss='.($en->{ru_maxrss}-$st->{ru_maxrss}));
}

{
    my $st = http::getrusage();
    ok($st->{ru_maxrss} > 20000, 'http::getrusage() >20000, s='.$st->{ru_maxrss});
    ok($st->{ru_maxrss} < 22000, 'http::getrusage() <22000, s='.$st->{ru_maxrss});
    eval {
        foreach my $i (0..100){
            my $m = http::curl_multi_init();
            my @lst;
            foreach my $j (0..100){
                my $e = http::curl_easy_init();
                push @lst, $e; # keep list to prevent garbage collection, we didnt SvREFCNT_inc() as we don't have curl_multi_get_handles
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
    ok($en->{ru_maxrss} > 27000, 'http::getrusage() multi s='.$en->{ru_maxrss});
    ok($en->{ru_maxrss} < 30000, 'http::getrusage() multi s='.$en->{ru_maxrss});
    ok($en->{ru_maxrss} >= $st->{ru_maxrss}, 'multi >= rss, rss='.($en->{ru_maxrss}-$st->{ru_maxrss}));
}

{
    my $st = http::getrusage();
    ok($st->{ru_maxrss} > 22000, 'http::getrusage() >22000 s='.$st->{ru_maxrss});
    ok($st->{ru_maxrss} < 28000, 'http::getrusage() <28000 s='.$st->{ru_maxrss});

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

    eval {
        foreach my $i (1..100){
            my $m = http::curl_multi_init();
            foreach my $e (@lst){
                my $c = http::curl_easy_duphandle($e);
                $c or die 'http::curl_easy_duphandle() failed:'.$c;
                my $r = http::curl_multi_add_handle($m, $c);
                $r == http::CURLM_OK()
                    or die 'http::curl_multi_add_handle() failed:'.$r;
            }
        }
    };
    is($@, '', 'http::curl_easy_init() didnt fail');

    my $en = http::getrusage();
    ok($en->{ru_maxrss} > 27000, 'http::getrusage() >27000 after 1000 curl_easy_init() + keep, size='.$en->{ru_maxrss});
    ok($en->{ru_maxrss} < 30000, 'http::getrusage() <30000 after 1000 curl_easy_init() + keep, size='.$en->{ru_maxrss});
    ok($en->{ru_maxrss} >= $st->{ru_maxrss}, 'http::getrusage() > http::getrusage(): >= rss, rss='.($en->{ru_maxrss}-$st->{ru_maxrss}));
}

