FROM quay.io/cdis/ubuntu:18.04

#
# point at nginx apt package repo, and install nginx,
# pre-package modules, and build dependencies
# https://nginx.org/en/linux_packages.html#Ubuntu
#
RUN apt-get update && \
    apt -y install curl gnupg2 ca-certificates lsb-release git less libyajl-dev logrotate && \
    echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list && \
    echo "deb http://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list && \
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -&& \
    apt-key fingerprint ABF5BD827BD9BF62 && \
    apt update && \
    apt install nginx nginx-module-njs nginx-module-perl -y && \
    apt-get install -y dnsutils git wget build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-dev libxml2-dev libcurl4-openssl-dev automake pkgconf vim && \
    apt clean && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
	  ln -sf /dev/stderr /var/log/nginx/error.log && \
    ln -sf /dev/stdout /var/log/modsec_audit.log

#
# Put compiled module source under /usr/src
#
WORKDIR /usr/src

#
# build libmodsecurity
#    https://www.nginx.com/blog/compiling-and-installing-modsecurity-for-open-source-nginx/
#
RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity /usr/src/modsecurity && \
	cd /usr/src/modsecurity && \
  git submodule init && \
  git submodule update && \
	./build.sh && \
	./configure && \
	make && \
  make install

#
# download nginx headers-more module:
#    https://github.com/openresty/headers-more-nginx-module
#
# download the modsecurity nginx connector
#   https://www.nginx.com/blog/compiling-and-installing-modsecurity-for-open-source-nginx/#    https://drive.google.com/drive/u/1/folders/1ky_9gL_stSEHupRty6EjFBefRPW4qJGj
#
#
RUN wget https://github.com/openresty/headers-more-nginx-module/archive/v0.34.tar.gz && \
	tar xvzf v0.34.tar.gz && \
  git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git

#
# download nginx source, and build the nginx modules
#   https://www.nginx.com/blog/compiling-dynamic-modules-nginx-plus/
#
RUN nginver=$(nginx -v 2>&1 | awk -F / '{ print $2 }') && \
    wget http://nginx.org/download/nginx-${nginver}.tar.gz && \
    tar zxvf nginx-${nginver}.tar.gz && \
    cd nginx-$nginver && \
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx --add-dynamic-module=../headers-more-nginx-module-0.34 && \
    make modules && \
    cp objs/*.so /etc/nginx/modules

#
# Uncomment to include CIS Assessor tools:
#    https://workbench.cisecurity.org/
#
# Note: build fails in quay with .zip COPY, but can
#   build a local image for test/cis/ or to push.
#
#COPY Assessor-CLI-v4.0.17.zip /mnt/Assessor-CLI/
#RUN apt update && apt install openjdk-11-jre rsync zip unzip -y && apt clean;

EXPOSE 80
STOPSIGNAL SIGTERM
CMD nginx -g 'daemon off;'
