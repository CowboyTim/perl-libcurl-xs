use Test::More tests => 19;

BEGIN {use_ok('utils::curl', qw())};

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
     my ($r, @res);
     eval {
         $r = http::curl_easy_init();
         push @res, http::curl_easy_getinfo($r, http::CURLINFO_EFFECTIVE_URL());
         http::curl_easy_setopt($r, http::CURLOPT_URL(), 'http://www.example.com/');
         http::curl_easy_setopt($r, http::CURLOPT_FOLLOWLOCATION(), 1);
         push @res, http::curl_easy_getinfo($r, http::CURLINFO_EFFECTIVE_URL());
         push @res, http::curl_easy_getinfo($r, http::CURLINFO_EFFECTIVE_METHOD());
         push @res, http::curl_easy_getinfo($r, http::CURLINFO_SPEED_DOWNLOAD_T());
         push @res, http::curl_easy_getinfo($r, http::CURLINFO_SIZE_DOWNLOAD_T());
         http::curl_easy_cleanup($r);
     };
     is($@, '', 'http::curl_easy_getinfo() eval');
     is(ref($r), 'SCALAR', 'http::curl_easy_getinfo() return');
     is($$r, undef, 'http::curl_easy_getinfo() return');
     is($res[0], '', 'http::curl_easy_getinfo() return empty');
     is($res[1], 'http://www.example.com/', 'http::curl_easy_getinfo() return real url: http://www.example.com/');
     is($res[2], 'GET', 'http::curl_easy_getinfo() return real method: GET');
     is($res[3], 0, 'http::curl_easy_getinfo() return real speed download: 0');
     is($res[4], 0, 'http::curl_easy_getinfo() return real size download: 0');
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
