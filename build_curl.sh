#!/bin/bash

set -e

PKG_BASE=${1:-/pkgbase}
shift
CURL_PATH=${1:-/opt/curl}
shift

./configure \
    --without-ca-embed \
    --without-libpsl \
    --without-libgsasl \
    --without-libssh2 \
    --without-libssh \
    --with-openssl \
    --without-brotli \
    --disable-ftp \
    --disable-tftp \
    --with-nghttp2 \
    --without-ldap \
    --disable-pop3 \
    --disable-imap \
    --disable-smb \
    --disable-smtp \
    --disable-telnet \
    --disable-gopher \
    --disable-rtsp \
    --disable-dnsshuffle \
    --enable-get-easy-options \
    --enable-websockets \
    --disable-alt-svc \
    --disable-docs \
    --disable-dict \
    --disable-ipfs \
    --disable-ipns \
    --disable-mqtt \
    --disable-file \
    --enable-ipv6 \
    --disable-openssl-auto-load-config \
    --enable-shared \
    --enable-aws \
    --disable-unix-sockets \
    --disable-mime \
    --disable-form-api \
    --without-librtmp \
    --without-apple-idn \
    --without-winidn \
    --disable-threaded-resolver \
    --prefix=$CURL_PATH \
    && make -j4 \
    && make install DESTDIR=$PKG_BASE
