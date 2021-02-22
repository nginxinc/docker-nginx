#!/bin/sh

set -e

ME=$(basename $0)

[ "${NGINX_ENTRYPOINT_NGINX_RELOAD_EVERY_X_HOURS:-}" ] || exit 0

start_background_reload() {
  echo >&3 "$ME: Reloading Nginx every $NGINX_ENTRYPOINT_NGINX_RELOAD_EVERY_X_HOURS hours"
  while :; do sleep ${NGINX_ENTRYPOINT_NGINX_RELOAD_EVERY_X_HOURS}h; echo >&3 "$ME: Reloading Nginx ..." && nginx -s reload; done &
}

start_background_reload