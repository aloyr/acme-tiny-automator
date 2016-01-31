#!/usr/bin/env bash

function usage() {
  >&2 echo "Usage: $0 <domain-name-to-create>"
  exit 1
}

if [ ! -f config.sh ]; then
    >&2 echo "Config file missing, exiting..."
    >&2 echo "Copy config-examples.sh to config.sh and adjust accordingly"
    exit 1
fi

# import custom settings
# start with:
# cp config-example.sh config.sh
# and adjust accordingly
. ./config.sh

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
LETSENCRYPT_CERT_DOMAIN="$1"
LETSENCRYPT_CERT_KEY="$LETSENCRYPT_CERTS/$1.key"
LETSENCRYPT_CERT_REQUEST="$LETSENCRYPT_CERTS/$1.csr"
LETSENCRYPT_CERT="$LETSENCRYPT_CERTS/$1.crt"
LETSENCRYPT_CHALLENGE_FOLDER="$APACHE_ROOT/$1/.well-known/acme-challenge/"

# check for common tools
ACME_TINY="$ACME_TINY_LOCAL_FOLDER/acme-tiny.py"
GIT=$(check_component git)
MKDIR=$(check_component mkdir)
OPENSSL=$(check_component openssl)
PYTHON=$(check_component python)
WGET=$(check_component wget)

# download acme-tiny, if it doesnt exist
if [ ! -d "$ACME_TINY_LOCAL_FOLDER" ]; then
    echo "downloading acme-tiny"
    $MKDIR -p "$ACME_TINY_LOCAL_FOLDER"
    $WGET $ACME_TINY_URL -O $ACME_TINY
fi

# create certificate folder & intermediate, if it doesn't exit
if [ ! -f "$LETSENCRYPT_INTERMEDIATE_CERT" ]; then
    if [ ! -d "$LETSENCRYPT_ROOT" ]; then
        echo "creating letsencrypt folder"
        $MKDIR -p "$LETSENCRYPT_ROOT"
    fi
    echo "downloading intermediate certificate"
    $WGET "$LETSENCRYPT_INTERMEDIATE_URL" -O $LETSENCRYPT_INTERMEDIATE_CERT
fi

# create private account.key, if it doesn't exist
if [ ! -f "$LETSENCRYPT_ACCOUNT" ]; then
    echo "generating letsencrypt account private key file (this should only happen once)"
    $OPENSSL genrsa 4096 > "$LETSENCRYPT_ACCOUNT"
fi

# create certs folder, if it doesn't exist
if [ ! -d "$LETSENCRYPT_CERTS" ]; then
    echo "creating certificates folder"
    $MKDIR -p "$LETSENCRYPT_CERTS"
fi

# create domain private key, if it doesn't exist
if [ ! -f "$LETSENCRYPT_CERT_KEY" ]; then
    echo "creating domain private file (this should only happen once)"
    $OPENSSL genrsa 4096 > "$LETSENCRYPT_CERT_KEY"
fi

# create certificate request
echo "generating certificate request"
$OPENSSL req -new -sha256 -key "$LETSENCRYPT_CERT_KEY" -subj "/CN=$LETSENCRYPT_CERT_DOMAIN" > "$LETSENCRYPT_CERT_REQUEST"

# create challenge folder in the webroot
if [ ! -d "$LETSENCRYPT_CHALLENGE_FOLDER" ]; then
    echo "creating challenge folder"
    $MKDIR -p "$LETSENCRYPT_CHALLENGE_FOLDER"
fi

# get signed certificate with acme-tiny
echo "getting signed certificate"
$PYTHON $ACME_TINY --account-key "$LETSENCRYPT_ACCOUNT" --csr "$LETSENCRYPT_CERT_REQUEST" --acme-dir "$LETSENCRYPT_CHALLENGE_FOLDER" > "$LETSENCRYPT_CERT"

# output certificate expiration date
echo "certificate for $LETSENCRYPT_CERT_DOMAIN has the following relevant dates:"
$OPENSSL x509 -noout -dates -in "$LETSENCRYPT_CERT"
