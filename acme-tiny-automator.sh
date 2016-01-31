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
LETSENCRYPT_INTERMEDIATE_CERT="$LETSENCRYPT_ROOT/intermediate.pem"
LETSENCRYPT_ACCOUNT="$LETSENCRYPT_ROOT/account.key"
LETSENCRYPT_CERTS="$LETSENCRYPT_ROOT/certs"

# check for common tools
ACME_TINY="$ACME_TINY_LOCAL_FOLDER/acme-tiny.py"
GIT=$(check_component git)
MKDIR=$(check_component mkdir)
OPENSSL=$(check_component openssl)
PYTHON=$(check_component python)
WGET=$(check_component wget)

# download acme-tiny, if it doesnt exist
if [ ! -d "$
ACME_TINY_LOCAL_FOLDER" ]; then
    $MKDIR -p "$ACME_TINY_LOCAL_FOLDER"
    $WGET $ACME_TINY_URL -O $ACME_TINY
fi

# create certificate folder & intermediate, if it doesn't exit
if [ ! -f "$LETSENCRYPT_INTERMEDIATE_CERT" ]; then
    if [ ! -d "$LETSENCRYPT_ROOT" ]; then
        $MKDIR -p "$LETSENCRYPT_ROOT"
    fi
    $WGET "$LETSENCRYPT_INTERMEDIATE_URL" -O $LETSENCRYPT_INTERMEDIATE_CERT
fi

# create account.key, if it doesn't exist
if [ ! -f "$LETSENCRYPT_ACCOUNT" ]; then
    $OPENSSL genrsa 4096 > "$LETSENCRYPT_ACCOUNT"
fi

# create certs folder, if it doesn't exist
if [ ! -d "$LETSENCRYPT_CERTS" ]; then
    $MKDIR -p "$LETSENCRYPT_CERTS"
fi
