#!/bin/sh
set -e

# This entrypoint allows Nginx gid/uid customization.
# By default Nginx will use automatically generated gid/uid.
# User can override both gid and uid by passing environment variables to the container.
# Set "NGINX_GID" to change Nginx gid (must not be equal to non-nginx gid in the image).
# Set "NGINX_UID" to change Nginx uid (must not be equal to non-nginx uid in the image).
# Normally, gid and uid are the same number.
# Stable gid/uid allows user pre-configure disk volumes with proper file ownership.
# Note: changing gid/uid doesn't change ownership of already created files with previous gid/uid values (but there shouldn't be any).

if [ -z "$NGINX_GID" ]; then
    nginx_gid="$(id -g nginx)"
    echo "Using default gid for Nginx: $nginx_gid. Note: default gid is not guaranteed to be stable across image updates. You can set NGINX_GID environment variable to customize Nginx gid."
else
    groupmod -g "$NGINX_GID" nginx
    echo "Nginx gid has been changed to $NGINX_GID."
fi

if [ -z "$NGINX_UID" ]; then
    nginx_uid="$(id -u nginx)"
    echo "Using default uid for Nginx: $nginx_uid. Note: default uid is not guaranteed to be stable across image updates. You can set NGINX_UID environment variable to customize Nginx uid."
else
    usermod -u "$NGINX_UID" nginx
    echo "Nginx uid has been changed to $NGINX_UID."
fi

exec "$@"
