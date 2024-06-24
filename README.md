# The Lost Art of the Makefile

This repository uses OpenSSL and GNU Makefile to automate and simplify Certificate Signing Request (CSR) processes.

## Problem

Creating replicas of TLS certificates for testing and development can be time-consuming and complex. This includes generating CA authority certificates, Signing Authority certificates, and certificates with complex Subject Alternative Names (SANs) for mTLS.

Corporate CSR processes can take anywhere from hours to weeks to complete. Having pre-tested Certificate Signing Requests (CSRs) ready can significantly streamline this process.

**Example of a Complex Subject Alternative Name for mTLS Certificate**

```
X509v3 extensions:
    X509v3 Key Usage: critical
        Digital Signature, Key Encipherment
    X509v3 Basic Constraints: 
        CA:FALSE
    X509v3 Extended Key Usage: 
        TLS Web Server Authentication, TLS Web Client Authentication, Code Signing, E-mail Protection
    X509v3 Subject Key Identifier: 
        F0:76:3B:B0:03:20:C5:15:2F:7A:4E:F1:F6:FE:AE:06:31:FE:88:B9
    X509v3 Authority Key Identifier: 
        E1:7D:A3:BE:51:DF:F9:1E:29:80:C8:57:CC:D9:D6:3E:37:5D:5F:55
    X509v3 Subject Alternative Name: 
        DNS:vault.dev1.gcp.lab5.ca, DNS:vault.prd1.gcp.lab5.ca, DNS:vault-0, DNS:vault-1, DNS:vault-2, DNS:vault, DNS:vault.vault, DNS:vault.vault.svc, DNS:vault.vault.svc.cluster, DNS:vault.vault.svc.cluster.local, DNS:vault-0.cluster, DNS:vault-1.cluster, DNS:vault-2.cluster, IP Address:127.0.0.1
```

## Solution

This repository allows you to test your Subject Alternative Names (SANs) and deployment process using a test certificate before submitting a CSR to the corporate PKI.

### Efficient Certificate Generation with GNU Make

GNU Make offers a powerful feature that optimizes the certificate generation process. By leveraging timestamp comparisons, it allows us to skip the generation of certificates when the source files haven't changed. This capability enables us to create an efficient dependency chain, streamlining the entire PKI management workflow.

```
root_crt ==> signing_crt ==> host_crt
```

## Demo

### Creating Certificate Authority Certificates

<video src="https://github.com/kborovik/pki-db/assets/59314971/6904829f-b4f4-4543-b4cc-fc05984a4c6f"></video>

### Creating Host Certificate Bundle

<video src="https://github.com/kborovik/pki-db/assets/59314971/36f1e035-86a0-4279-b0ed-1cbaf3cbc8be"></video>

### Requirements

- OpenSSL version 3.0.0 or higher (https://www.openssl.org/)
- GNU Make 4.0.0 or higher (https://www.gnu.org/software/make/)
- GNU PG 2.0.0 or higher (https://gnupg.org/)

### Project Structure

The project is organized as follows:

- **Core Logic**: The main functionality is implemented in the `Makefile`.
- **OpenSSL**: The repository follows the standard OpenSSL directory structure.

### Key Components

- `makefile` contains the core logic and automation scripts.
- `ca` directory stores Certificate Authority related files.
- `etc` directory stores OpenSSL configuration files.
- `certs` directory stores generated certificates.

### Generated Certificate Package

The repository generates a comprehensive certificate package containing:

- Root CA certificate chain (Root+Signing) `ca-certificates.crt`
- Host CSR `host.domain.com.csr`
- Host certificate `host.domain.com.crt`
- Host encrypted private key `host.domain.com.key`
- Host P12 (PFX) bundle `host.domain.com.p12`

## Usage Guide

### Setting Up a New PKI

**Clone the repository**

```shell
git clone https://github.com/kborovik/pki-db.git
```

**Initialize new PKI DB (removes old PKI DB and all TLS certificates)**

```shell
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

### Configuring GPG Keys

GPG keys are used to encrypt passwords for TLS certificate private keys. Each TLS private key receives a unique password, allowing for the generation of random private key passwords that can be easily shared with team members.

**Update Makefile with GPG key**

```shell
sed -i 's/^GPG_KEY .\*/GPG_KEY ?= 1A4A6FC0BB90A4B5F2A11031E577D405DD6ABEA5/' makefile
```

**Verify GPG key**

```shell
make
==> Certificate <==
COMMON_NAME:
SUBJECT_ALT_NAME:
==> Encryption Key <==
GPG_KEY: 1A4A6FC0BB90A4B5F2A11031E577D405DD6ABEA5
==> Software <==
OpenSSL: OpenSSL 3.0.13 30 Jan 2024 (Library: OpenSSL 3.0.13 30 Jan 2024)
Make: GNU Make 4.3
GPG: gpg (GnuPG) 2.4.4
Create Certificates? (yes/no): 
```

### Updating Certificate Authority Distinguished Name

```shell
etc/
├── root.conf
├── signing.conf
└── server.conf
```

**Example configuration**

```shell
vim etc/root.config
vim etc/signing.config
vim etc/server.config
```

**Update `ca_dn`**

```
[ ca_dn ]
0.domainComponent = ca
1.domainComponent = lab5
organizationName = Lab5 DevOps Inc.
organizationalUnitName = www.lab5.ca
commonName = $organizationName Root CA
```

### Creating Certificates

To generate a new certificate, follow these steps:

- Set the required `COMMON_NAME` environment variable.
- Optionally, set the `SUBJECT_ALT_NAME` environment variable for additional identities.
- Run `make` command

```shell
export COMMON_NAME="www.lab5.ca"
export SUBJECT_ALT_NAME="DNS:www.lab5.ca,IP:127.0.0.1"
make
==> Certificate <==
COMMON_NAME: www.lab5.ca
SUBJECT_ALT_NAME: DNS:www.lab5.ca,IP:127.0.0.1
==> Encryption Key <==
GPG_KEY: 1A4A6FC0BB90A4B5F2A11031E577D405DD6ABEA5
==> Software <==
OpenSSL: OpenSSL 3.0.13 30 Jan 2024 (Library: OpenSSL 3.0.13 30 Jan 2024)
Make: GNU Make 4.3
GPG: gpg (GnuPG) 2.4.4
Create Certificates? (yes/no): 
```

### Managing Certificates

**View certificates**

```shell
tree certs/
certs/
├── ca-certificates.crt
├── db.lab5.ca.asc
├── db.lab5.ca.crt
├── db.lab5.ca.csr
├── db.lab5.ca.key
├── db.lab5.ca.p12
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

## Acknowledgements

This repository is based on the excellent work of the "OpenSSL PKI Tutorial".

For more information, visit: https://pki-tutorial.readthedocs.io/en/latest/index.html
