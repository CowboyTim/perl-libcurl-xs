package utils::curl_common;

our $VERSION    = '0.01';
our $XS_VERSION = '0.01';

require DynaLoader;
DynaLoader::bootstrap(__PACKAGE__, $VERSION);
sub dl_load_flags { 0x01 }

1;
