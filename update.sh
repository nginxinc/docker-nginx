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
    [mainline]='1.27.3'
    [stable]='1.26.2'
)

# Current njs versions
declare -A njs=(
    [mainline]='0.8.7'
    [stable]='0.8.5'
)

# Current njs patchlevel version
# Remember to update pkgosschecksum when changing this.
declare -A njspkg=(
    [mainline]='1'
    [stable]='1'
)

# Current otel versions
declare -A otel=(
    [mainline]='0.1.0'
    [stable]='0.1.0'
)

# Current nginx package patchlevel version
# Remember to update pkgosschecksum when changing this.
declare -A pkg=(
    [mainline]=1
    [stable]=1
)

# Current built-in dynamic modules package patchlevel version
# Remember to update pkgosschecksum when changing this
declare -A dynpkg=(
    [mainline]=1
    [stable]=2
)

declare -A debian=(
    [mainline]='bookworm'
    [stable]='bookworm'
)

declare -A alpine=(
    [mainline]='3.21'
    [stable]='3.21'
)

# When we bump njs version in a stable release we don't move the tag in the
# pkg-oss repo.  This setting allows us to specify a revision to check out
# when building packages on architectures not supported by nginx.org
# Remember to update pkgosschecksum when changing this.
declare -A rev=(
    [mainline]='${NGINX_VERSION}-${PKG_RELEASE}'
    [stable]='${NGINX_VERSION}-${PKG_RELEASE}'
)

# Holds SHA512 checksum for the pkg-oss tarball produced by source code
# revision/tag in the previous block
# Used in builds for architectures not packaged by nginx.org
declare -A pkgosschecksum=(
    [mainline]='5617feecfb441cd972b9ac51a2fd78384a3d2bde2f399163be0746d44ec8f7d8c47234af4f6b0012667c3d0446cced521f55f8f71254415e3766c2e3802bf960'
    [stable]='b5d8ad59567a5df18f134236c4e22a339229cd56f4b2ae8d1b77a17f3dcfb16672103bd9191d419acf93c90e866b59417aad26ad7710d9dcc53bf38d1f88d764'
)

get_packages() {
    local distro="$1"
    shift
    local branch="$1"
    shift
    local bn=""
    local otel=
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
    *-otel)
        otel="nginx-module-otel"
        bn="\n"
        ;;
    esac

    echo -n ' \\\n'
    case "$distro" in
    *-slim)
        for p in nginx; do
            echo -n '        '"$p"'=${NGINX_VERSION}-'"$r"'${PKG_RELEASE} \\'
        done
        ;;
    *)
        for p in nginx; do
            echo -n '        '"$p"'=${NGINX_VERSION}-'"$r"'${PKG_RELEASE} \\\n'
        done
        for p in nginx-module-xslt nginx-module-geoip nginx-module-image-filter $perl; do
            echo -n '        '"$p"'=${NGINX_VERSION}-'"$r"'${DYNPKG_RELEASE} \\\n'
        done
        for p in nginx-module-njs; do
            echo -n '        '"$p"'=${NGINX_VERSION}'"$sep"'${NJS_VERSION}-'"$r"'${NJS_RELEASE} \\'"$bn"
        done
        for p in $otel; do
            echo -n '        '"$p"'=${NGINX_VERSION}'"$sep"'${OTEL_VERSION}-'"$r"'${PKG_RELEASE} \\'
        done
        ;;
    esac
}

get_packagerepo() {
    local distro="$1"
    shift
    distro="${distro%-perl}"
    distro="${distro%-otel}"
    distro="${distro%-slim}"
    local branch="$1"
    shift

    [ "$branch" = "mainline" ] && branch="$branch/" || branch=""

    echo "https://nginx.org/packages/${branch}${distro}/"
}

get_packagever() {
    local distro="$1"
    shift
    distro="${distro%-perl}"
    distro="${distro%-otel}"
    distro="${distro%-slim}"
    local branch="$1"
    shift
    local package="$1"
    shift
    local suffix=

    [ "${distro}" = "debian" ] && suffix="~${debianver}"

    case "${package}" in
        "njs")
            echo ${njspkg[$branch]}${suffix}
            ;;
        "dyn")
            echo ${dynpkg[$branch]}${suffix}
            ;;
        *)
            echo ${pkg[$branch]}${suffix}
            ;;
    esac
}

get_buildtarget() {
    local distro="$1"
    shift
    case "$distro" in
        alpine-slim)
            echo base
            ;;
        alpine)
            echo module-geoip module-image-filter module-njs module-xslt
            ;;
        debian)
            echo base module-geoip module-image-filter module-njs module-xslt
            ;;
        *-perl)
            echo module-perl
            ;;
        *-otel)
            echo module-otel
            ;;
    esac
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
        alpine{,-perl,-otel,-slim} \
        debian{,-perl,-otel}; do
        echo "$branch: $variant dockerfiles"
        dir="$branch/$variant"
        variant="$(basename "$variant")"

        [ -d "$dir" ] || continue

        template="Dockerfile-${variant}.template"
        {
            generated_warning
            cat "$template"
        } >"$dir/Dockerfile"

        debianver="${debian[$branch]}"
        alpinever="${alpine[$branch]}"
        nginxver="${nginx[$branch]}"
        njsver="${njs[${branch}]}"
        otelver="${otel[${branch}]}"
        revver="${rev[${branch}]}"
        pkgosschecksumver="${pkgosschecksum[${branch}]}"

        packagerepo=$(get_packagerepo "$variant" "$branch")
        packages=$(get_packages "$variant" "$branch")
        packagever=$(get_packagever "$variant" "$branch" "any")
        njspkgver=$(get_packagever "$variant" "$branch" "njs")
        dynpkgver=$(get_packagever "$variant" "$branch" "dyn")
        buildtarget=$(get_buildtarget "$variant")

        sed -i.bak \
            -e 's,%%ALPINE_VERSION%%,'"$alpinever"',' \
            -e 's,%%DEBIAN_VERSION%%,'"$debianver"',' \
            -e 's,%%DYNPKG_RELEASE%%,'"$dynpkgver"',' \
            -e 's,%%NGINX_VERSION%%,'"$nginxver"',' \
            -e 's,%%NJS_VERSION%%,'"$njsver"',' \
            -e 's,%%NJS_RELEASE%%,'"$njspkgver"',' \
            -e 's,%%OTEL_VERSION%%,'"$otelver"',' \
            -e 's,%%PKG_RELEASE%%,'"$packagever"',' \
            -e 's,%%PACKAGES%%,'"$packages"',' \
            -e 's,%%PACKAGEREPO%%,'"$packagerepo"',' \
            -e 's,%%REVISION%%,'"$revver"',' \
            -e 's,%%PKGOSSCHECKSUM%%,'"$pkgosschecksumver"',' \
            -e 's,%%BUILDTARGET%%,'"$buildtarget"',' \
            "$dir/Dockerfile"

    done

    for variant in \
        alpine-slim \
        debian; do \
        echo "$branch: $variant entrypoint scripts"
        dir="$branch/$variant"
        cp -a entrypoint/*.sh "$dir/"
        cp -a entrypoint/*.envsh "$dir/"
    done
done
