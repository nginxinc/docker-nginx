#!/bin/sh
# vim:sw=2:ts=2:sts=2:et

set -e

entrypoint_log() {
  if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
    echo "$@"
  fi
}

if [ "$1" = "nginx" ] || [ "$1" = "nginx-debug" ]; then
  if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
      entrypoint_log "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

    entrypoint_log "$0: info: Looking for shell scripts in /docker-entrypoint.d/"
    find "/docker-entrypoint.d/" -follow -type f -print | sort -V | while read -r f; do
      case "$f" in
      *.envsh)
        if [ -x "$f" ]; then
          entrypoint_log "$0: info: Sourcing $f"
          . "$f"
        else
          # warn on shell scripts without exec bit
          entrypoint_log "$0: info: Ignoring $f, not executable"
        fi
        ;;
      *.sh)
        if [ -x "$f" ]; then
          entrypoint_log "$0: info: Launching $f"
          "$f"
        else
          # warn on shell scripts without exec bit
          entrypoint_log "$0: info: Ignoring $f, not executable"
        fi
        ;;
      *) entrypoint_log "$0: info: Ignoring $f" ;;
      esac
    done

    entrypoint_log "$0: info: Configuration complete; ready for start up"
  else
    entrypoint_log "$0: info: No files found in /docker-entrypoint.d/, skipping configuration"
  fi
fi

exec "$@"
