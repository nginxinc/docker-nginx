#!/bin/sh
# vim:sw=4:ts=4:et

set -e

ME=$(basename $0)
DEFAULT_CONF_FILE="etc/nginx/conf.d/default.conf"

# check if we have ipv6 available
if [ ! -f "/proc/net/if_inet6" ]; then
    echo "$ME: ipv6 not available, exiting" 1>&2
    exit 0
fi

if [ ! -f "/$DEFAULT_CONF_FILE" ]; then
    echo "$ME: /$DEFAULT_CONF_FILE is not a file or does not exist, exiting" 1>&2
    exit 0
fi

# check if the file can be modified, e.g. not on a r/o filesystem
touch /$DEFAULT_CONF_FILE 2>/dev/null || { echo "$ME: Can not modify /$DEFAULT_CONF_FILE (read-only file system?), exiting"; exit 0; }

# check if the file is already modified, e.g. on a container restart
grep -q "listen  \[::]\:80;" /$DEFAULT_CONF_FILE && { echo "$ME: IPv6 listen already enabled, exiting"; exit 0; }

if [ -f "/etc/os-release" ]; then
    . /etc/os-release
else
    echo "$ME: can not guess the operating system, exiting" 1>&2
    exit 0
fi

echo "$ME: Getting the checksum of /$DEFAULT_CONF_FILE"

case "$ID" in
    "debian")
        CHECKSUM=$(dpkg-query --show --showformat='${Conffiles}\n' nginx | grep $DEFAULT_CONF_FILE | cut -d' ' -f 3)
        echo "$CHECKSUM  /$DEFAULT_CONF_FILE" | md5sum -c - >/dev/null 2>&1 || {
            echo "$ME: /$DEFAULT_CONF_FILE differs from the packaged version, exiting" 1>&2
            exit 0
        }
        ;;
    "alpine")
        CHECKSUM=$(apk manifest nginx 2>/dev/null| grep $DEFAULT_CONF_FILE | cut -d' ' -f 1 | cut -d ':' -f 2)
        echo "$CHECKSUM  /$DEFAULT_CONF_FILE" | sha1sum -c - >/dev/null 2>&1 || {
            echo "$ME: /$DEFAULT_CONF_FILE differs from the packages version, exiting" 1>&2
            exit 0
        }
        ;;
    *)
        echo "$ME: Unsupported distribution, exiting" 1>&2
        exit 0
        ;;
esac

# enable ipv6 on default.conf listen sockets
sed -i -E 's,listen       80;,listen       80;\n    listen  [::]:80;,' /$DEFAULT_CONF_FILE

echo "$ME: Enabled listen on IPv6 in /$DEFAULT_CONF_FILE"

exit 0
