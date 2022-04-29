.ONESHELL:
.SILENT:
.EXPORT_ALL_VARIABLES:

TLS_CN ?=
TLS_SAN ?=

PKI_ROOT_PASSWD ?= $(shell pass pki/lab5/root-ca-key-passwd)
PKI_SIGNING_PASSWD ?= $(shell pass pki/lab5/signing-ca-key-passwd)
PKI_SERVER_PASSWD ?= $(shell pass pki/lab5/server-key-passwd)

# Valid algorithm names for private key generation are RSA, RSA-PSS, EC, X25519, X448, ED25519 and ED448
pkey_algorithm ?= ED25519

settings:
	echo "######################################################################"
	echo "#"
	echo "# Settings:"
	echo "# - TLS_CN  = $(TLS_CN)"
	echo "# - TLS_SAN = $(TLS_SAN)"
	echo "#"
	echo "######################################################################"

###############################################################################
# General PKI
###############################################################################
all: pki-root-crt pki-signing-crt pki-server-crt

clean: pki-clean pki-db

pki-db: pki-root-db pki-signing-db

pki-clean:
	-rm -rf ca crl certs

dirs := ca/root-ca/private ca/root-ca/db ca/signing-ca/private ca/signing-ca/db crl certs

$(dirs):
	mkdir -p $@

###############################################################################
# Root PKI
###############################################################################
root_db := ca/root-ca/db/root-ca.db ca/root-ca/db/root-ca.db.attr
root_crl := ca/root-ca/db/root-ca.crt.srl ca/root-ca/db/root-ca.crl.srl
root_key := ca/root-ca/private/root-ca.key
root_csr := ca/root-ca.csr
root_crt := ca/root-ca.crt

$(root_db): $(dirs)
	cp /dev/null $@

$(root_crl): $(dirs)
	echo 01 > $@

$(root_key):
	openssl genpkey -algorithm $(pkey_algorithm) -aes-128-cbc -pass pass:$(PKI_ROOT_PASSWD) -out $@

$(root_csr): $(root_key)
	openssl req -new -config etc/root-ca.conf -key $(root_key) -passin pass:$(PKI_ROOT_PASSWD) -out $@

$(root_crt): $(root_csr)
	openssl ca -selfsign -config etc/root-ca.conf -in $(root_csr) -extensions root_ca_ext -passin pass:$(PKI_ROOT_PASSWD) -out $@

pki-root-db: $(root_db) $(root_crl)

pki-root-crt: $(root_crt)

pki-root-crt-info:
	openssl x509 -text -noout -in $(root_crt)

###############################################################################
# Signing PKI
###############################################################################
signing_db := ca/signing-ca/db/signing-ca.db ca/signing-ca/db/signing-ca.db.attr
signing_crl := ca/signing-ca/db/signing-ca.crt.srl ca/signing-ca/db/signing-ca.crl.srl
signing_key := ca/signing-ca/private/signing-ca.key
signing_csr := ca/signing-ca.csr
signing_crt := ca/signing-ca.crt

$(signing_db): $(dirs)
	cp /dev/null $@

$(signing_crl): $(dirs)
	echo 01 > $@

$(signing_key):
	openssl genpkey -algorithm $(pkey_algorithm) -aes-128-cbc -pass pass:$(PKI_SIGNING_PASSWD) -out $@

$(signing_csr): $(signing_key)
	openssl req -new -config etc/signing-ca.conf -key $(signing_key) -passin pass:$(PKI_SIGNING_PASSWD) -out $@

$(signing_crt): $(signing_csr)
	openssl ca -config etc/root-ca.conf -in $(signing_csr) -extensions signing_ca_ext -passin pass:$(PKI_ROOT_PASSWD) -out $@

pki-signing-db: $(signing_db) $(signing_crl)

pki-signing-crt: $(root_crt) $(signing_crt)

pki-signing-crt-info:
	openssl x509 -text -noout -in $(signing_crt)

###############################################################################
# Servers PKI
###############################################################################
server_key := certs/$(TLS_CN).key
server_csr := certs/$(TLS_CN).csr
server_crt := certs/$(TLS_CN).crt
server_p12 := certs/$(TLS_CN).p12
server_pem := certs/$(TLS_CN).pem
server_ca := certs/$(TLS_CN).ca

$(server_key):
	openssl genpkey -algorithm $(pkey_algorithm) -aes-128-cbc -pass pass:$(PKI_SERVER_PASSWD) -out $@

$(server_csr): $(server_key)
	openssl req -new -config etc/server.conf -key $(server_key) -passin pass:$(PKI_SERVER_PASSWD) -out $@

$(server_crt): $(server_csr)
	openssl ca -config etc/signing-ca.conf -in $(server_csr) -extensions server_ext -passin pass:$(PKI_SIGNING_PASSWD) -out $@

$(server_p12): $(server_key)
	openssl pkcs12 -inkey $(server_key) -in $(server_crt) -name $(TLS_CN) -export -nodes -passout pass:$(PKI_SERVER_PASSWD) -passin pass:$(PKI_SERVER_PASSWD) -out $@

$(server_pem): $(server_crt)
	cat $(server_key) $(server_crt) > $@

$(server_ca): $(root_crt) $(signing_crt)
	cat $(root_crt) $(signing_crt) > $@

pki-server-crt: $(signing_crt) $(server_crt) $(server_p12) $(server_pem) $(server_ca)

pki-server-csr-info:
	openssl req -text -noout -in $(server_csr)

pki-server-crt-info:
	openssl x509 -text -noout -in $(server_crt)

pki-server-p12-info:
	openssl pkcs12 -info -nodes -in $(server_p12) -passin 'pass:$(PKI_SERVER_PASSWD)'

###############################################################################
# Errors Check
###############################################################################
ifndef TLS_CN
$(error | Define TLS_CN: export TLS_CN=pki.lab5.ca |)
endif

ifndef TLS_SAN
$(error | Define TLS_CN: export TLS_SAN=DNS:pki.lab5.ca,DNS:pki-dev.lab5.ca,IP:10.0.0.1 |)
endif

ifndef PKI_ROOT_PASSWD
$(error | PKI_ROOT_PASSWD is not defined |)
endif

ifndef PKI_SIGNING_PASSWD
$(error | PKI_SIGNING_PASSWD is not defined |)
endif

ifndef PKI_SERVER_PASSWD
$(error | PKI_SERVER_PASSWD is not defined |)
endif

ifeq ($(shell which openssl),)
$(error Missing command 'openssl'. https://www.openssl.org/)
endif
