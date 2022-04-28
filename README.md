# About

This repository helps to implement TLS PKIs with the OpenSSL toolkit.

The repository is abased on the excellent work of "OpenSSL PKI Tutorial" team.

https://pki-tutorial.readthedocs.io/en/latest/index.html

# How to Use

## Create New PKI

- Checkout repository
- Run `rm -rf .git`
- Run `make clean`
- Update DN information in `etc/root-ca.conf`, `etc/signing-ca.conf`, `etc/server.conf`
- Set:
  - `export TLS_CN=vault.lab5.ca` (CommonName)
  - `export TLS_SAN=DNS:vault.lab5.ca,IP:10.0.0.2` (subjectAltName)
  - `export PKI_ROOT_PASSWD=BigPassword`
  - `export PKI_SIGNING_PASSWD=SmallPassword`
  - `export PKI_SERVER_PASSWD=TinyPassword`
- Run `make all`
- Run `git init && git add --all && git commit -m 'initial commit'`

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
