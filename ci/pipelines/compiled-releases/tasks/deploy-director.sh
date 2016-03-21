#!/usr/bin/env bash

TASKS_DIR="$PWD/bosh-src/ci/pipelines/compiled-releases/tasks"
$TASKS_DIR/generate-bosh-init-manifest.sh

bosh-init deploy $TASKS_DIR/bosh-init.yml
