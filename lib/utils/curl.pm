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

package http::curl::easy;

sub DESTROY {
    http::curl_easy_cleanup($_[0]) if defined $_[0] and defined $$_[0];
}

1;
