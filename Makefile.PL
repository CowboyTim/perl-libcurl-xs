use ExtUtils::MakeMaker;

use strict;

print "LIBCURL_INC: $ENV{LIBCURL_INC}\n";
print "LIBCURL_LIB: $ENV{LIBCURL_LIB}\n";
print "LIBCURL_RPATH: $ENV{LIBCURL_RPATH}\n";

$ENV{LIBCURL_INC} ||= do {
    print "LIBCURL_INC not set, trying to set it by running pkg-config\n";
    my $inc_flags = `pkg-config libcurl --cflags-only-I`;
    chomp $inc_flags;
    if(!$inc_flags){
        die "No libcurl installed according to `pkg-config libcurl`";
    }
    $inc_flags =~ s/^-I//;
    $inc_flags;
};

$ENV{LIBCURL_LIB} ||= do {
    print "LIBCURL_LIB not set, trying to set it by running pkg-config\n";
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
$ENV{LIBCURL_RPATH} ||= $ENV{LIBCURL_LIB};

{
    local @ARGV = ();
    do './curl_constants.PL'
        or die "problem running curl_constants.PL: exit:$?, $@\n";
}

use Config;

WriteMakefile(
    NAME                => 'utils::curl',
    VERSION_FROM        => 'lib/utils/curl.pm',
    LIBS                => ["-L$ENV{LIBCURL_LIB} -lcurl"],
    CCFLAGS             => "$Config{ccflags} -Wextra -Werror -fPIC -rdynamic",
    LDDLFLAGS           => "-shared -Wl,--disable-new-dtags -L$ENV{LIBCURL_LIB} -Wl,-R$ENV{LIBCURL_RPATH} -Wl,-rpath=$ENV{LIBCURL_RPATH} -lcurl",
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
    NEEDS_LINKING       => 1,
    XSMULTI             => 1,
    BUILD_REQUIRES      => {"ExtUtils::MakeMaker" => '7.12'},
    XS                  => {
        'lib/utils/curl.xs'       => 'lib/utils/curl.c',
    },
);
