#!/usr/bin/env sh
# vim:sw=4:ts=4:et

set -e

if [ "$1" = "nginx" ]; then
    if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -print -quit 2>/dev/null | /bin/grep -q .; then
        echo "$0: /docker-entrypoint.d/ is not empty, will attempt to perform an initial configuration"

        echo "$0: Looking for shell scripts in /docker-entrypoint.d/"
        for f in $(/usr/bin/find /docker-entrypoint.d/ -type f -name "*.sh" -executable | sort -n); do
            echo "$0: Launching $f";
            "$f"
        done

        # warn on shell scripts without exec bit
        for f in $(/usr/bin/find /docker-entrypoint.d/ -type f -name "*.sh" -not -executable); do
            echo "$0: Ignoring $f, not executable";
        done
        # warn on filetypes we don't know what to do with
        for f in $(/usr/bin/find /docker-entrypoint.d/ -type f -not -name "*.sh"); do
            echo "$0: Ignoring $f";
        done

        echo "$0: Initial configuration complete; ready for start up"
    else
        echo "$0: /docker-entrypoint.d/ is empty, skipping initial configuration"
    fi
fi

exec "$@"
