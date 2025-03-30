#!/bin/bash

set -e

PKG_BASE=${1:-/pkgbase}
shift
CURL_PATH=${1:-/opt/curl}
shift

export LIBCURL_LIB=$PKG_BASE/$CURL_PATH/lib/
export LIBCURL_INC=$PKG_BASE/$CURL_PATH/include/
export LIBCURL_RPATH=$CURL_PATH/lib
export LD_LIBRARY_PATH=$PKG_BASE/$CURL_PATH/lib/
export PERL_MM_OPT="INSTALLDIRS=site INSTALL_BASE=$CURL_PATH/ INSTALLSITEARCH=$CURL_PATH/lib/perl"
perl Makefile.PL
make
make test
make install DESTDIR=$PKG_BASE
