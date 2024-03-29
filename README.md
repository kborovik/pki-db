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

- **Clone repository**

```
git clone https://github.com/kborovik/pki-db.git
```

- **Initialize new PKI DB**

`make clean` removes old PKI DB and all TLS certificates.

```
make clean

######################################################################
# WARNING! - All TLS private keys will be destroyed!
######################################################################

Continue destruction? (yes/no): yes
```

- **Remove old Git repository**

```shell
rm -rf .git
```

- **Create new Git repository**

```shell
git init
git add --all
git commit -m 'new pki-db host.com'
```

- **Set GPG keys**

GPG key encrypts passwords for TLS certificate private keys. Each TLS private keys gets a unique password. This allows generate random private key passwords and share them easily with other team members.

Example:

```shell
GPG_KEY := 1A4A6FC0BB90A4B5F2A11031E577D405DD6ABEA5
```

```shell
vim makefile
```

- **Update `[ ca_dn ]` information**

Add organization Certificate Authority Distinguished Name.

Example:

```ini
[ ca_dn ]
0.domainComponent = ca
1.domainComponent = lab5
organizationName = Lab5 DevOps Inc.
organizationalUnitName = www.lab5.ca
commonName = $organizationName Root CA
```

```
vim etc/root.conf
vim etc/signing.conf
vim etc/server.conf
```

- **Create certificate template**

Add Common Name (PKI_CN) and Subject Alternative Name (PKI_SAN).

Example:

```bash
#!/usr/bin/env bash
export PKI_CN="www.lab5.ca"
export PKI_SAN="DNS:www.lab5.ca,IP:127.0.0.1,email:user@email.com"
```

**WARNING!**: `hosts/new.domain.com` must have the same name as `PKI_CN`. Example: `hosts/new.domain.com` == `PKI_CN=new.domain.com`

If file name is not the same as `PKI_CN` the following error message will be printed:

```shell
make: *** No rule to make target 'hosts/www.lab5.ca', needed by 'certs/www.lab5.ca.csr'.  Stop.
```

- **Export environment variables**

```shell
source hosts/my.host.com
```

- **Create new certificate**

```shell
make
```

## Show Private Key Password

```shell
make show-pass
```

## Decrypt Private Key

```shell
make show-key
```

## View CSR, CRT, P12

```shell
make show-csr
```

```shell
make show-crt
```

```shell
make show-p12
```

# Thank you

The repository is based on the excellent work of the "OpenSSL PKI Tutorial".

https://pki-tutorial.readthedocs.io/en/latest/index.html
