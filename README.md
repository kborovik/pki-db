# About

The repository is abased on the excellent work of "OpenSSL PKI Tutorial" team. (https://pki-tutorial.readthedocs.io/en/latest/index.html)

# How to Use

- Checkout the repository
- Update `etc/root-ca.conf`, `etc/signing-ca.conf` `etc/server.conf`
- Export:
  - `TLS_CN` - TLS CommonName
  - `TLS_SAN` - TLS subjectAltName
- Run `make all`
- Get new certificate from `certs/`

# Example

```
> export TLS_CN=www.lab5.ca
> export TLS_SAN=DNS:vault.lab5.ca,IP:10.0.0.2
>
> make
######################################################################
#
# Settings:
# - TLS_CN  = vault.lab5.ca
# - TLS_SAN = DNS:vault.lab5.ca,IP:10.0.0.2
#
######################################################################
>
> make all
>
> tree certs/
certs/
├── vault.lab5.ca.ca
├── vault.lab5.ca.crt
├── vault.lab5.ca.csr
├── vault.lab5.ca.key
└── vault.lab5.ca.pem
```
