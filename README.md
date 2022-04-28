# About

The repository is abased on the excellent work of "OpenSSL PKI Tutorial" team. (https://pki-tutorial.readthedocs.io/en/latest/index.html)

# How to Use

- Checkout the repository
- Update `etc/root-ca.conf`, `etc/signing-ca.conf` `etc/server.conf`
- Export:
  - `TLS_CN` - TLS CommonName
  - `TLS_SAN` - TLS subjectAltName
- Run `make all`

# Example

```
> export TLS_CN=www.lab5.ca
> export DNS:vault.lab5.ca,IP:10.0.0.2
>
> make
> make all
```
