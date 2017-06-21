#!/bin/bash
set -ev

molecule --version
ansible --version

ls -la .

make roles
molecule syntax
molecule test

if [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then
  make packer
  make anaconda
fi
