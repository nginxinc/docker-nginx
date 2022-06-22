#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

declare branches=(
    "stable"
    "mainline"
)

# Current nginx versions
# Remember to update pkgosschecksum when changing this.
declare -A nginx=(
    [mainline]='1.23.0'
    [stable]='1.22.0'
)

# Current njs versions
declare -A njs=(
    [mainline]='0.7.5'
    [stable]='0.7.5'
)

# Current package patchlevel version
# Remember to update pkgosschecksum when changing this.
declare -A pkg=(
    [mainline]=1
    [stable]=1
)

declare -A debian=(
    [mainline]='bullseye'
    [stable]='bullseye'
)

declare -A alpine=(
    [mainline]='3.16'
    [stable]='3.16'
)

# When we bump njs version in a stable release we don't move the tag in the
# mercurial repo.  This setting allows us to specify a revision to check out
# when building alpine packages on architectures not supported by nginx.org
# Remember to update pkgosschecksum when changing this.
declare -A rev=(
    [mainline]='${NGINX_VERSION}-${PKG_RELEASE}'
    [stable]='714'
)

# Holds SHA512 checksum for the pkg-oss tarball produced by source code
# revision/tag in the previous block
# Used in alpine builds for architectures not packaged by nginx.org
declare -A pkgosschecksum=(
    [mainline]='678b1e9ab34777f1a1a1a8717aff0dfa08cc187cf2cf140c084d23205f3ba3af97805e72ebbed49dd7bfcb23bbeca982b150fff5c2a6c96f161ed9085101f1a4'
    [stable]='f457d5988c1f2663e04c5cdad71874c25e94754277dd9da5d73c1d37c32bdaf288b3b20d8b5d070ffb33aab363eaf4a7abbcf95fcfd72b0729a1c1908c37e30e'
)

get_packages() {
    local distro="$1"
    shift
    local branch="$1"
    shift
    local perl=
    local r=
    local sep=

    case "$distro:$branch" in
    alpine*:*)
        r="r"
        sep="."
        ;;
    debian*:*)
        sep="+"
        ;;
    esac

    case "$distro" in
    *-perl)
        perl="nginx-module-perl"
        ;;
    esac

    echo -n ' \\\n'
    for p in nginx nginx-module-xslt nginx-module-geoip nginx-module-image-filter $perl; do
        echo -n '        '"$p"'=${NGINX_VERSION}-'"$r"'${PKG_RELEASE} \\\n'
    done
    for p in nginx-module-njs; do
        echo -n '        '"$p"'=${NGINX_VERSION}'"$sep"'${NJS_VERSION}-'"$r"'${PKG_RELEASE} \\'
    done
}

get_packagerepo() {
    local distro="${1%-perl}"
    shift
    local branch="$1"
    shift

    [ "$branch" = "mainline" ] && branch="$branch/" || branch=""

    echo "https://nginx.org/packages/${branch}${distro}/"
}

get_packagever() {
    local distro="${1%-perl}"
    shift
    local branch="$1"
    shift
    local suffix=

    [ "${distro}" = "debian" ] && suffix="~${debianver}"

    echo ${pkg[$branch]}${suffix}
}

generated_warning() {
    cat <<__EOF__
#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#
__EOF__
}

for branch in "${branches[@]}"; do
    for variant in \
        alpine{,-perl} \
        debian{,-perl}; do
        echo "$branch: $variant"
        dir="$branch/$variant"
        variant="$(basename "$variant")"

        [ -d "$dir" ] || continue

        template="Dockerfile-${variant%-perl}.template"
        {
            generated_warning
            cat "$template"
        } >"$dir/Dockerfile"

        debianver="${debian[$branch]}"
        alpinever="${alpine[$branch]}"
        nginxver="${nginx[$branch]}"
        njsver="${njs[${branch}]}"
        revver="${rev[${branch}]}"
        pkgosschecksumver="${pkgosschecksum[${branch}]}"

        packagerepo=$(get_packagerepo "$variant" "$branch")
        packages=$(get_packages "$variant" "$branch")
        packagever=$(get_packagever "$variant" "$branch")

        sed -i.bak \
            -e 's,%%ALPINE_VERSION%%,'"$alpinever"',' \
            -e 's,%%DEBIAN_VERSION%%,'"$debianver"',' \
            -e 's,%%NGINX_VERSION%%,'"$nginxver"',' \
            -e 's,%%NJS_VERSION%%,'"$njsver"',' \
            -e 's,%%PKG_RELEASE%%,'"$packagever"',' \
            -e 's,%%PACKAGES%%,'"$packages"',' \
            -e 's,%%PACKAGEREPO%%,'"$packagerepo"',' \
            -e 's,%%REVISION%%,'"$revver"',' \
            -e 's,%%PKGOSSCHECKSUM%%,'"$pkgosschecksumver"',' \
            "$dir/Dockerfile"

        cp -a entrypoint/*.sh "$dir/"

    done
done
