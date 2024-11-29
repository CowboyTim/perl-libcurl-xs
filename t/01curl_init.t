use Test::More tests => 5;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my $r1 = eval {
    http::curl_global_init();
};
is($r1, 1, 'http::curl_global_init() return');
is($@, '', 'http::curl_global_init() eval');

my $r2 = eval {
    http::curl_global_cleanup();
};
is($r2, 1, 'http::curl_global_cleanup() return');
is($@, '', 'http::curl_global_cleanup() eval');
