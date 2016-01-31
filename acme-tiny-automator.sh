#!/usr/bin/env bash

# import custom settings
# start with:
# cp config-example.sh config.sh
# and adjust accordingly
. ./config.sh

function usage() {
  >&2 echo "Usage: $0 <domain-name-to-create>"
  exit 1
}

function check_component() {
    RESULT=$(which $1)
    if [ $? -gt 0 ]; then
        >&2 echo "Missing $1"
        >&2 echo "Without it, this script won't work correctly"
        >&2 echo "Please fix this error and try again"
        exit 1
    else
        echo $RESULT
    fi
}

# check parameters
if [ $# -ne 1 ] || [ $1 == '-h' ]; then
    usage
fi

# general settings
ACME_TINY_URL='https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py'
LETSENCRYPT_INTERMEDIATE_URL='https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem'

# check for common tools
ACME_TINY="$ACME_TINY_LOCAL_FOLDER/acme-tiny.py"
GIT=$(check_component git)
PYTHON=$(check_component python)
WGET=$(check_component wget)

# download acme-tiny, if it doesnt exist
if [ ! -d "$ACME_TINY_LOCAL_FOLDER" ]; then
    mkdir -p $ACME_TINY_LOCAL_FOLDER
    $WGET $ACME_TINY_URL -O $ACME_TINY
fi


