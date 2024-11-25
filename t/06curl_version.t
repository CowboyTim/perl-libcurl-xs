use Test::More tests => 13;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

{
    my $r1;
    eval {
        $r1 = http::curl_version_info();
    };
    is($@, '', 'http::curl_easy_init() eval');
    is(ref($r1), 'HASH', 'http::curl_easy_init() return');
    like($r1->{version}, qr/\d+\.\d+\.\d+/, 'http::curl_version_info() return version: '.$r1->{version});
    like($r1->{ssl_version}, qr/\d+\.\d+\.\d+/, 'http::curl_version_info() return ssl version: '.$r1->{ssl_version});
    like($r1->{ssl_version_num}, qr/\d+/, 'http::curl_version_info() return ssl version num: '.$r1->{ssl_version_num});
    like($r1->{libz_version}, qr/\d+\.\d+\.\d+/, 'http::curl_version_info() return libz version: '.$r1->{libz_version});
    like($r1->{host}, qr/\w+/, 'http::curl_version_info() return host: '.$r1->{host});
    like($r1->{features}, qr/\d+/, 'http::curl_version_info() return features: '.$r1->{features});
    isnt(scalar @{$r1->{protocols}}, 0, 'http::curl_version_info() return protocols: '.join(",", sort @{$r1->{protocols}}));

}

{
    my $r1;
    eval {
        $r1 = http::curl_version();
    };
    is($@, '', 'http::curl_easy_init() eval');
    isnt($r1, '', 'http::curl_version() return: '.$r1);
}

is_deeply(\@warn, [], 'no warnings');
