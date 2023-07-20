#!/bin/sh
# vim:sw=4:ts=4:et

set -e

entrypoint_log() {
    if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

if [ "$1" = "nginx" -o "$1" = "nginx-debug" ]; then
    # check if /etc/nginx directory is writable
    if touch /etc/nginx/.is-writable 2>/dev/null; then
        rm -f /etc/nginx/.is-writable
        # check if there are docker entrypoint scripts
        if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
            entrypoint_log "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

            entrypoint_log "$0: Looking for shell scripts in /docker-entrypoint.d/"
            find "/docker-entrypoint.d/" -follow -type f -print | sort -V | while read -r f; do
                case "$f" in
                    *.envsh)
                        if [ -x "$f" ]; then
                            entrypoint_log "$0: Sourcing $f";
                            . "$f"
                        else
                            # warn on shell scripts without exec bit
                            entrypoint_log "$0: Ignoring $f, not executable";
                        fi
                        ;;
                    *.sh)
                        if [ -x "$f" ]; then
                            entrypoint_log "$0: Launching $f";
                            "$f"
                        else
                            # warn on shell scripts without exec bit
                            entrypoint_log "$0: Ignoring $f, not executable";
                        fi
                        ;;
                    *) entrypoint_log "$0: Ignoring $f";;
                esac
            done

            entrypoint_log "$0: Configuration complete; ready for start up"
        else
            entrypoint_log "$0: No files found in /docker-entrypoint.d/, skipping configuration"
        fi
    else
        entrypoint_log "$0: Cannot modify contents inside /etc/nginx/ (read-only file system?), skipping configuration"
    fi
fi

exec "$@"
