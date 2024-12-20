package utils::curl;

use strict; use warnings;

our $VERSION = '0.2';

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

package WWW::Curl::Easy;

sub new {
    http::curl_easy_init();
}

sub setopt {
    my ($self, $opt, $val) = @_;
    http::curl_easy_setopt($self, $opt, $val);
}

sub perform {
    my ($self) = @_;
    http::curl_easy_perform($self);
}

sub getinfo {
    my ($self, $opt) = @_;
    http::curl_easy_getinfo($self, $opt);
}

sub strerror {
    my ($self) = @_;
    http::curl_easy_strerror($self);
}

sub errbuf {
    my ($self) = @_;
    $self->strerror();
}

package WWW::Curl::Multi;

sub new {
    http::curl_multi_init();
}

sub add_handle {
    my ($self, $easy) = @_;
    http::curl_multi_add_handle($self, $easy);
}

sub perform {
    my ($self) = @_;
    http::curl_multi_perform($self);
}

sub fdset {
    my ($self) = @_;
    http::curl_multi_fdset($self);
}

sub info_read {
    my ($self) = @_;
    http::curl_multi_info_read($self);
}

1;
