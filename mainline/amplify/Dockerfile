FROM debian:stretch-slim

LABEL maintainer="NGINX Amplify Engineering"

ENV NGINX_VERSION         1.13.6-1~stretch
ENV NJS_VERSION           1.13.6.0.1.14-1~stretch
ENV AMPLIFY_AGENT_VERSION 0.46-2~stretch

RUN set -x \
    && deps="apt-transport-https apt-utils gnupg1 ca-certificates" \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y $deps \
    && echo "deb https://packages.amplify.nginx.com/debian/ stretch amplify-agent" > /etc/apt/sources.list.d/nginx-amplify.list \
    && echo "deb http://nginx.org/packages/mainline/debian/ stretch nginx" >> /etc/apt/sources.list.d/nginx.list \
    && \
    NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
    found=''; \
    for server in \
        ha.pool.sks-keyservers.net \
        hkp://keyserver.ubuntu.com:80 \
        hkp://p80.pool.sks-keyservers.net:80 \
        pgp.mit.edu \
    ; do \
        echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
        apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
    apt-get update \
    && nginxPackages=" \
        nginx=${NGINX_VERSION} \
        nginx-module-xslt=${NGINX_VERSION} \
        nginx-module-geoip=${NGINX_VERSION} \
        nginx-module-image-filter=${NGINX_VERSION} \
        nginx-module-njs=${NJS_VERSION} \
        nginx-amplify-agent=${AMPLIFY_AGENT_VERSION} \
    " \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        $nginxPackages \
        gettext-base \
        procps \
    && apt-get remove --purge --auto-remove -y $deps \
    && rm -rf /etc/apt/sources.list.d/nginx-amplify.list \
    && rm -rf /etc/apt/sources.list.d/nginx-amplify.list \
    && rm -rf /var/lib/apt/lists/*

# Copy nginx stub_status config
COPY ./conf.d/stub_status.conf /etc/nginx/conf.d

# API_KEY is required for configuring the NGINX Amplify Agent.
# It could be your real API key for NGINX Amplify here if you wanted
# to build your own image to host it in a private registry.
# However, including private keys in the Dockerfile is not recommended.
# Use the environment variables at runtime as described below.

#ENV API_KEY 1234567890

# If AMPLIFY_IMAGENAME is set, the startup wrapper script will use it to
# generate the 'imagename' to put in the /etc/amplify-agent/agent.conf
# If several instances use the same 'imagename', the metrics will
# be aggregated into a single object in NGINX Amplify. Otherwise Amplify
# will create separate objects for monitoring (an object per instance).
# AMPLIFY_IMAGENAME can also be passed to the instance at runtime as
# described below.

#ENV AMPLIFY_IMAGENAME my-docker-instance-123

# The /entrypoint.sh script will launch nginx and the Amplify Agent.
# The script honors API_KEY and AMPLIFY_IMAGENAME environment
# variables, and updates /etc/amplify-agent/agent.conf accordingly.

COPY ./entrypoint.sh /entrypoint.sh

# TO set/override API_KEY and AMPLIFY_IMAGENAME when starting an instance:
# docker run --name my-nginx1 -e API_KEY='..effc' -e AMPLIFY_IMAGENAME="service-name" -d nginx-amplify

EXPOSE 80

STOPSIGNAL SIGTERM

ENTRYPOINT ["/entrypoint.sh"]
