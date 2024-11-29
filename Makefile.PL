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

print "Building curl constants for your libcurl version\n";
open(my $c_fh, ">", "lib/utils/curl_constants.xs")
    or die "Can't create: $!\n";
print {$c_fh} <<'HERE';
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <curl/curl.h>
#include <curl/easy.h>
#include <curl/multi.h>

MODULE = utils::curl_constants  PACKAGE = utils::curl_constants

VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

BOOT:
{
HV *stash = gv_stashpv("http", 0);
HERE
my @c_consts = do './curl_constants.pl';
die $@ if $@;
foreach my $c (@c_consts) {
    print {$c_fh} "newCONSTSUB(stash, \"$c\", newSViv($c));\n";
}
print {$c_fh} <<'HERE';
}
HERE

WriteMakefile(
    NAME                => 'utils::curl',
    VERSION_FROM        => 'lib/utils/curl.pm',
    LIBS                => ['-lcurl'],
    CCFLAGS             => '-Wextra -Werror',
    OPTIMIZE            => '-Os',
    DEFINE              => '-UXS_APIVERSION_BOOTCHECK -UXS_VERSION_BOOTCHECK',
    INC                 => "-I. -I$ENV{LIBCURL_INCLUDE}",
    NO_META             => 1,
    NO_MYMETA           => 1,
    XSMULTI             => 1,
    BUILD_REQUIRES      => {"ExtUtils::MakeMaker" => '7.12'},
    XS                  => {
        'lib/utils/curl.xs'           => 'lib/utils/curl.c',
        'lib/utils/curl_constants.xs' => 'lib/utils/curl_constants.c',
    },
);

package MY;
sub test_via_harness {
  my($self, $perl, $tests) = @_;
  local $_ = $self->SUPER::test_via_harness($perl, $tests);
  s/PERL_DL_NONLAZY=1//g;
  return $_;
}

sub test_via_script {
  my($self, $perl, $tests) = @_;
  local $_ = $self->SUPER::test_via_script($perl, $tests);
  s/PERL_DL_NONLAZY=1//g;
  return $_;
}

