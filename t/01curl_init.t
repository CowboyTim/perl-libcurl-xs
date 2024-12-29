use Test::More tests => 10;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

my $r1 = eval {
    http::curl_global_init();
};
is($r1, 0, 'http::curl_global_init() return');
is($@, '', 'http::curl_global_init() eval');

my $r2 = eval {
    http::curl_global_cleanup();
};
is($r2, 1, 'http::curl_global_cleanup() return');
is($@, '', 'http::curl_global_cleanup() eval');

my $r3 = eval {
    http::curl_global_init(0);
};
is($r3, 0, 'http::curl_global_init() return');
is($@, '', 'http::curl_global_init() eval');

my $r4 = eval {
    http::curl_global_init(
         http::CURL_GLOBAL_ALL()
        |http::CURL_GLOBAL_SSL()
        |http::CURL_GLOBAL_WIN32()
        |http::CURL_GLOBAL_NOTHING()
        |http::CURL_GLOBAL_DEFAULT()
        |http::CURL_GLOBAL_ACK_EINTR()
        |http::CURL_GLOBAL_NOTHING()
    );
};
is($r4, 0, 'http::curl_global_init() return');
is($@, '', 'http::curl_global_init() eval');

is_deeply(\@warn, [], 'no warnings');
