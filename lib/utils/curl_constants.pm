package utils::curl_constants;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION     = '0.01';
our $XS_VERSION  = $VERSION;

require XSLoader;
XSLoader::load('utils::curl_constants', $VERSION);

1;
