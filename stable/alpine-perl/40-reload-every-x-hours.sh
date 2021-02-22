#!/bin/sh

set -e

ME=$(basename $0)

[ "${NGINX_ENTRYPOINT_NGINX_RELOAD_EVERY_X_HOURS:-}" ] || exit 0
if [ $(echo "$NGINX_ENTRYPOINT_NGINX_RELOAD_EVERY_X_HOURS > 0" | bc) == 0 ]; then
  echo >&3 "$ME: Error. Provide integer or floating point number greater that 0. See 'man sleep'." 
  exit 1
fi

start_background_reload() {
  echo >&3 "$ME: Reloading Nginx every $NGINX_ENTRYPOINT_NGINX_RELOAD_EVERY_X_HOURS hour(s)"
  while :; do sleep ${NGINX_ENTRYPOINT_NGINX_RELOAD_EVERY_X_HOURS}h; echo >&3 "$ME: Reloading Nginx ..." && nginx -s reload; done &
}

start_background_reload