use Test::More tests => 6;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

is(http::curl_getdate(), undef, 'http::curl_date() return undef on no args');
is(http::curl_getdate('Sun, 06 Nov 1994 08:49:37 GMT'), 784111777, 'http::curl_date() return OK: 784111777');
is(http::curl_getdate('Sunday, 06-Nov-94 08:49:37 GMT'), 784111777, 'http::curl_date() return OK: 784111777');
is(http::curl_getdate("20040911 +0200"), 1094853600, 'http::curl_date() return OK: 1094853600');

is_deeply(\@warn, [], 'no warnings');
