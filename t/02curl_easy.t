use Test::More tests => 28;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
#$SIG{__WARN__} = sub { push @warn, $_[0] };

{
    my $r = eval {
        http::curl_easy_init();
    };
    is(ref($r), 'http::curl::easy', 'http::curl_easy_init() return');
    is($@, '', 'http::curl_easy_init() eval');
}

{
    my $r = eval {
        http::curl_easy_cleanup();
    };
    is($r, undef, 'http::curl_easy_cleanup() return');
    is($@, '', 'http::curl_easy_cleanup() eval');
}

{
    my $r1;
    my $r = eval {
        $r1 = http::curl_easy_init();
        is(ref($r1), 'http::curl::easy', 'http::curl_easy_init() return');
        ok(defined $r1, 'http::curl_easy_init() return defined');
        ok(defined $$r1, 'http::curl_easy_init() return defined');
        http::curl_easy_cleanup($r1);
    };
    is($r, undef, 'http::curl_easy_cleanup(http) return');
    is($@, '', 'http::curl_easy_cleanup(http) eval');
    is($$r1, undef, 'http::curl_easy_cleanup(http) return undef');
}

{
    my $r1 = http::curl_easy_init();
    is(ref($r1), 'http::curl::easy', 'http::curl_easy_init() return');
    ok(defined $r1, 'http::curl_easy_init() return defined');
    ok(defined $$r1, 'http::curl_easy_init() return defined');
    http::curl_easy_cleanup($r1);
    is($r1, undef, 'http::curl_easy_cleanup(http) return undef');
    http::curl_easy_cleanup($r1);
    my $r3 = undef;
    http::curl_easy_cleanup($r3);
    is($r3, undef, 'http::curl_easy_cleanup(http) return x1');
}

{
    my $r = eval {
        http::curl_easy_setopt();
    };
    is($r, undef, 'http::curl_easy_setopt() return');
}

{
    my $r1 = http::curl_easy_init();
    is(ref($r1), 'http::curl::easy', 'http::curl_easy_init() return');
    isnt($$r1, undef, 'http::curl_easy_init() return OK');
    my $r2 = http::curl_easy_setopt($r1, http::CURLOPT_URL(), "http://example.com");
    is($r2, 0, 'http::curl_easy_setopt(http, CURLOPT_URL, "http://example.com") return ok');
    my $re = http::curl_easy_setopt($r1, http::CURLOPT_VERBOSE(), 0);
    is($re, 0, 'http::curl_easy_setopt(http, CURLOPT_VERBOSE, 0) return ok');
    my $r3 = http::curl_easy_perform($r1);
    is($r3, 0, 'http::curl_easy_perform(http) return ok');
    http::curl_easy_reset($r1);
    my $r5 = http::curl_easy_setopt($r1, http::CURLOPT_URL(), "http://example.com");
    is($r5, 0, 'http::curl_easy_setopt(http, CURLOPT_URL, "http://example.com") return ok');
    my $r4 = http::curl_easy_perform($r1);
    is($r4, 0, 'http::curl_easy_perform(http) return ok');
    http::curl_easy_cleanup($r1);
    is(http::CURLOPT_VERBOSE(), 41, 'http::CURLOPT_VERBOSE() return');
}

{
    my ($r1, $r3, $re);
    eval {
        $r1 = http::curl_easy_init();
        $re = http::curl_easy_setopt($r1, http::CURLOPT_VERBOSE(), 0);
        $r3 = http::curl_easy_perform($r1);
        if($r3 != http::CURLE_OK()){
            my $err = http::curl_easy_strerror($r3);
            die "curl_easy_perform() failed: $err\n";
        }
    };
    is($@, "curl_easy_perform() failed: URL using bad/illegal format or missing URL\n", 'http::curl_easy_perform(http) eval');
    is($r3, 3, 'http::curl_easy_perform(http) return ok');
}
is_deeply(\@warn, [], 'no warnings');
