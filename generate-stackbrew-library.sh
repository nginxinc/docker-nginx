#!/bin/bash
set -eu

declare -A aliases
aliases=(
	[mainline]='1 1.17 latest'
	[stable]='1.16'
)

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
base=buster

versions=( */ )
versions=( "${versions[@]%/}" )

# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile" or any file COPY'd from "$1/Dockerfile"
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
		fileCommit \
			Dockerfile \
			$(git show HEAD:./Dockerfile | awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++) {
						print $i
					}
				}
			')
	)
}

cat <<-EOH
# this file is generated via https://github.com/nginxinc/docker-nginx/blob/$(fileCommit "$self")/$self

Maintainers: NGINX Docker Maintainers <docker-maint@nginx.com> (@nginxinc)
GitRepo: https://github.com/nginxinc/docker-nginx.git
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

for version in "${versions[@]}"; do
	commit="$(dirCommit "$version/$base")"

	fullVersion="$(git show "$commit":"$version/$base/Dockerfile" | awk '$1 == "ENV" && $2 == "NGINX_VERSION" { print $3; exit }')"

	versionAliases=( $fullVersion )
	if [ "$version" != "$fullVersion" ]; then
		versionAliases+=( $version )
	fi
	versionAliases+=( ${aliases[$version]:-} )

	echo
	cat <<-EOE
		Tags: $(join ', ' "${versionAliases[@]}")
		Architectures: amd64, arm32v7, arm64v8, i386, ppc64le, s390x
		GitCommit: $commit
		Directory: $version/$base
	EOE

	for variant in buster-perl; do
		commit="$(dirCommit "$version/$variant")"

		variantAliases=( "${versionAliases[@]/%/-perl}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

		echo
		cat <<-EOE
			Tags: $(join ', ' "${variantAliases[@]}")
			Architectures: amd64, arm32v7, arm64v8, i386, ppc64le, s390x
			GitCommit: $commit
			Directory: $version/$variant
		EOE
	done

	for variant in alpine alpine-perl; do
		commit="$(dirCommit "$version/$variant")"

		variantAliases=( "${versionAliases[@]/%/-$variant}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

		echo
		cat <<-EOE
			Tags: $(join ', ' "${variantAliases[@]}")
			Architectures: amd64, arm32v6, arm64v8, i386, ppc64le, s390x
			GitCommit: $commit
			Directory: $version/$variant
		EOE
	done

done
