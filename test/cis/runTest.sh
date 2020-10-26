#!/bin/bash
#
# Run some tests
#

# globals --------
ASSESSOR_PATH="${ASSESSOR_PATH:-$HOME/.local/Assessor-CLI}"
export GEN3_HOME

# lib ------------------------

help() {
      cat - <<EOM
bash runTest.sh nginx-docker-image
NOTE:
    - point GEN3_HOME at cloud-automation/
    - install CIS Assessor-CLI/ under $ASSESSOR_PATH
      or change the ASSESSOR_PATH environment variable
      see https://workbench.cisecurity.org/
EOM
}

setup() {
  local configFolder="$(mktemp -d "$XDG_RUNTIME_DIR/nginxText_XXXXXX")"
  local revproxy="$GEN3_HOME/kube/services/revproxy"
  gen3_log_info "copying nginx config from $revproxy to $configFolder" 1>&2
  cp "$revproxy/nginx.conf" "$configFolder/" 1>&2
  cp "$revproxy/helpers.js" "$configFolder/" 1>&2
  cp -r "$revproxy/gen3.nginx.conf" "$configFolder/gen3.conf" 1>&2
  rm "$configFolder/gen3.conf/jupyterhub-service.conf" "$configFolder/gen3.conf/fenceshib-service.conf" 1>&2
  cp -r "$GEN3_HOME/gen3/lib/manifestDefaults/modsec" "$configFolder/modsec" 1>&2
  # below is from cloud-automation/.../revproxy-deploy.yaml
  for name in ngx_http_perl_module.so ngx_http_js_module.so ngx_http_headers_more_filter_module.so ngx_http_modsecurity_module.so; do
    echo "load_module modules/$name;" >> "$configFolder/gen3_modules.conf"
  done
  echo "modsecurity on;" >> "$configFolder/gen3_server_modsec.conf"
  echo "modsecurity_rules_file /etc/nginx/modsec/main.conf;" >> "$configFolder/gen3_server_modsec.conf"

  echo "$configFolder"
  return 0
}


# main ----------------------

if [[ $# -lt 1 || "$1" =~ ^-*h(elp)? ]]; then
    help
    exit 0
fi
image="$1"
shift

if [[ -z "$GEN3_HOME" || ! -d "$GEN3_HOME" ]]; then
  echo "ERROR: set GEN3_HOME environment variable, and point at cloud-automation/ install"
  help
  exit 1
fi

if [[ ! -f "${ASSESSOR_PATH}/Assessor-CLI.sh" ]]; then
  echo "ERROR: ${ASSESSOR_PATH}/Assessor-CLI.sh does not exist - set ASSESSOR_PATH environment"
  help
  exit 1
fi

source "$GEN3_HOME/gen3/gen3setup.sh"
nginxFolder="$(setup)"

echo docker run -it --rm --name nginx-cis-test -v "${nginxFolder}:/etc/gen3-nginx" -v "${ASSESSOR_PATH}:/mnt/Assessor-CLI" "$image" /bin/bash
echo '(apt update && apt install rsync -y) > /dev/null 2>&1'
echo rsync -av /etc/gen3-nginx/ /etc/nginx/
echo nginx -t
echo nginx
echo '(apt install openjdk-11-jre -y) > /dev/null 2>&1'
echo cd /mnt/Assessor-CLI
echo bash ./Assessor-CLI.sh -h
echo bash ./Assessor-CLI.sh -b benchmarks/CIS_NGINX_Benchmark_v1.1.0-oval.xml
echo bash ./Assessor-CLI.sh -b benchmarks/CIS_NGINX_Benchmark_v1.1.0-xccdf.xml
