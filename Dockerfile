ARG ARCH
FROM --platform=${ARCH} debian:bookworm-slim AS builder-base
ADD https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2024-11-19/2024-11-19-raspios-bookworm-armhf-lite.img.xz /tmp/
RUN apt update && apt install -y xz-utils file p7zip
WORKDIR /
ARG ARCH
ENV platform_arch=${ARCH}
RUN \[ "${platform_arch}" == "linux/arm/v6" \] \
    && mkdir -p /stage \
    && cd /stage \
    && xz -d /tmp/2024-11-19-raspios-bookworm-armhf-lite.img.xz \
    && 7z x /tmp/*.img \
    && pwd \
    && ls -l \
    && 7z x -snld 1.img \
    && rm -f 1.img 0.fat \
    && rm -rf tmp \
    && mkdir -p tmp \
    && chmod 1777 tmp \
    || exit 0
RUN \[ "${platform_arch}" != "linux/arm/v6" \] && ln -s / /stage || exit 0

FROM scratch AS builder
COPY --from=builder-base /stage /
RUN echo "GMT" > /etc/timezone
RUN ln -sfT /usr/share/zoneinfo/right/GMT /etc/localtime
ENV TERM=
RUN apt install -y dpkg gawk dialog

FROM builder AS deb-pkg-build
RUN apt install -y zlib1g-dev libssl-dev libsocket6-perl perl make gcc ca-certificates
ADD https://curl.se/download/curl-8.11.1.tar.gz /tmp/
COPY build_curl.sh /build/
WORKDIR /tmp
RUN tar xfz curl-*.tar.gz
WORKDIR /
ENV CURL_PATH=/opt
ENV PKG_BASE=/pkgbase
RUN cd /tmp/curl-* && sh /build/build_curl.sh "$PKG_BASE" "$CURL_PATH"
RUN LD_LIBRARY_PATH=$PKG_BASE/$CURL_PATH/lib/ $PKG_BASE/$CURL_PATH/bin/curl --version
WORKDIR /build
COPY build_cpan.sh /build/
COPY curl_constants.PL Makefile.PL MANIFEST* /build/
COPY t /build/t
COPY lib /build/lib
RUN sh /build/build_cpan.sh "$PKG_BASE" "$CURL_PATH"
WORKDIR /
RUN rm -rf \
        $PKG_BASE/$CURL_PATH/include \
        $PKG_BASE/$CURL_PATH/bin/curl-config \
        $PKG_BASE/$CURL_PATH/bin/curl \
        $PKG_BASE/$CURL_PATH/share \
        $PKG_BASE/$CURL_PATH/lib/*.la \
        $PKG_BASE/$CURL_PATH/lib/pkgconfig \
        $PKG_BASE/$CURL_PATH/lib/*.a
RUN find $PKG_BASE/$CURL_PATH -type f -name '*.so*' -exec strip --strip-unneeded {} \;
ENV PKG_DIST=/pkgdist
RUN mkdir -p $PKG_DIST && mv $PKG_BASE/* $PKG_DIST/
RUN \
    LD_LIBRARY_PATH=$PKG_DIST/opt/lib \
    PERL5LIB=$PKG_DIST/opt/lib/perl \
        perl -MData::Dumper \
             -Mutils::curl \
             -we \
             'print "VERSION: $utils::curl::VERSION\n".Dumper(http::curl_version_info())."\n";'
RUN LD_LIBRARY_PATH=$PKG_DIST/opt/lib PERL5LIB=$PKG_DIST/opt/lib/perl perl -Mutils::curl -e 'print $utils::curl::VERSION' > $PKG_DIST/VERSION && cat $PKG_DIST/VERSION
COPY package_deb.sh /build
ARG ARCH
ENV platform_arch=${ARCH}
ENV AUTHOR="m@local"
WORKDIR /pkg
RUN PKG_VERSION=$(cat $PKG_DIST/VERSION; rm -f $PKG_DIST/VERSION) PKG_ARCH=$platform_arch PKG_NAME=utils-curl PKG_BASE=$PKG_DIST \
    bash /build/package_deb.sh

FROM scratch AS pkg
ARG CACHEBUST=1
COPY --from=deb-pkg-build /pkg /
