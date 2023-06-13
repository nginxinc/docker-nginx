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

cid="$(docker run -d "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

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
		--link "$cid":nginx \
		"$clientImage" \
		curl -fsSL -X"$method" --connect-to '::nginx:' "$@" "$proto://example.com/$url"
}

. "$HOME/oi/test/retry.sh" '[ "$(_request GET / --output /dev/null || echo $?)" != 7 ]'

# Check that we can request /
_request GET http '/index.html' | grep '<h1>Welcome to nginx!</h1>'

docker logs $cid 2>&1 | grep "Enabled listen on IPv6"
