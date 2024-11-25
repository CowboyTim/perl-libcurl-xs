use Test::More tests => 22;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

{
    my $u = http::curl_url();
    isnt($u, undef, 'http::curl_url(): return ok: u not undef: u='.sprintf("0x%x",$$u));
    http::curl_url_cleanup();
    isnt($u, undef, 'http::curl_url_cleanup(): return ok: u not undef: u='.sprintf("0x%x",$$u));
    http::curl_url_cleanup($u);
    is($u, undef, 'http::curl_url_cleanup(u): return ok: u undef');
}

{
    my $u = http::curl_url();
    http::curl_url_set($u, http::CURLUPART_URL(), 'http://www.example.com');
    my $r = http::curl_url_get($u, http::CURLUPART_URL(), my $url);
    is($r, http::CURLUE_OK(), 'http::curl_url_get(): return value ok');
    is($url, 'http://www.example.com/', 'http::curl_url_set() and http::curl_url_get()');
    http::curl_url_cleanup($u);
}

{
    my $u = http::curl_url();
    my $k = http::curl_url_set($u, http::CURLUPART_URL(), 'http://u:b@www.example.com:677/some/url?query=string&more=&some=;-()*%;@', http::CURLU_URLENCODE());
    is($k, http::CURLUE_OK(), 'http::curl_url_set(): return value ok');
    my $r = http::curl_url_get($u, http::CURLUPART_QUERY(), my $url_q, http::CURLU_URLENCODE());
    is($r, http::CURLUE_OK(), 'http::curl_url_get(): return value ok');
    is($url_q, 'query=string&more=&some=;-()*%;@', 'http::curl_url_set() and http::curl_url_get()');
    my $d = http::curl_url_dup($u);
    isnt($d, undef, 'http::curl_url_dup(): return ok: d not undef: d='.sprintf("0x%x",$$d));
    http::curl_url_cleanup($u);
    my $s = http::curl_url_get($d, http::CURLUPART_SCHEME(), my $url_s, http::CURLU_URLENCODE());
    is($s, http::CURLUE_OK(), 'http::curl_url_get(): return value ok');
    is($url_s, 'http', 'http::curl_url_get(): scheme');
}

{
    my $r;
    my $u = http::curl_url();
    my $k = http::curl_url_set($u, http::CURLUPART_SCHEME(), 'https');
    is($k, http::CURLUE_OK(), 'http::curl_url_set(): return value ok');
    $r = http::curl_url_set($u, http::CURLUPART_HOST(), 'www.example.com');
    is($r, http::CURLUE_OK(), 'http::curl_url_set(): return value ok');
    $r = http::curl_url_set($u, http::CURLUPART_PORT(), '677');
    is($r, http::CURLUE_OK(), 'http::curl_url_set(): return value ok');
    $r = http::curl_url_set($u, http::CURLUPART_PATH(), '/some/url');
    is($r, http::CURLUE_OK(), 'http::curl_url_set(): return value ok');
    $r = http::curl_url_set($u, http::CURLUPART_QUERY(), 'query=string&more=&some=;-()*%;@');
    is($r, http::CURLUE_OK(), 'http::curl_url_set(): return value ok');
    $r = http::curl_url_set($u, http::CURLUPART_USER(), 'u');
    is($r, http::CURLUE_OK(), 'http::curl_url_set(): return value ok');
    $r = http::curl_url_set($u, http::CURLUPART_PASSWORD(), 'b');
    is($r, http::CURLUE_OK(), 'http::curl_url_set(): return value ok');
    $r = http::curl_url_get($u, http::CURLUPART_URL(), my $url);
    is($r, http::CURLUE_OK(), 'http::curl_url_get(): return value ok');
    is($url, 'https://u:b@www.example.com:677/some/url?query=string&more=&some=;-()*%;@', 'http::curl_url_set() and http::curl_url_get()');
}

is_deeply(\@warn, [], 'no warnings');
