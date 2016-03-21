#!/usr/bin/env bash

$PWD/bosh-src/ci/pipelines/compiled-releases/tasks/generate-bosh-init-manifest.sh > bosh-init.yml

echo "$BOSH_SSH_TUNNEL_KEY" > ssh_tunnel_key
chmod 600 ssh_tunnel_key

BOSH_INIT_LOG_LEVEL=debug bosh-init deploy bosh-init.yml
