#!/usr/bin/env bash

cp -r director-state/* .

export HOME=$PWD

bosh-init delete bosh-init.yml
