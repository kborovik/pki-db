# The Lost Art of the Makefile

This repository uses OpenSSL and GNU Makefile to automate and simplify Certificate Signing Request (CSR) processes.

## Problem

The Corporate CSR process can take anywhere from hours to weeks to complete.

## Solution

Test your Subject Alternative Names (SAN) and deployment process using a test certificate before submitting a CSR to the corporate PKI.

This repo generates certificate package:

- Root CA certificate `ca-certificates.crt`
- Test Host certificate `host.domain.com.crt`
- Test Host CSR `host.domain.com.csr`
- Test Host encrypted private key `host.domain.com.key`
- Test Host P12 (PFX) bundle `host.domain.com.p12`

# Demo

[![asciicast](https://asciinema.org/a/644660.svg)](https://asciinema.org/a/644660)

# Requirements

The procedure was developed and tested with `OpenSSL 3.0.2 15 Mar 2022 (Library: OpenSSL 3.0.2 15 Mar 2022)`

# How to Use

## Create New PKI

- Clone repository

```
git clone https://github.com/kborovik/pki-db.git
```

- Set GPG key (gpg_key := 51DB9DC8)

```
vim Makefile
```

- Update `[ ca_dn ]` information

```
vim etc/root.conf
vim etc/signing.conf
vim etc/server.conf
```

- Create certificate template (`CommonName` and `subjectAltName`)

```
cp hosts/www.lab5.ca hosts/new.host.com
```

```
vim hosts/new.host.com
```

```
source hosts/new.host.com
```

- Initialize new PKI DB

```
make clean
```

```
######################################################################
# WARNING! - All TLS private keys will be destroyed!
######################################################################

Continue destruction? (yes/no): yes
```

- Create new certificate

```
make
```

```
######################################################################
#
# Settings:
# - PKI_CN  = new.host.com
# - PKI_SAN = DNS:new.host.com,IP:127.0.0.1
#
######################################################################

Create certificate? (yes/no):
```

- Remove old Git repository

```
rm -rf .git
```

- Create new Git repository

```
git init
git add --all
git commit -m 'new pki-db host.com'
```

## Create New Certificate

- Create server certificate template

```
vim hosts/new.host.com
```

```
cat hosts/new.host.com
```

```
export PKI_CN="new.host.com"
export PKI_SAN="DNS:new.host.com, IP:127.0.0.1"
```

```
source hosts/new.host.com
```

- Create certificate

```
make
```

```
######################################################################
#
# Settings:
# - PKI_CN  = new.host.com
# - PKI_SAN = DNS:new.host.com, IP:127.0.0.1
#
######################################################################

Create certificate? (yes/no):
```

```
tree certs/
```

```
certs/
├── ca-certificates.crt
├── new.host.com.crt
├── new.host.com.csr
├── new.host.com.key
└── new.host.com.p12

0 directories, 5 files
```

## Decrypt Private Key

```
make show-key
```

## View CSR, CRT, P12

```
make show-csr
```

```
make show-crt
```

```
make show-p12
```

# Private Key Algorithm

The TLS certificate private key algorithm can be changed from the default `RSA` to `RSA-PSS`, `ED25519`, `ED448` by setting

```
export pkey_algorithm=ED25519
```

or updating `pkey_algorithm` in Makefile

Note: `ED25519` and `ED448` requires OpenSSL 1.1.1 and higher

# Thank you

The repository is based on the excellent work of the "OpenSSL PKI Tutorial".

https://pki-tutorial.readthedocs.io/en/latest/index.html
