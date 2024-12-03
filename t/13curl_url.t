use Test::More tests => 9;
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/../blib/lib";

use_ok('utils::curl', qw());

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
    http::curl_url_cleanup($u);
}
