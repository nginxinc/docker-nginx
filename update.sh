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
    [mainline]='1.27.0'
    [stable]='1.26.1'
)

# Current njs versions
declare -A njs=(
    [mainline]='0.8.4'
    [stable]='0.8.4'
)

# Current njs patchlevel version
# Remember to update pkgosschecksum when changing this.
declare -A njspkg=(
    [mainline]='2'
    [stable]='2'
)

# Current otel versions
declare -A otel=(
    [mainline]='0.1.0'
    [stable]='0.1.0'
)

# Current package patchlevel version
# Remember to update pkgosschecksum when changing this.
declare -A pkg=(
    [mainline]=2
    [stable]=2
)

declare -A debian=(
    [mainline]='bookworm'
    [stable]='bookworm'
)

declare -A alpine=(
    [mainline]='3.19'
    [stable]='3.19'
)

# When we bump njs version in a stable release we don't move the tag in the
# mercurial repo.  This setting allows us to specify a revision to check out
# when building alpine packages on architectures not supported by nginx.org
# Remember to update pkgosschecksum when changing this.
declare -A rev=(
    [mainline]='${NGINX_VERSION}-${PKG_RELEASE}'
    [stable]='${NGINX_VERSION}-${PKG_RELEASE}'
)

# Holds SHA512 checksum for the pkg-oss tarball produced by source code
# revision/tag in the previous block
# Used in alpine builds for architectures not packaged by nginx.org
declare -A pkgosschecksum=(
    [mainline]='cd3333f4dfa4a873f6df73dfe24e047adc092d779aefb46577b6307ff0d0125543508694a80158b2bfc891167ad763b0d08287829df9924d4c22f50d063e76c0'
    [stable]='0db2bf5f86e7c31f23d0e3e7699a5d8a4d9d9b0dc2f98d3e3a31e004df20206270debf6502e4481892e8b64d55fba73fcc8d74c3e0ddfcd2d3f85a17fa02a25e'
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
        for p in nginx nginx-module-xslt nginx-module-geoip nginx-module-image-filter $perl; do
            echo -n '        '"$p"'=${NGINX_VERSION}-'"$r"'${PKG_RELEASE} \\\n'
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

    [ "${package}" = "njs" ] && echo ${njspkg[$branch]}${suffix} || echo ${pkg[$branch]}${suffix}
}

get_buildtarget() {
    local distro="$1"
    shift
    case "$distro" in
        alpine-slim)
            echo base
            ;;
        alpine-perl)
            echo module-perl
            ;;
        alpine-otel)
            echo module-otel
            ;;
        alpine)
            echo module-geoip module-image-filter module-njs module-xslt
            ;;
        debian)
            echo "\$nginxPackages"
            ;;
        debian-perl)
            echo "nginx-module-perl=\${NGINX_VERSION}-\${PKG_RELEASE}"
            ;;
        debian-otel)
            echo "nginx-module-otel"
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
        buildtarget=$(get_buildtarget "$variant")

        sed -i.bak \
            -e 's,%%ALPINE_VERSION%%,'"$alpinever"',' \
            -e 's,%%DEBIAN_VERSION%%,'"$debianver"',' \
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
