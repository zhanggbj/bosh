#!/bin/sh

echo $BOSH_SSH_TUNNEL_KEY > ssh_tunnel_key

cat $PWD/bosh-src/ci/pipelines/compiled-releases/tasks/bosh-init-template.yml | sed s%{{access_key_id}}%$BOSH_INIT_ACCESS_KEY%g | sed s%{{secret_key_id}}%$BOSH_INIT_SECRET_KEY%g > bosh-init.yml
