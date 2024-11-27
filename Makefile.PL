use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'utils::curl',
    VERSION             => '0.01',
    LIBS                => ['-lcurl'],
    CCFLAGS             => '-Wextra -Werror',
    OPTIMIZE            => '-Os',
    DEFINE              => '',
    INC                 => '-I.',
    NO_META             => 1,
    NO_MYMETA           => 1,
    XSMULTI             => 1,
    LINKTYPE            => 'dynamic',
    XS                  => {
        'lib/utils/curl.xs'           => 'lib/utils/curl.c',
        'lib/utils/curl_constants.xs' => 'lib/utils/curl_constants.c',
        'lib/utils/curl_common.xs'    => 'lib/utils/curl_common.c',
    },
    XSBUILD             => {
        xs => {
            'lib/utils' => {
                DEFINE    => '-Dabc',
                LIBS      => ['-lrt -ldefke'],
                LDDLFLAGS => '-lrt',
                LDFROM    => "lib/utils/curl\$(OBJ_EXT) -lrt",
            }
    }},
    BUILD_REQUIRES      => {"ExtUtils::MakeMaker" => '7.12'},
);

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

BOOT:
{
HV *stash = gv_stashpv("http", 0);
HERE
foreach my $c (do './curl_constants.pl'){
    print {$c_fh} "newCONSTSUB(stash, \"$c\", newSViv($c));\n";
}
print {$c_fh} <<'HERE';
}
HERE

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

