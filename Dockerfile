FROM alpine:latest AS raspberry-pi-builder-base
ADD https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2024-11-19/2024-11-19-raspios-bookworm-armhf-lite.img.xz /tmp/
RUN apk --update add xz file p7zip
WORKDIR /stage
RUN xz -d /tmp/2024-11-19-raspios-bookworm-armhf-lite.img.xz
RUN 7z x /tmp/*.img && pwd && ls -l && 7z x -snld 1.img && rm -f 1.img 0.fat
RUN rm -rf tmp; mkdir -p tmp; chmod 1777 tmp

FROM scratch AS raspberry-pi-builder
COPY --from=raspberry-pi-builder-base /stage /
RUN chown -R man:man /var/cache/man
RUN echo "GMT" > /etc/timezone
RUN ln -sfT /usr/share/zoneinfo/right/GMT /etc/localtime
ENV TERM=
RUN apt install -y dpkg gawk dialog

FROM raspberry-pi-builder AS deb-pkg-build
RUN apt install -y zlib1g-dev libssl-dev libsocket6-perl perl make gcc
ADD https://curl.se/download/curl-8.11.1.tar.gz /tmp/
WORKDIR /tmp
RUN tar xfz curl-*.tar.gz
WORKDIR /
ENV CURL_PATH=/opt
RUN cd /tmp/curl-* && ./configure \
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
    && make install DESTDIR=/pkgbase
WORKDIR /build
ARG CACHEBUST=1
COPY . /build
RUN LIBCURL_LIB=/pkgbase/$CURL_PATH/lib/ \
    LIBCURL_INC=/pkgbase/$CURL_PATH/include/ \
    LD_LIBRARY_PATH=/pkgbase/$CURL_PATH/lib/ \
    PERL_MM_OPT="INSTALLDIRS=site INSTALL_BASE=$CURL_PATH/ INSTALLSITEARCH=$CURL_PATH/lib/perl" \
    perl Makefile.PL \
    && make \
    && make test \
    && make install DESTDIR=/pkgbase
WORKDIR /pkgbase
RUN rm -rf \
        /pkgbase/$CURL_PATH/include \
        /pkgbase/$CURL_PATH/bin/curl-config \
        /pkgbase/$CURL_PATH/bin/curl \
        /pkgbase/$CURL_PATH/share \
        /pkgbase/$CURL_PATH/lib/*.la \
        /pkgbase/$CURL_PATH/lib/pkgconfig \
        /pkgbase/$CURL_PATH/lib/*.a
RUN PERL5LIB=/pkgbase/$CURL_PATH/lib/perl \
        perl -MData::Dumper \
             -Mutils::curl \
             -we \
             'print "VERSION: $utils::curl::VERSION\n".Dumper(http::curl_version_info())."\n";'
ARG VERSION=1.0.1
ARG AUTHOR='<me@home>'
ENV AUTHOR="$AUTHOR"
ENV VERSION="$VERSION"

FROM scratch AS pkg
COPY --from=deb-pkg-build /pkg /
