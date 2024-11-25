use Test::More tests => 6;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

{
    my $e = http::curl_easy_init();
    my $k;
    $k |= http::curl_easy_setopt($e, http::CURLOPT_URL(), 'http://www.example.com/');
    $k |= http::curl_easy_setopt($e, http::CURLOPT_NOBODY(), 1);
    my $cnt = 0;
    my $abc = sub {
        $cnt++;
    };
    $k |= http::curl_easy_setopt($e, http::CURLOPT_DEBUGFUNCTION(), $abc);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_VERBOSE(), 1);
    $k |= http::curl_easy_setopt($e, http::CURLOPT_HEADER(), 0);
    $k |= http::curl_easy_perform($e);
    isnt($cnt, 0, 'callback function called');
    my $l = $cnt;
    http::curl_easy_cleanup($e);
    is($e, undef, 'http::curl_easy_cleanup() return undef');
    eval {&{$abc}()};
    is($@, '', 'callback function called');
    is($cnt - $l, 1, 'callback function called extra');
}

is_deeply(\@warn, [], 'no warnings');
