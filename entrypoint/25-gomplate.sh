#!/bin/sh

set -e

ME=$(basename $0)

entrypoint_log() {
    if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

add_stream_block() {
  local conffile="/etc/nginx/nginx.conf"

  if grep -q -E "\s*stream\s*\{" "$conffile"; then
    entrypoint_log "$ME: $conffile contains a stream block; include $stream_output_dir/*.conf to enable stream templates"
  else
    # check if the file can be modified, e.g. not on a r/o filesystem
    touch "$conffile" 2>/dev/null || { entrypoint_log "$ME: info: can not modify $conffile (read-only file system?)"; exit 0; }
    entrypoint_log "$ME: Appending stream block to $conffile to include $stream_output_dir/*.conf"
    cat << END >> "$conffile"
# added by "$ME" on "$(date)"
stream {
  include $stream_output_dir/*.conf;
}
END
  fi
}

auto_gomplate() {
  local template_dir="${NGINX_GOMPLATE_TEMPLATE_DIR:-/etc/nginx/templates}"
  local suffix="${NGINX_GOMPLATE_TEMPLATE_SUFFIX:-.template}"
  local output_dir="${NGINX_GOMPLATE_OUTPUT_DIR:-/etc/nginx/conf.d}"
  local stream_suffix="${NGINX_GOMPLATE_STREAM_TEMPLATE_SUFFIX:-.stream-template}"
  local stream_output_dir="${NGINX_GOMPLATE_STREAM_OUTPUT_DIR:-/etc/nginx/stream-conf.d}"

  [ -d "$template_dir" ] || return 0
  if [ ! -w "$output_dir" ]; then
    entrypoint_log "$ME: ERROR: $template_dir exists, but $output_dir is not writable"
    return 0
  fi
  [ command -v gomplate ] || return 0

  entrypoint_log "$ME: Running gomplate on $template_dir to $output_dir"
  gomplate --input-dir "$template_dir" --include "*$suffix" --output-map "$output_dir/{{ .in | strings.TrimSuffix \"$suffix\" }}"

  # Print the first file with the stream suffix, this will be false if there are none
  if test -n "$(find "$template_dir" -name "*$stream_suffix" -print -quit)"; then
    mkdir -p "$stream_output_dir"
    if [ ! -w "$stream_output_dir" ]; then
      entrypoint_log "$ME: ERROR: $template_dir exists, but $stream_output_dir is not writable"
      return 0
    fi
    add_stream_block
    entrypoint_log "$ME: Running gomplate on $template_dir to $stream_output_dir"
    gomplate --input-dir "$template_dir" --include "*$stream_suffix" --output-map "$stream_output_dir/{{ .in | strings.TrimSuffix \"$stream_suffix\" }}"
  fi
}

auto_gomplate

exit 0
