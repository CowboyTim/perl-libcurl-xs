package utils::curl;

use strict; use warnings;

our $VERSION = '0.1';

require DynaLoader;
our @ISA = qw(DynaLoader);
__PACKAGE__->bootstrap($VERSION);

sub dl_load_flags { 0x01 } # RTLD_LAZY

package http;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $AUTOLOAD;

sub AUTOLOAD {
    my (@a_args) = @_;
    my $c_name = $AUTOLOAD;
    $c_name =~ s/.*:://;
    if($c_name =~ m/^(?:CURLE|CURLINFO|CURLPROXY|CURLM|CURLMOPT|CURLMSG)_(?:.*)$/){
        no strict 'refs';
        unless(UNIVERSAL::can("http",$c_name)){
            my @cl = caller(0);
            die "Undefined subroutine &${cl[0]}::$c_name called at $cl[1] line $cl[2].\n";
        }
        return &{"http::$c_name"}();
    }
    if($c_name =~ m/^(?:CURLOPT)_(.*)$/ and length($1)){
        my $opt_name = $1;
        if(UNIVERSAL::can("http","curl_easy_option_by_name")){
            my $opt = eval {http::curl_easy_option_by_name($opt_name)};
            return $opt->{id} if defined $opt;
        }
        no strict 'refs';
        unless(UNIVERSAL::can("http",$c_name)){
            my @cl = caller(0);
            die "Undefined subroutine &${cl[0]}::$c_name called at $cl[1] line $cl[2].\n";
        }
        return &{"http::$c_name"}();
    }
    my @cl = caller(0);
    die "Undefined subroutine &${cl[0]}::$c_name called at $cl[1] line $cl[2].\n";
}

1;
