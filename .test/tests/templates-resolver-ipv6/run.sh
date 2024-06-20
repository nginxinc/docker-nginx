#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail

# check if we have ipv6 available
if [ ! -f "/proc/net/if_inet6" ]; then
    exit 0
fi

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

clientImage='buildpack-deps:buster-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

# Create a new Docker network
nid="$(docker network create --ipv6 --subnet fd0c:7e57::/64 nginx-test-ipv6-network)"

_network_exit_handler() {
    docker network rm -f $nid > /dev/null
}

# Create an instance of the container-under-test
serverImage="$("$HOME/oi/test/tests/image-name.sh" librarytest/nginx-template "$image")"
"$HOME/oi/test/tests/docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
COPY dir/server.conf.template /etc/nginx/templates/server.conf.template
EOD
cid="$(docker run -d --network $nid -e NGINX_ENTRYPOINT_LOCAL_RESOLVERS=true -e NGINX_MY_SERVER_NAME=example.com "$serverImage")"

_container_exit_handler() {
    docker rm -vf $cid > /dev/null
}
_exit_handler() { _container_exit_handler; _network_exit_handler; }
trap "_exit_handler" EXIT

ipv6cid="$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.GlobalIPv6Address}}{{end}}' $cid)"

_request() {
	local method="$1"
	shift

	local proto="$1"
	shift

	local url="${1#/}"
	shift

	if [ "$(docker inspect -f '{{.State.Running}}' "$cid" 2>/dev/null)" != 'true' ]; then
		echo >&2 "$image stopped unexpectedly!"
		( set -x && docker logs "$cid" ) >&2 || true
		false
	fi

	docker run --rm \
		--network "$nid" \
		"$clientImage" \
		curl -fsSL -X"$method" --connect-to "::[$ipv6cid]:" "$@" "$proto://example.com/$url"
}

. "$HOME/oi/test/retry.sh" '[ "$(_request GET / --output /dev/null || echo $?)" != 7 ]'

# Check that we can request /
_request GET http '/resolver-templates' | grep 'example.com - OK'
