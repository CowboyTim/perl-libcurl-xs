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
    if($c_name =~ m/^curl_version|curl_version_info|curl_getdate|global_(init|cleanup|trace)$/){
        print "curl: $c_name\n";
        XSLoader::load('utils::curl_common', $VERSION);
        unless(UNIVERSAL::can("http",$c_name)){
            my @cl = caller(0);
            die "Undefined subroutine &${cl[0]}::$c_name called at $cl[1] line $cl[2].\n";
        }
        return &{"http::$c_name"}(@a_args);
    }
    if($c_name =~ m/^(?:CURLE|CURLINFO|CURLPROXY|CURLM|CURLMOPT|CURLMSG)_(?:.*)$/){
        XSLoader::load('utils::curl_constants', $VERSION);
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
        XSLoader::load('utils::curl_constants', $VERSION);
        unless(UNIVERSAL::can("http",$c_name)){
            my @cl = caller(0);
            die "Undefined subroutine &${cl[0]}::$c_name called at $cl[1] line $cl[2].\n";
        }
        return &{"http::$c_name"}();
    }
    my @cl = caller(0);
    die "Undefined subroutine &${cl[0]}::$c_name called at $cl[1] line $cl[2].\n";
}

package http::curl::easy;

sub DESTROY {
    http::curl_easy_cleanup($_[0]) if defined $_[0] and defined $$_[0];
}

package http::curl::multi;

sub DESTROY {
    my ($curlm) = @_;
    return unless defined $curlm and defined $$curlm;
    foreach my $easy_handle (http::curl_multi_get_handles($curlm)){
        http::curl_multi_remove_handle($curlm, $easy_handle);
        http::curl_easy_cleanup($easy_handle);
    }
    http::curl_multi_cleanup($curlm);
}

1;
