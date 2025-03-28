use ExtUtils::MakeMaker;

use strict;

print "LIBCURL_INC: $ENV{LIBCURL_INC}\n";
print "LIBCURL_LIB: $ENV{LIBCURL_LIB}\n";

$ENV{LIBCURL_INC} ||= do {
    my $inc_flags = `pkg-config libcurl --cflags-only-I`;
    chomp $inc_flags;
    if(!$inc_flags){
        die "No libcurl installed according to `pkg-config libcurl`";
    }
    $inc_flags =~ s/^-I//;
    $inc_flags;
};

$ENV{LIBCURL_LIB} ||= do {
    my $lib_flags;
    if($ENV{LIBCURL_INC}){
        $lib_flags = $ENV{LIBCURL_INC};
        $lib_flags =~ s/\/include/\/lib/;
    } else {
        $lib_flags = `pkg-config libcurl --libs-only-L`;
        chomp $lib_flags;
        if(!$lib_flags){
            die "No libcurl installed according to `pkg-config libcurl`";
        }
        $lib_flags =~ s/^-L//;
    }
    $lib_flags;
};

{
    local @ARGV = ();
    do './curl_constants.PL' or die $@, $?;
}

use Config;

WriteMakefile(
    NAME                => 'utils::curl',
    VERSION_FROM        => 'lib/utils/curl.pm',
    LIBS                => ['-lcurl'],
    CCFLAGS             => "$Config{ccflags} -Wextra -Werror -Wno-deprecated",
    LDDLFLAGS           => "$Config{lddlflags} -s -L$ENV{LIBCURL_LIB} -Wl,-rpath,$ENV{LIBCURL_LIB}",
    OPTIMIZE            => '-Os',
    MAN1PODS            => {},
    MAN3PODS            => {},
    DEFINE              => '-UXS_APIVERSION_BOOTCHECK -UXS_VERSION_BOOTCHECK',
    INC                 => "-I. -I$ENV{LIBCURL_INC}",
    NO_META             => 1,
    PL_FILES            => {},
    NO_MYMETA           => 1,
    NO_PERLLOCAL        => 1,
    NO_PACKLIST         => 1,
    XSMULTI             => 1,
    BUILD_REQUIRES      => {"ExtUtils::MakeMaker" => '7.12'},
    XS                  => {
        'lib/utils/curl.xs'       => 'lib/utils/curl.c',
    },
);
