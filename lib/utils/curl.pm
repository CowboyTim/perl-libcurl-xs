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
XSLoader::load('utils::curl_constants', $VERSION);

sub AUTOLOAD {
    my (@a_args) = @_;
    my $c_name = $AUTOLOAD;
    $c_name =~ s/.*:://;
    return unless $c_name =~ m/^(?:CURLOPT)_(.*)$/;
    return unless length($1//"");
    my $opt = http::curl_easy_option_by_name($1);
    return unless defined $opt;
    return $opt->{id};
}

package http::curl::easy;

sub DESTROY {
    http::curl_easy_cleanup($_[0]) if defined $_[0] and defined $$_[0];
}

1;
