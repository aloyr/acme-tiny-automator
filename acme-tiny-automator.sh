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
if [ $# -lt 1 ] || [ $1 == '-h' ]; then
    usage
fi

# general settings
ACME_TINY_URL='https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py'
LETSENCRYPT_ACCOUNT="$LETSENCRYPT_ROOT/account.key"
LETSENCRYPT_CERT="$LETSENCRYPT_CERTS/$1.crt"
LETSENCRYPT_CERT_DOMAIN="$1"
LETSENCRYPT_CERT_KEY="$LETSENCRYPT_CERTS/$1.key"
LETSENCRYPT_CERT_REQUEST="$LETSENCRYPT_CERTS/$1.csr"
LETSENCRYPT_CERT_SAN="[SAN]\nsubjectAltName="
LETSENCRYPT_CERT_SUBJECT="/CN=$LETSENCRYPT_CERT_DOMAIN"
LETSENCRYPT_CERTS="$LETSENCRYPT_ROOT/certs"
LETSENCRYPT_CHALLENGE_FOLDER="$WEB_ROOT/$1/.well-known/acme-challenge/"
LETSENCRYPT_HAS_SAN=0
LETSENCRYPT_INTERMEDIATE_URL='https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem'
LETSENCRYPT_INTERMEDIATE_CERT="$LETSENCRYPT_ROOT/intermediate.pem"

# prepare SAN if necessary
if [ $# -gt 1 ]; then
    LETSENCRYPT_HAS_SAN=1
    # check existence of openssl.cnf file, exit if it is missing
    if [ ! -f "$OPENSSL_CNF" ]; then
        >&2 echo "Missing openssl.cnf file"
        >&2 echo "With SAN, it is impossible to continue without it"
        exit 1
    fi
    echo "processing SAN"
    # parse all additional names
    for ((i=2; i<=$#; i++)) {
        LETSENCRYPT_CERT_SAN="${LETSENCRYPT_CERT_SAN}DNS:${!i},"
    }
    # remove trailing comma
    LETSENCRYPT_CERT_SUBJECT="${LETSENCRYPT_CERT_SAN%?}"
fi

# check for common tools
ACME_TINY="$ACME_TINY_LOCAL_FOLDER/acme-tiny.py"
CAT=$(check_component cat)
GIT=$(check_component git)
MKDIR=$(check_component mkdir)
OPENSSL=$(check_component openssl)
PRINTF=$(check_component printf)
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
if [ $LETSENCRYPT_HAS_SAN -eq 0 ]; then
    $OPENSSL req -new -sha256 -key "$LETSENCRYPT_CERT_KEY" \
        -subj "$LETSENCRYPT_CERT_SUBJECT"
        -out "$LETSENCRYPT_CERT_REQUEST"
else
    $OPENSSL req -new -sha256 -key "$LETSENCRYPT_CERT_KEY" \
        -subj "$LETSENCRYPT_CERT_SUBJECT" \
        -reqexts SAN
        -config <($CAT $OPENSSL_CNF <($PRINTF "$LETSENCRYPT_CERT_SAN")) \
        -out "$LETSENCRYPT_CERT_REQUEST"
fi

# create challenge folder in the webroot
if [ ! -d "$LETSENCRYPT_CHALLENGE_FOLDER" ]; then
    echo "creating challenge folder"
    $MKDIR -p "$LETSENCRYPT_CHALLENGE_FOLDER"
fi

# get signed certificate with acme-tiny
echo "getting signed certificate"
$PYTHON $ACME_TINY --account-key "$LETSENCRYPT_ACCOUNT" \
    --csr "$LETSENCRYPT_CERT_REQUEST" \
    --acme-dir "$LETSENCRYPT_CHALLENGE_FOLDER" \
    > "$LETSENCRYPT_CERT"

# output certificate expiration date
echo "certificate for $LETSENCRYPT_CERT_DOMAIN has the following relevant dates:"
$OPENSSL x509 -noout -dates -in "$LETSENCRYPT_CERT"
