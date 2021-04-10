#!/bin/sh

set -e

ME=$(basename $0)

auto_templates() {
  local template_dir="${NGINX_TEMPLATE_DIR:-/etc/nginx/config}"
  local suffix="${NGINX_TEMPLATE_SUFFIX:-.template}"
  local output_dir="${NGINX_OUTPUT_DIR:-/etc/nginx/conf.d}"

  local template sedfile relative_path output_path subdir
  [ -d "$template_dir" ] || return 0
  if [ ! -w "$output_dir" ]; then
    echo >&3 "$ME: ERROR: $template_dir exists, but $output_dir is not writable"
    return 0
  fi
  sedfile=$(mktemp --tmpdir)
  printenv | sed -e "s#[\"'\/\#\\&]#\\\\\0#g" -e "s/=/\\\^#/" -e "s/^\(.*\)$/s#\\\^\1#g/" > "$sedfile"
  find "$template_dir" -follow -type f -name "*$suffix" -print | while read -r template; do
    relative_path="${template#$template_dir/}"
    output_path="$output_dir/${relative_path%$suffix}"
    subdir=$(dirname "$relative_path")
    # create a subdirectory where the template file exists
    mkdir -p "$output_dir/$subdir"
	 cp "$template" "$output_path"
    echo >&3 "$ME: Running sed on $template to $output_path"
	 sed -f "$sedfile" -i "$output_path"
  done
  rm "$sedfile"
}

auto_templates

exit 0
