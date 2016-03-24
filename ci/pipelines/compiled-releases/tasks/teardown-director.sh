#!/usr/bin/env bash

export HOME=$PWD/director-state

cd director-state

bosh-init delete bosh-init.yml
