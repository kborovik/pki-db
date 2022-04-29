# About

This repository helps manage TLS Certificates (PKI) with the OpenSSL toolkit in DEV/TEST environments to mimic external (PROD) X.509 PKI.

The repository is based on the excellent work of the "OpenSSL PKI Tutorial" team.

https://pki-tutorial.readthedocs.io/en/latest/index.html

# How to Use

By default, all private keys are encrypted with a password. To decrypt run:

```
→ openssl pkey -in certs/vault.lab5.ca.key -passin pass:TinyPassword
```

## Create New PKI

- Checkout this repository
- Run `rm -rf .git` (optional)
- Run `make clean` to remove RootCA and certificates
- Update `[ ca_dn ]` information in `etc/root-ca.conf`, `etc/signing-ca.conf`, `etc/server.conf`.
- Set:
  - `export TLS_CN=vault.lab5.ca` (CommonName)
  - `export TLS_SAN=DNS:vault.lab5.ca,IP:10.0.0.2` (subjectAltName)
  - `export PKI_ROOT_PASSWD=BigPassword`
  - `export PKI_SIGNING_PASSWD=SmallPassword`
  - `export PKI_SERVER_PASSWD=TinyPassword`
- Run `make all`
- Run `git init && git add --all && git commit -m 'initial commit'` (optional)

# Example

## Create New Certificate

```
→ export TLS_CN=vault.lab5.ca
→ export TLS_SAN=DNS:vault.lab5.ca,IP:10.0.0.2
→
→ make
######################################################################
#
# Settings:
# - TLS_CN  = vault.lab5.ca
# - TLS_SAN = DNS:vault.lab5.ca,IP:10.0.0.2
#
######################################################################
→
→ make all
→
→ tree certs/
certs/
├── vault.lab5.ca.ca
├── vault.lab5.ca.crt
├── vault.lab5.ca.csr
├── vault.lab5.ca.key
├── vault.lab5.ca.p12
└── vault.lab5.ca.pem

0 directories, 6 files
```
