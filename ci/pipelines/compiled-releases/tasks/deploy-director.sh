#!/usr/bin/env bash

$PWD/bosh-src/ci/pipelines/compiled-releases/tasks/generate-bosh-init-manifest.sh > bosh-init.yml

echo $BOSH_SSH_TUNNEL_KEY > ssh_tunnel_key

bosh-init deploy bosh-init.yml
