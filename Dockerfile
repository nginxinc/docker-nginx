FROM debian:wheezy

MAINTAINER NGINX Docker Maintainers "docker-maint@nginx.com"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q wget
RUN wget -q -O - http://nginx.org/keys/nginx_signing.key | apt-key add -
RUN echo "deb http://nginx.org/packages/mainline/debian/ wheezy nginx" >> /etc/apt/sources.list
RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

# forward request logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log

# be backwards compatible with pre-official images
RUN ln -sf ../share/nginx /usr/local/nginx

VOLUME ["/usr/share/nginx/html"]
VOLUME ["/etc/nginx"]

EXPOSE 80 443

CMD ["/usr/sbin/nginx", "-c", "/etc/nginx/nginx.conf", "-g", "daemon off; error_log /dev/stderr warn;"]
