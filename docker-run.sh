#!/bin/bash

stub=$1; shift
set -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ATC_URL=${ATC_URL:-"http://10.244.8.2:8080"}
export fly_target=${fly_target:-target-bosh-lite}
echo "Concourse API target: ${fly_target}"
echo "Concourse API: $ATC_URL"
echo "Name: $(basename $DIR)"

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

usage() {
  echo "USAGE: run.sh path/to/credentials.yml"
  exit 1
}


if [ -z "${stub}" ]; then
  stub="../credentials.yml"
fi
stub=$(realpath $stub)
if [ ! -f ${stub} ]; then
  usage
fi


pushd $DIR
  fly sp -t ${fly_target} configure -c docker-pipeline.yml -p pipeline-docker --load-vars-from ${stub} -n
  fly -t ${fly_target} unpause-pipeline --pipeline pipeline-docker
  fly -t ${fly_target} trigger-job -j pipeline-docker/job-create-docker-image
  fly -t ${fly_target} watch -j pipeline-docker/job-create-docker-image
popd
