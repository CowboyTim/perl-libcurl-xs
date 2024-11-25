use Test::More tests => 14;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

{
    my @r = eval {
        http::curl_easy_escape();
    };
    is($r[0], undef, 'http::curl_easy_escape() return');
    is($@, '', 'http::curl_easy_escape() eval');
}

{
    my @r = eval {
        http::curl_easy_escape("some data,&?* data\t\n\rconverted://");
    };
    is($r[0], 'some%20data%2C%26%3F%2A%20data%09%0A%0Dconverted%3A%2F%2F', 'http::curl_easy_escape() return');
    is($r[1], undef, 'http::curl_easy_unescape() return');
    is($@, '', 'http::curl_easy_escape() eval');
}

{
    my @r = eval {
        http::curl_easy_unescape('some%20data%2C%26%3F%2A%20data%09%0A%0Dconverted%3A%2F%2F');
    };
    is($r[0], "some data,&?* data\t\n\rconverted://", 'http::curl_easy_unescape() return');
    is($r[1], undef, 'http::curl_easy_unescape() return');
    is($@, '', 'http::curl_easy_unescape() eval');
}

{
    my $v;
    my @r = eval {
        $v = 'some%20data%2C%26%3F%2A%20data%09%0A%0Dconverted%3A%2F%2F';
        http::curl_easy_unescape($v);
    };
    is($r[0], "some data,&?* data\t\n\rconverted://", 'http::curl_easy_unescape() return');
    is($r[1], undef, 'http::curl_easy_unescape() return');
    is($v, 'some%20data%2C%26%3F%2A%20data%09%0A%0Dconverted%3A%2F%2F', 'http::curl_easy_unescape() VALUE ok');
    is($@, '', 'http::curl_easy_unescape() eval');
}

is_deeply(\@warn, [], 'no warnings');
