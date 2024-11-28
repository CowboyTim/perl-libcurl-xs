use strict; use warnings;
my @c;
# read in CURLE_ enum constants from the curl.h header file
my $inc_flags = $ENV{LIBCURL_INCLUDE} || die "LIBCURL_INCLUDE not set";
my $str = '';
for my $f (qw(curl/curl.h curl/multi.h curl/easy.h)){
    my $curl_h = "$inc_flags/$f";
    open(my $fh, "<", $curl_h) or die "Can't open $curl_h: $!\n";
    print STDERR "reading in $curl_h\n";
    {
        local $/; # slurp mode
        $str .= <$fh>;
    }
    close $fh;
}
push @c, $str =~ m/^\s*(CURLINFO_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLE_(?:[A-Z_0-9]+))\s*/gms;
my $m_str = $str =~ s/.*typedef enum \{(.*?)\} CURLMoption;.*/$1/gmsr;
push @c, $m_str =~ m/^\s*(CURLM_(?:[A-Z_0-9]+))\s*/gms;
push @c, $m_str =~ m/^\s*(CURLMOPT_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLMSG_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLPROXY_(?:[A-Z_0-9]+))\s*/gms;
my $n_str = $str =~ s/.*typedef enum \{(.*?)\} CURLoption;.*/$1/gmsr;
push @c, $n_str =~ m/\((CURLOPT_(?:[A-Z_0-9]+)),/gms;
push @c, map {"CURLOPT_$_"} ($n_str =~ m/ CINIT\(([A-Z0-9_]+),.*?\)/gms);
my %uniq;
@uniq{@c} = ();
@c = sort keys %uniq;
@c;
