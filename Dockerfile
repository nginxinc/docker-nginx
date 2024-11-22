ARG AZLINUX_BASE_VERSION=master

# For local development
FROM quay.io/cdis/amazonlinux-base:${AZLINUX_BASE_VERSION}

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

RUN dnf install -y nginx-module-njs-0:1.24.0+0.8.3-1.amzn2023.ngx nginx-module-njs-0:1.24.0+0.8.3-1.amzn2023.ngx nginx


EXPOSE 80
STOPSIGNAL SIGTERM
CMD nginx -g 'daemon off;'
