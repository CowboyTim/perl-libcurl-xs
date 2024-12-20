use strict; use warnings;
my $ofn = shift @ARGV || "curl_constants.xsh";
my @c;
# read in CURLE_ enum constants from the curl.h header file
my $inc_flags = $ENV{LIBCURL_INC} ||= do {
    my $inc_flags = `pkg-config libcurl --cflags-only-I`;
    chomp $inc_flags;
    if(!$inc_flags){
        die "No libcurl installed according to `pkg-config libcurl`";
    }
    $inc_flags =~ s/^-I//;
    $inc_flags;
};
my $str = '';
for my $f (qw(curl/curl.h curl/multi.h curl/easy.h curl/urlapi.h curl/websockets.h)) {
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
push @c, $str =~ m/^\s*(CURLSOCKTYPE_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/\s*#define\s*(CURL_SOCKOPT_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/\s*#define\s*(CURL_SOCKET_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/\s*#define\s*(CURLWS_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLUE_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLUPART_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/\s*#define\s*(CURLU_(?:[A-Z_0-9]+))\s*/gms;
my $m_str = $str =~ s/.*typedef enum \{(.*?)\} CURLMoption;.*/$1/gmsr;
push @c, $m_str =~ m/^\s*(CURLMOPT_(?:[A-Z_0-9]+))\s*/gms;
my $s_str = $str =~ s/.*typedef enum \{(.*?)\} CURLMcode;.*/$1/gmsr;
push @c, $s_str =~ m/^\s*(CURLM_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLMSG_(?:[A-Z_0-9]+))\s*/gms;
push @c, $str =~ m/^\s*(CURLPROXY_(?:[A-Z_0-9]+))\s*/gms;
my $n_str = $str =~ s/.*typedef enum \{(.*?)\} CURLoption;.*/$1/gmsr;
push @c, $n_str =~ m/\((CURLOPT_(?:[A-Z_0-9]+)),/gms;
push @c, map {"CURLOPT_$_"} ($n_str =~ m/ CINIT\(([A-Z0-9_]+),.*?\)/gms);
my %uniq;
@uniq{@c} = ();
@c = sort keys %uniq;

print "Building curl constants for your libcurl version\n";
open(my $c_fh, ">", $ofn) or die "Can't create $ofn: $!\n";
print {$c_fh} <<'HERE';
BOOT:
{
HV *stash = gv_stashpv("http", 0);
HERE
foreach my $c (@c) {
    print {$c_fh} "newCONSTSUB(stash, \"$c\", newSViv($c));\n";
}
print {$c_fh} <<'HERE';
}
HERE
close($c_fh) or die "Can't close $ofn: $!\n";

1;
