FROM debian:stretch AS build

LABEL maintainer="NGINX Docker Maintainers <docker-maint@nginx.com>"

ARG PCRE_VERSION="8.42"
ARG PCRE_CHECKSUM="69acbc2fbdefb955d42a4c606dfde800c2885711d2979e356c0636efde9ec3b5"

ARG ZLIB_VERSION="1.2.11"
ARG ZLIB_CHECKSUM="c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"

ARG OPENSSL_VERSION="1.1.1a"
ARG OPENSSL_CHECKSUM="fc20130f8b7cbd2fb918b2f14e2f429e109c31ddd0fb38fc5d71d9ffed3f9f41"

ARG NGINX_VERSION="1.15.8"
ARG NGINX_CHECKSUM="a8bdafbca87eb99813ae4fcac1ad0875bf725ce19eb265d28268c309b2b40787"
ARG NGINX_CONFIG="\
    --with-cc-opt='-static' \
    --with-ld-opt='-static' \
    --sbin-path=/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/tmp/nginx.pid \
    --http-log-path=/dev/stdout \
    --error-log-path=/dev/stdout \
    --http-client-body-temp-path=/tmp/client_temp \
    --http-proxy-temp-path=/tmp/proxy_temp \
    --http-fastcgi-temp-path=/tmp/fastcgi_temp \
    --http-uwsgi-temp-path=/tmp/uwsgi_temp \
    --http-scgi-temp-path=/tmp/scgi_temp \
    --with-pcre=/tmp/pcre-$PCRE_VERSION \
    --with-openssl=/tmp/openssl-$OPENSSL_VERSION \
    --with-zlib=/tmp/zlib-$ZLIB_VERSION \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads"

ADD https://ftp.pcre.org/pub/pcre/pcre-$PCRE_VERSION.tar.gz /tmp/pcre.tar.gz
ADD https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz /tmp/openssl.tar.gz
ADD https://zlib.net/zlib-$ZLIB_VERSION.tar.gz /tmp/zlib.tar.gz
ADD https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz /tmp/nginx.tar.gz

WORKDIR /tmp
RUN if [ "$PCRE_CHECKSUM" != "$(sha256sum /tmp/pcre.tar.gz | awk '{print $1}')" ]; then exit 1; fi && \
    tar xf /tmp/pcre.tar.gz && \
    if [ "$ZLIB_CHECKSUM" != "$(sha256sum /tmp/zlib.tar.gz | awk '{print $1}')" ]; then exit 1; fi && \
    tar xf /tmp/zlib.tar.gz && \
    if [ "$OPENSSL_CHECKSUM" != "$(sha256sum /tmp/openssl.tar.gz | awk '{print $1}')" ]; then exit 1; fi && \
    tar xf /tmp/openssl.tar.gz && \
    if [ "$NGINX_CHECKSUM" != "$(sha256sum /tmp/nginx.tar.gz | awk '{print $1}')" ]; then exit 1; fi && \
    tar xf /tmp/nginx.tar.gz && \
    mv /tmp/nginx-$NGINX_VERSION /tmp/nginx

WORKDIR /tmp/nginx
RUN apt update && \
    apt install -y git gcc g++ make && \
    ./configure $NGINX_CONFIG && \
    make


FROM scratch

COPY rootfs /

COPY --from=build /lib/x86_64-linux-gnu/ld-2.24.so /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
                  /lib/x86_64-linux-gnu/libc-2.24.so /lib/x86_64-linux-gnu/libc.so.6 \
                  /lib/x86_64-linux-gnu/libnss_files-2.24.so /lib/x86_64-linux-gnu/libnss_files.so.2 \
                  /lib/x86_64-linux-gnu/
COPY --from=build /tmp/nginx/objs/nginx /nginx
COPY --from=build /tmp/nginx/html /etc/nginx/html

STOPSIGNAL SIGTERM

ENTRYPOINT ["/nginx", "-g", "daemon off;"]
