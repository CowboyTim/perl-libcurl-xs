use ExtUtils::MakeMaker;

use strict;

$ENV{LIBCURL_INCLUDE} ||= do {
    my $inc_flags = `pkg-config libcurl --cflags-only-I`;
    chomp $inc_flags;
    if(!$inc_flags){
        die "No libcurl installed according to `pkg-config libcurl`";
    }
    $inc_flags =~ s/^-I//;
    $inc_flags;
};

do './curl_constants.PL' or die $?;

use Config;

WriteMakefile(
    NAME                => 'utils::curl',
    VERSION_FROM        => 'lib/utils/curl.pm',
    LIBS                => ['-lcurl'],
    CCFLAGS             => "$Config{ccflags} -Wextra -Werror",
    LDDLFLAGS           => "$Config{lddlflags} -s",
    OPTIMIZE            => '-Os',
    MAN1PODS            => {},
    MAN3PODS            => {},
    DEFINE              => '-UXS_APIVERSION_BOOTCHECK -UXS_VERSION_BOOTCHECK',
    INC                 => "-I. -I$ENV{LIBCURL_INCLUDE}",
    NO_META             => 1,
    PL_FILES            => {
        'curl_constants.PL' => 'curl_constants.xsh',
    },
    NO_MYMETA           => 1,
    XSMULTI             => 1,
    BUILD_REQUIRES      => {"ExtUtils::MakeMaker" => '7.12'},
    XS                  => {
        'lib/utils/curl.xs'       => 'lib/utils/curl.c',
    },
);
