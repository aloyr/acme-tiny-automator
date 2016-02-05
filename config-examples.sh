#!/usr/bin/env bash

# this file has example settings that should work as default values for most installations
# you should copy this file into config.sh and then adjust config.sh to fit your environment
ACME_TINY_LOCAL_FOLDER='/opt/acme-tiny'
LETSENCRYPT_ROOT='/etc/httpd/ssl/letsencrypt'
OPENSSL_CNF='/etc/pki/tls/openssl.cnf'
RENEW_DAYS_BEFORE_EXPIRATION=7
WEB_ROOT='/var/www'