#!/usr/bin/env bash

# import custom settings
# start with:
# cp config-example.sh config.sh
# and adjust accordingly
. ./config.sh

# general settings
ACME_TINY_URL='https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py'
LETSENCRYPT_INTERMEDIATE_URL='https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem'

# check for common tools
GIT=$(which git)
PYTHON=$(which python)

# check for python libraries

