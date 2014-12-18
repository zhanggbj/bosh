#!/bin/bash

set -e
set -x

if [ "$1" == "" ]; then
  echo "At least one argument required. ex: run-in-container.sh /path/to/cmd arg1 arg2"
  exit 1
fi

# Pushing to Docker Hub requires login
DOCKER_IMAGE=${DOCKER_IMAGE:-bosh/integration}

# To push to the Pivotal GoCD Docker Registry (behind firewall):
# DOCKER_IMAGE=docker.gocd.cf-app.com:5000/bosh-container

echo "Running '$@' in docker container '$DOCKER_IMAGE'..."
docker run \
  -a stderr \
  -v $(pwd):/opt/bosh \
  -e RUBY_VERSION \
  -e DB \
  -e CODECLIMATE_REPO_TOKEN \
  -e COVERAGE \
  -e HTTP_PROXY=$HTTP_PROXY \
  -e HTTPS_PROXY=$HTTPS_PROXY \
  -e NO_PROXY=$NO_PROXY \
  $DOCKER_IMAGE \
  $@ \
  &

SUBPROC="$!"

trap "
  echo '--------------------- KILLING PROCESS'
  kill $SUBPROC

  echo '--------------------- KILLING CONTAINERS'
  docker ps -q | xargs docker kill
" SIGTERM SIGINT # gocd sends TERM; INT just nicer for testing with Ctrl+C

wait $SUBPROC
