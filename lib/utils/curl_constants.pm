package utils::curl_constants;

our $VERSION = '0.01';

require DynaLoader;
DynaLoader::bootstrap(__PACKAGE__, $VERSION);

sub dl_load_flags { 0x01 }

1;
