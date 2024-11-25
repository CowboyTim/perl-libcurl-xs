use Test::More tests => 23;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

{
    my $r = eval {
        http::curl_easy_getinfo();
    };
    is($@, '', 'http::curl_easy_getinfo() eval');
    is($r, undef, 'http::curl_easy_getinfo() return, undef');
}

{
    my $r;
    eval {
        my $r1 = http::curl_easy_init();
        $r = http::curl_easy_getinfo($r1);
        http::curl_easy_cleanup($r1);
    };
    is($@, '', 'http::curl_easy_getinfo() eval, with curl object');
    is($r, undef, 'http::curl_easy_getinfo() return, with curl object');
}

{
    my $r = http::curl_easy_init();
    is(http::curl_easy_getinfo($r, http::CURLINFO_EFFECTIVE_URL()), '', 'http::curl_easy_getinfo() return empty');
    is(http::curl_easy_setopt($r, http::CURLOPT_URL(), 'http://www.example.com/'), http::CURLE_OK(), 'http::curl_easy_setopt() return ok');
    is(http::curl_easy_setopt($r, http::CURLOPT_FOLLOWLOCATION(), 1), http::CURLE_OK(), 'http::curl_easy_setopt() return ok');
    is(http::curl_easy_getinfo($r, http::CURLINFO_EFFECTIVE_URL()), 'http://www.example.com/', 'http::curl_easy_getinfo() return real url: http://www.example.com/');
    is(http::curl_easy_getinfo($r, http::CURLINFO_SPEED_DOWNLOAD_T()), 0, 'http::curl_easy_getinfo() return real speed download: 0');
    is(http::curl_easy_getinfo($r, http::CURLINFO_SIZE_DOWNLOAD_T()), 0, 'http::curl_easy_getinfo() return real size download: 0');
    is(http::curl_easy_getinfo($r, http::CURLINFO_TOTAL_TIME()), 0, 'http::curl_easy_getinfo() return real total time: 0');
    my $ret = http::curl_easy_perform($r);
    is($ret, http::CURLE_OK(), 'http::curl_easy_perform() return ok');
    like(http::curl_easy_getinfo($r, http::CURLINFO_SPEED_DOWNLOAD_T()), qr/\d+/, 'http::curl_easy_getinfo() return real speed download'); 
    like(http::curl_easy_getinfo($r, http::CURLINFO_SIZE_DOWNLOAD_T()), qr/\d+/, 'http::curl_easy_getinfo() return real size download');
    like(http::curl_easy_getinfo($r, http::CURLINFO_TOTAL_TIME()), qr/\d+\.\d+/, 'http::curl_easy_getinfo() return real total time');
    http::curl_easy_cleanup($r);
}

{
    my ($r, @res);
    eval {
        push @res, http::curl_easy_option_by_name();
    };
    is($@, '', 'http::curl_easy_option_by_name() eval empty');
    is($res[0], undef, 'http::curl_easy_option_by_name() return empty');
}

{
    my ($r, @res);
    eval {
        push @res, http::curl_easy_option_by_name("URL");
    };
    is($@, '', 'http::curl_easy_option_by_name() eval URL');
    is_deeply($res[0], {name => 'URL', id => 10002, type => 4, flags => 0}, 'http::curl_easy_option_by_name() return URL');
}

{
    my ($r, @res);
    eval {
        push @res, http::curl_easy_option_by_name("FOLLOWLOCATION");
    };
    is($@, '', 'http::curl_easy_option_by_name() eval FOLLOWLOCATION');
    is_deeply($res[0], {name => 'FOLLOWLOCATION', id => 52, type => 0, flags => 0}, 'http::curl_easy_option_by_name() return FOLLOWLOCATION');
}

is_deeply(\@warn, [], 'no warnings');
