package http;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION     = '0.01';
our $XS_VERSION  = $VERSION;

require XSLoader;
XSLoader::load('utils::curl', $VERSION);

sub AUTOLOAD {
    my (@a_args) = @_;
    my $c_name = $AUTOLOAD;
    $c_name =~ s/.*:://;
    if($c_name =~ m/^(?:CURLE|CURLINFO|CURLPROXY)_(?:.*)$/){
        XSLoader::load('utils::curl_constants', $VERSION);
        unless(UNIVERSAL::can("http",$c_name)){
            my @cl = caller(0);
            die "Undefined subroutine &${cl[0]}::$c_name called at $cl[1] line $cl[2].\n";
        }
        return &{"http::$c_name"}(@a_args);
    }
    unless($c_name =~ m/^(?:CURLOPT)_(.*)$/
            and length($1)
            and $opt = http::curl_easy_option_by_name($1)){
        my @cl = caller(0);
        die "Undefined subroutine &${cl[0]}::$c_name called at $cl[1] line $cl[2].\n";
    }
    return $opt->{id};
}

package http::curl::easy;

sub DESTROY {
    http::curl_easy_cleanup($_[0]) if defined $_[0] and defined $$_[0];
}

1;
