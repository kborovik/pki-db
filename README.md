# About

This repository helps manage TLS Certificates (PKI) with the OpenSSL toolkit in DEV/TEST environments to mimic external (PROD) X.509 PKI.

The repository is based on the excellent work of the "OpenSSL PKI Tutorial" team.

https://pki-tutorial.readthedocs.io/en/latest/index.html

# How to Use

## Create New Certificate

**create server certificate template**

```
→ cat env/vault.lab5.ca
export PKI_CN=vault.lab5.ca
export PKI_SAN=DNS:vault.lab5.ca,IP:127.0.0.1
```

```
→ source env/vault.lab5.ca
```

**or export directly**

```
→ export PKI_CN=vault.lab5.ca
→ export PKI_SAN=DNS:vault.lab5.ca,IP:10.0.0.2
```

**check settings**

```
→ make
```

```
######################################################################
#
# Settings:
# - PKI_CN  = vault.lab5.ca
# - PKI_SAN = DNS:vault.lab5.ca,IP:127.0.0.1
#
######################################################################
```

**create certificate**

```
→ make all
```

```
→ tree certs/
certs/
├── ca-certificates.crt
├── vault.lab5.ca.crt
├── vault.lab5.ca.csr
├── vault.lab5.ca.key
└── vault.lab5.ca.p12

0 directories, 5 files
```

## Manage Private Key Passwords

By default, all private keys are encrypted with a password. I use UNIX `pass` (https://www.passwordstore.org/) to supply password automatically.

```
PKI_ROOT_PASSWD ?= $(shell pass pki/lab5/root-ca-key-passwd)
PKI_SIGNING_PASSWD ?= $(shell pass pki/lab5/signing-ca-key-passwd)
PKI_SERVER_PASSWD ?= $(shell pass pki/lab5/server-key-passwd)
```

**decrypt**

```
→ openssl pkey -in certs/vault.lab5.ca.key -passin pass:TinyPassword
```

**or with make**

```
→ make show-key
```

## Create New PKI

### Steps

- Clone this repository

```
→ git clone https://github.com/kborovik/pki-db.git
```

- Remove Git folder

```
→ rm -rf .git
```

- Set PKI passwords (or in Makefile)

```
→ export PKI_ROOT_PASSWD=BigPassword
→ export PKI_SIGNING_PASSWD=SmallPassword
→ export PKI_SERVER_PASSWD=TinyPassword
```

- Update `[ ca_dn ]` information

```
→ vim etc/root-ca.conf
→ vim etc/signing-ca.conf
→ vim etc/server.conf
```

- Create new PKI DB

```
→ make new
```

- Create first `CommonName` and `subjectAltName`

```
→ export PKI_CN=vault.lab5.ca
→ export PKI_SAN=DNS:vault.lab5.ca,IP:10.0.0.2
```

- Create certificate

```
→ make all
```

- Create new Git repository

```
→ git init
→ git add --all
→ git commit -m 'new pki-db lab5.ca'
```

### Private Key Algorithm

The TLS certificate private key algorithm can be changed from the default `RSA` to `RSA-PSS`, `ED25519`, `ED448` by setting `export pkey_algorithm := ED25519` or updating `pkey_algorithm` in Makefile. (`ED25519` and `ED448` requires OpenSSL 1.1.1 and higher)
