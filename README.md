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

[![asciicast](https://asciinema.org/a/649686.svg)](https://asciinema.org/a/649686)

# Requirements

The procedure was developed and tested with `OpenSSL >= 3.0.0`

# How to Use

## Create New PKI

**Clone repository**

```
git clone https://github.com/kborovik/pki-db.git
```

**Initialize new PKI DB**

Remove old PKI DB and all TLS certificates

```
make clean
```

**Remove old Git repository**

```shell
rm -rf .git
```

**Create new Git repository**

```shell
git init
git add --all
git commit -m 'initial pki db'
```

**Set GPG keys**

GPG key encrypts passwords for TLS certificate private keys. Each TLS private keys gets a unique password. This allows generate random private key passwords and share them easily with other team members.

**Set shell environment**

```shell
export GPG_KEY=1A4A6FC0BB90A4B5F2A11031E577D405DD6ABEA5
```

**Update Makefile**

```shell
(0) > grep -e '^GPG_KEY' makefile
GPG_KEY ?= 1A4A6FC0BB90A4B5F2A11031E577D405DD6ABEA5

```

**View settings**

```shell
(0) > make
==> Certificate <==
COMMON_NAME: 
SUBJECT_ALT_NAME: 
==> Encryption Key <==
GPG_KEY: 1A4A6FC0BB90A4B5F2A11031E577D405DD6ABEA5
==> Software <==
OpenSSL: OpenSSL 3.0.2 15 Mar 2022 (Library: OpenSSL 3.0.2 15 Mar 2022)
GPG: gpg (GnuPG) 2.2.27
```

**Update Certificate Authority Distinguished Name**

Add organization Certificate Authority Distinguished Name in files:

```shell
etc/
├── root.conf
├── server.conf
└── signing.conf
```

Example:

```ini
[ ca_dn ]
0.domainComponent = ca
1.domainComponent = lab5
organizationName = Lab5 DevOps Inc.
organizationalUnitName = www.lab5.ca
commonName = $organizationName Root CA
```

## Create Certificate

**Create certificate**

Example:

```bash
(0) > make COMMON_NAME="www.lab5.ca" SUBJECT_ALT_NAME="DNS:www.lab5.ca,IP:127.0.0.1,email:user@email.com"

==> Certificate <==
COMMON_NAME: www.lab5.ca
SUBJECT_ALT_NAME: DNS:www.lab5.ca,IP:127.0.0.1,email:user@email.com
==> Encryption Key <==
GPG_KEY: 1A4A6FC0BB90A4B5F2A11031E577D405DD6ABEA5
==> Software <==
OpenSSL: OpenSSL 3.0.2 15 Mar 2022 (Library: OpenSSL 3.0.2 15 Mar 2022)
GPG: gpg (GnuPG) 2.2.27
Create Certificates? (yes/no): yes

```
**View certificates**

```shell
(0) > tree certs/
certs/
├── ca-certificates.crt
├── www.lab5.ca.asc
├── www.lab5.ca.crt
├── www.lab5.ca.csr
├── www.lab5.ca.key
└── www.lab5.ca.p12
```

**Show Private Key Password**

```shell
make show-pass
```

**Decrypt Private Key**

```shell
make show-key
```

**View CSR**

```shell
make show-csr
```

**View CRT**

```shell
make show-crt
```

**View P12**

```shell
make show-p12
```

# Thank you

The repository is based on the excellent work of the "OpenSSL PKI Tutorial".

https://pki-tutorial.readthedocs.io/en/latest/index.html
