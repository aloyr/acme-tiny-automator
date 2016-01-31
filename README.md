# acme-tiny-automator
automates deployment of letsencrypt certs using acme-tiny library

This relies on the acme-tiny library, does not need to be run as root, 
does not install anything on the server, other than the acme-tiny.py file.

## motivation
This script exists to help me automate implement SSL through my Continuous Integration server.
I work in several projects that will benefit from this. One specifically has several feature branches
that we can instantiate as an environment for code and content QA. This project has 9 languages differenciated
at the domain level, which makes wildcard certs less convenient to use.

Having this whole environment on SSL automatically will help my process and perhaps will help someone else
that happens to stumble upon this. :)

## installation
To install, you will need to clone the repository and customize the configuration file.
At a minimum, that will involve the following:
```bash
git clone https://github.com/aloyr/acme-tiny-automator.git
cd acme-tiny-automator
cp config-examples.sh config.sh
chmod +x acme-tiny-automator
```
Soon I will create a setup script that will handle even that.

## execution
Program execution is simple:
```bash
./acme-tiny-automator <domain-name>
```
This will get you setup with LetsEncrypt, in case you aren't already setup, issue the 
proper certificate request, and place it in the folder specified in the configuration file.

## post-execution
Just configure your Apache or nginx stanza with the certificates.
Your SSL file statements in Apache will look something like this:
```
SSLCertificateFile <path-to-letsencrypt-certs/domain>.crt
SSLCertificateKeyFile <path-to-letsencrypt-certs/domain>.key
SSLCertificateChainFile <path-to-letsencrypt-certs>/intermediate.pem
```
