#!/bin/bash

AUTHOR=${AUTHOR?Need AUTHOR}
PKG_VERSION=${PKG_VERSION:-1.0-1}
PKG_BASE=${PKG_BASE?Need PKG_BASE}
PKG_NAME=${PKG_NAME?Need PKG_NAME}
PKG_ARCH=${PKG_ARCH:-all}

# map docker platforms to debian arch
if [ "$PKG_ARCH" = "linux/amd64" ]; then
    PKG_ARCH=amd64
elif [ "$PKG_ARCH" = "linux/arm64" ]; then
    PKG_ARCH=arm64
elif [ "$PKG_ARCH" = "linux/armhf" ]; then
    PKG_ARCH=armhf
fi

# temp dir setup
tmp_dpkg_dir=$(mktemp -p /tmp -d tmp.XXXXXX)
function cleanup(){
    if [[ -n $tmp_dpkg_dir ]]; then
        rm -rf $tmp_dpkg_dir
    fi
}
trap cleanup EXIT INT TERM HUP
dpkg_dir=$tmp_dpkg_dir/$PKG_NAME-$PKG_VERSION
mkdir -p $dpkg_dir

# copy files
cp -a $PKG_BASE/* $dpkg_dir

# setup dpkg + build
mkdir -p $dpkg_dir/DEBIAN
cat >$dpkg_dir/DEBIAN/control <<EOc
Package: $PKG_NAME
Version: $PKG_VERSION
Section: contrib
Priority: optional
Architecture: $PKG_ARCH
Depends: perl (>= 5.32.1)
Maintainer: $AUTHOR
Description: http CPAN module for perl, using libcurl
 Uses perl.
EOc

cat >$dpkg_dir/DEBIAN/conffiles <<EOcfgf
EOcfgf

dpkg-deb --build $dpkg_dir/
echo "file $(pwd)/$PKG_NAME-${PKG_VERSION}.deb"
mv $tmp_dpkg_dir/*.deb "$PKG_NAME-${PKG_VERSION}_${PKG_ARCH}.deb"
