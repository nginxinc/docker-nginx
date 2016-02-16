FROM centos:6

MAINTAINER NGINX Docker Maintainers "docker-maint@nginx.com"

ENV NGINX_VERSION 1.9.11-1.el6.ngx

COPY ./nginx.repo /etc/yum.repos.d/nginx.repo

RUN rpm --import http://nginx.org/keys/nginx_signing.key \
	&& yum install -y ca-certificates nginx-${NGINX_VERSION} gettext \
	&& yum clean all

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
