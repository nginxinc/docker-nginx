#!/bin/bash
#
# Run some tests
#

if [[ $# -lt 1 || "$1" =~ ^-*h(elp)? ]]; then
    cat - <<EOM
  bash runTest.sh nginx-docker-image
EOM
  exit 1
fi

image="$1"

docker run -d --rm --name nginx-test -v "$(pwd)/conf.d:/etc/nginx/conf.d" -v "$(pwd)/modsec:/etc/nginx/modsec" -v "$(pwd)/nginx.conf:/etc/nginx/nginx.conf" -v "$(pwd)/helpers.js:/etc/nginx/helpers.js" -p 9080:80 -p 9085:8085 "$image"
sleep 10
curl -D - http://localhost:9085/
curl -D - http://localhost:9080/
curl -D - http://localhost:9080/foo?testparam=thisisatestofmodsecurity

