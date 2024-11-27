use strict;
my @c;
# read in CURLE_ enum constants from the curl.h header file
my $inc_flags = `pkg-config libcurl --cflags-only-I`;
chomp $inc_flags;
$inc_flags =~ s/^-I//;
my $curl_h = "$inc_flags/curl/curl.h";
open(my $fh, "<", $curl_h) or die "Can't open $curl_h: $!\n";
my $in_enum = 0;
my $str = '';
{
    local $/; # slurp mode
    $str = <$fh>;
}
close $fh;
push @c, $str =~ m/^\s*(CURLINFO_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLE_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLPROXY_(?:[A-Z_0-9]+))\s*/gms;
my %uniq;
@uniq{@c} = ();
@c = sort keys %uniq;
@c;
