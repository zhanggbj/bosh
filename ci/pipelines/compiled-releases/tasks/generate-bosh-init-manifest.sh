#!/bin/sh

cat $PWD/bosh-src/ci/pipelines/compiled-releases/tasks/bosh-init-template.yml | sed s%{{access_key_id}}%$BOSH_INIT_ACCESS_KEY%g | sed s%{{secret_key_id}}%$BOSH_INIT_SECRET_KEY%g
