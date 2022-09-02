# TLS (SSL) PKI for DevOps

This repository helps manage TLS Certificates (PKI) with the OpenSSL toolkit in DEV/TEST environments to mimic external (PROD) X.509 PKI.

The repository is based on the excellent work of the "OpenSSL PKI Tutorial" team.

https://pki-tutorial.readthedocs.io/en/latest/index.html

# How to Use

## Create New PKI

- Clone repository

```
git clone https://github.com/kborovik/pki-db.git
```

- Set private key passwords

```
mkdir -p ~/.secrets/pki
```

```
echo "VeryBigPassword" > ~/.secrets/pki/PKI_ROOT_PASSWD
```

```
echo "SimplyBigPassword" > ~/.secrets/pki/PKI_SIGNING_PASSWD
```

```
echo "EasySmallPassword" > ~/.secrets/pki/PKI_SERVER_PASSWD
```

- Update `[ ca_dn ]` information

```
vim etc/root-ca.conf
vim etc/signing-ca.conf
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
make new
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
export PKI_CN=new.host.com
export PKI_SAN=DNS:new.host.com,IP:127.0.0.1
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
# - PKI_SAN = DNS:new.host.com,IP:127.0.0.1
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
