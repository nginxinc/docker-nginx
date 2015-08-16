#!/bin/bash

# set -u fails the script if there are any undefiend environment variables

set -e -u

pull() {
  local server=$1
  echo "Pulling repository on $server"
  ssh core@$server "docker pull quay.io/ssro/$CIRCLE_PROJECT_REPONAME:development"
}

env=$1

if [[ $env == 'production' ]]; then
  FILTER="DEPLOY_CORE_PROD"
  MASTER=$DEPLOY_CORE_PROD1
 elif [[ $env == 'staging' ]]; then
  FILTER="DEPLOY_CORE_STAGING"
  MASTER=$DEPLOY_CORE_STAGING1
fi

# Need to pull on all servers
for i in $(env|grep $FILTER|cut -d "=" -f 2)
do
  pull "$i" &
done
wait

# Then connect to one controller is enough
ssh core@$MASTER  "fleetctl stop nginx \
	 && fleetctl start nginx"
