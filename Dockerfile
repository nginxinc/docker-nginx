FROM ubuntu:18.04

# See https://nginx.org/en/linux_packages.html#mainline
RUN apt update && \
  apt install curl gnupg2 ca-certificates lsb-release vim less -y && \
  echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list && \
  curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - && \
  apt update && \
  apt install nginx nginx-plus-module-headers-more -y && \
  rm -rf /var/lib/apt/lists/*