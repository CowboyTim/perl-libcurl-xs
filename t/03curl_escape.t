use Test::More tests => 7;
use strict; use warnings;

BEGIN {use_ok('utils::curl', qw())};

{
    my $r = eval {
        http::curl_easy_escape();
    };
    is($r, undef, 'http::curl_easy_escape() return');
    is($@, '', 'http::curl_easy_escape() eval');
}

{
    my $r = eval {
        http::curl_easy_escape("some data,&?* data\t\n\rconverted://");
    };
    is($r, 'some%20data%2C%26%3F%2A%20data%09%0A%0Dconverted%3A%2F%2F', 'http::curl_easy_escape() return');
    is($@, '', 'http::curl_easy_escape() eval');
}

{
    my $r = eval {
        http::curl_easy_unescape('some%20data%2C%26%3F%2A%20data%09%0A%0Dconverted%3A%2F%2F');
    };
    is($r, "some data,&?* data\t\n\rconverted://", 'http::curl_easy_unescape() return');
    is($@, '', 'http::curl_easy_unescape() eval');
}
