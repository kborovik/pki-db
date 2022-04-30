# About

This repository helps manage TLS Certificates (PKI) with the OpenSSL toolkit in DEV/TEST environments to mimic external (PROD) X.509 PKI.

The repository is based on the excellent work of the "OpenSSL PKI Tutorial" team.

https://pki-tutorial.readthedocs.io/en/latest/index.html

# How to Use

## Create New Certificate

Create server certificate template.

```
→ cat env/vault.lab5.ca
export PKI_CN=vault.lab5.ca
export PKI_SAN=DNS:vault.lab5.ca,IP:127.0.0.1
→
→ source env/vault.lab5.ca
```

or export directly

```
→ export PKI_CN=vault.lab5.ca
→ export PKI_SAN=DNS:vault.lab5.ca,IP:10.0.0.2
```

check settings

```
→ make
######################################################################
#
# Settings:
# - PKI_CN  = vault.lab5.ca
# - PKI_SAN = DNS:vault.lab5.ca,IP:127.0.0.1
#
######################################################################
```

make certificate

```
→ make all
→
→ tree certs/
certs/
├── rootCA.pem
├── vault.lab5.ca.crt
├── vault.lab5.ca.csr
├── vault.lab5.ca.key
├── vault.lab5.ca.p12
└── vault.lab5.ca.pem

0 directories, 6 files
```

## Manage Private Key Passwords

By default, all private keys are encrypted with a password. I use UNIX `pass` (https://www.passwordstore.org/) to supply password automatically.

```
PKI_ROOT_PASSWD ?= $(shell pass pki/lab5/root-ca-key-passwd)
PKI_SIGNING_PASSWD ?= $(shell pass pki/lab5/signing-ca-key-passwd)
PKI_SERVER_PASSWD ?= $(shell pass pki/lab5/server-key-passwd)
```

**Decrypt**

```
→ openssl pkey -in certs/vault.lab5.ca.key -passin pass:TinyPassword
```

or

```
→ make pki-server-key-info
```

## Create New PKI

- Checkout this repository
- Run `rm -rf .git` (optional)
- Run `make clean` to remove RootCA and certificates
- Update `[ ca_dn ]` information in `etc/root-ca.conf`, `etc/signing-ca.conf`, `etc/server.conf`.
- Set:
  - `export PKI_CN=vault.lab5.ca` (CommonName)
  - `export PKI_SAN=DNS:vault.lab5.ca,IP:10.0.0.2` (subjectAltName)
  - `export PKI_ROOT_PASSWD=BigPassword`
  - `export PKI_SIGNING_PASSWD=SmallPassword`
  - `export PKI_SERVER_PASSWD=TinyPassword`
- Run `make all`
- Run `git init && git add --all && git commit -m 'initial commit'` (optional)
