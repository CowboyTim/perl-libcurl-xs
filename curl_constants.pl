use strict; use warnings;
my @c;
# read in CURLE_ enum constants from the curl.h header file
my $inc_flags = `pkg-config libcurl --cflags-only-I`;
chomp $inc_flags;
$inc_flags =~ s/^-I//;
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
push @c, $str =~ m/^\s*(CURLM_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLMOPT_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLMSG_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLPROXY_(?:[A-Z_0-9]+))\s*/gms;
my %uniq;
@uniq{@c} = ();
@c = sort keys %uniq;
@c;
