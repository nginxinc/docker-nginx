#FROM quay.io/cdis/ubuntu:18.04

ARG AZLINUX_BASE_VERSION=master

# For local development
FROM quay.io/cdis/amazonlinux-base:${AZLINUX_BASE_VERSION}

#
# point at nginx apt package repo, and install nginx,
# pre-package modules, and build dependencies
# https://nginx.org/en/linux_packages.html#Ubuntu
#
# RUN apt-get update && \
#   apt -y install curl gnupg2 ca-certificates lsb-release git less libyajl-dev logrotate && \
#   echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
#   | tee /etc/apt/sources.list.d/nginx.list && \
#   echo "deb http://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" \
#   | tee /etc/apt/sources.list.d/nginx.list && \
#   curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -&& \
#   apt-key fingerprint ABF5BD827BD9BF62 && \
#   apt update && \
#   apt install nginx=1.19.10-1~bionic nginx-module-njs=1.19.10+0.5.3-1~bionic nginx-module-perl=1.19.10-1~bionic -y && \
#   apt-get install -y dnsutils git wget build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-dev libxml2-dev libcurl4-openssl-dev automake pkgconf vim && \
#   apt clean && \
#   ln -sf /dev/stdout /var/log/nginx/access.log && \
#   ln -sf /dev/stderr /var/log/nginx/error.log && \
#   ln -sf /dev/stdout /var/log/modsec_audit.log

RUN cat <<EOT >> /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/amzn/2023/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
priority=9

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/amzn/2023/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
priority=9
EOT

RUN dnf install -y nginx-0:1.24.0-1.amzn2023.ngx nginx-module-njs-0:1.24.0+0.8.3-1.amzn2023.ngx nginx-module-njs-0:1.24.0+0.8.3-1.amzn2023.ngx git dnsutils wget

#libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-dev libxml2-dev libcurl4-openssl-dev automake pkgconf

#
# Put compiled module source under /usr/src
#
WORKDIR /usr/src

#
# build libmodsecurity
#    https://www.nginx.com/blog/compiling-and-installing-modsecurity-for-open-source-nginx/
#
RUN yum install gcc-c++ flex bison  libxml2-devel doxygen zlib-devel git automake libtool pcre-devel \
  cd /opt/ \
  # Steal Fedora's YAJL and YAJL-devel packages
  wget https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/23/Everything/x86_64/os/Packages/y/yajl-2.1.0-4.fc23.x86_64.rpm &&\
  rpm -i yajl-2.1.0-4.fc23.x86_64.rpm &&\
  wget https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/23/Everything/x86_64/os/Packages/y/yajl-devel-2.1.0-4.fc23.x86_64.rpm &&\
  rpm -i yajl-devel-2.1.0-4.fc23.x86_64.rpm &&\
  # Install latest bison
  yum install https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/23/x86_64/b/bison-3.0.4-3.fc23.x86_64.rpm &&\
  # Amazon's GeoIP-devel package does not come with geoip.pc (no idea why not)
  wget ftp://rpmfind.net/linux/centos/5.11/extras/x86_64/RPMS/GeoIP-data-20090201-1.el5.centos.x86_64.rpm &&\
  wget ftp://rpmfind.net/linux/fedora/linux/releases/23/Everything/x86_64/os/Packages/g/GeoIP-1.6.6-1.fc23.x86_64.rpm &&\
  wget ftp://rpmfind.net/linux/fedora/linux/releases/23/Everything/x86_64/os/Packages/g/GeoIP-devel-1.6.6-1.fc23.x86_64.rpm &&\
  rpm -i GeoIP-1.6.6-1.fc23.x86_64.rpm  GeoIP-data-20090201-1.el5.centos.x86_64.rpm &&\
  rpm -i GeoIP-devel-1.6.6-1.fc23.x86_64.rpm &&\
  rm -rf *.rpm &&\
  git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity /usr/src/modsecurity && \
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
