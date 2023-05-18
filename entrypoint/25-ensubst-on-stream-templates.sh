#!/bin/sh

set -e

ME=$(basename $0)

entrypoint_log() {
    if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

add_stream_block() {
  if ! grep -q -E "\s*stream\s*\{" /etc/nginx/nginx.conf; then
    cat << END >> /etc/nginx/nginx.conf
stream {
  include /etc/nginx/stream_conf.d/*.conf;
}
END
    entrypoint_log "Appended stream block to /etc/nginx/nginx.conf to include /etc/nginx/stream_conf.d/*.conf"
  fi
}

auto_envsubst() {
  local template_dir="${NGINX_ENVSUBST_STREAM_TEMPLATE_DIR:-/etc/nginx/stream_templates}"
  local suffix="${NGINX_ENVSUBST_TEMPLATE_SUFFIX:-.template}"
  local output_dir="${NGINX_ENVSUBST_STREAM_OUTPUT_DIR:-/etc/nginx/stream_conf.d}"
  local filter="${NGINX_ENVSUBST_FILTER:-}"

  local template defined_envs relative_path output_path subdir
  defined_envs=$(printf '${%s} ' $(awk "END { for (name in ENVIRON) { print ( name ~ /${filter}/ ) ? name : \"\" } }" < /dev/null ))
  [ -d "$template_dir" ] || return 0
  mkdir -p "$output_dir"
  if [ ! -w "$output_dir" ]; then
    entrypoint_log "$ME: ERROR: $template_dir exists, but $output_dir is not writable"
    return 0
  fi

  # Add a block to include stream configurations in the core config
  add_stream_block

  find "$template_dir" -follow -type f -name "*$suffix" -print | while read -r template; do
    relative_path="${template#$template_dir/}"
    output_path="$output_dir/${relative_path%$suffix}"
    subdir=$(dirname "$relative_path")
    # create a subdirectory where the template file exists
    mkdir -p "$output_dir/$subdir"
    entrypoint_log "$ME: Running envsubst on $template to $output_path"
    envsubst "$defined_envs" < "$template" > "$output_path"
  done
}

auto_envsubst

exit 0