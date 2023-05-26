#!/bin/bash
set -eu

image="nginx"
registry="public.ecr.aws/z9d2n7e1"

declare -A aliases
aliases=(
	[mainline]='1 1.25 latest'
	[stable]='1.24'
)

architectures=( amd64 arm64v8 )

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
base=debian

versions=( mainline stable )

pulllist=()
declare -A taglist
taglist=()

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

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

for version in "${versions[@]}"; do
	commit="$(dirCommit "$version/$base")"
	fullVersion="$(git show "$commit":"$version/$base/Dockerfile" | awk '$1 == "ENV" && $2 == "NGINX_VERSION" { print $3; exit }')"
    pulllist+=( "$image:$fullVersion" )
    for variant in perl alpine alpine-perl alpine-slim; do
        pulllist+=( "$image:$fullVersion-$variant" )
    done
done

for version in "${versions[@]}"; do
	commit="$(dirCommit "$version/$base")"

	fullVersion="$(git show "$commit":"$version/$base/Dockerfile" | awk '$1 == "ENV" && $2 == "NGINX_VERSION" { print $3; exit }')"

	versionAliases=( $fullVersion )
	if [ "$version" != "$fullVersion" ]; then
		versionAliases+=( $version )
	fi
	versionAliases+=( ${aliases[$version]:-} )

    for tag in ${versionAliases[@]:1}; do
        taglist["$image:$tag"]="$image:$fullVersion"
    done

	for variant in debian-perl; do
		variantAliases=( "${versionAliases[@]/%/-perl}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

        for tag in ${variantAliases[@]}; do
	    if [ "$tag" != "${fullVersion}-perl" ]; then
            taglist["$image:$tag"]="$image:$fullVersion-perl"
        fi
        done
	done

	for variant in alpine alpine-perl alpine-slim; do
		commit="$(dirCommit "$version/$variant")"

		variantAliases=( "${versionAliases[@]/%/-$variant}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

        for tag in ${variantAliases[@]}; do
	        if [ "$tag" != "${fullVersion}-$variant" ]; then
                taglist["$image:$tag"]="$image:${fullVersion}-$variant"
            fi
        done
	done

done

echo "#!/bin/sh"
echo "set -ex"
echo
echo "export DOCKER_CLI_EXPERIMENTAL=enabled"
echo
echo "# pulling stuff"
for arch in ${architectures[@]}; do
for tag in ${pulllist[@]}; do
    echo "docker pull $arch/$tag";
done
done

echo

echo "# tagging stuff"

for arch in ${architectures[@]}; do
for tag in ${pulllist[@]}; do
    echo "docker tag $arch/$tag $registry/$tag-$arch"
done
for tag in ${!taglist[@]}; do
    echo "docker tag $arch/${taglist[$tag]} $registry/$tag-$arch"
done
done

echo "# pushing stuff"

for arch in ${architectures[@]}; do
for tag in ${pulllist[@]}; do
    echo "docker push $registry/$tag-$arch"
done
for tag in ${!taglist[@]}; do
    echo "docker push $registry/$tag-$arch"
done
done

echo
echo "# manifesting stuff"
for tag in ${pulllist[@]} ${!taglist[@]}; do
    string="docker manifest create --amend $registry/$tag"
    for arch in ${architectures[@]}; do
        string+=" $registry/$tag-$arch"
    done
    echo $string
done

echo
echo "# pushing manifests"
for tag in ${pulllist[@]} ${!taglist[@]}; do
    echo "docker manifest push --purge $registry/$tag"
done
