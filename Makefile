.ONESHELL:
.SILENT:
.EXPORT_ALL_VARIABLES:

PKI_CN ?=
PKI_SAN ?=

PKI_ROOT_PASSWD ?= $(shell pass pki/lab5/root-ca-key-passwd)
PKI_SIGNING_PASSWD ?= $(shell pass pki/lab5/signing-ca-key-passwd)
PKI_SERVER_PASSWD ?= $(shell pass pki/lab5/server-key-passwd)

# Valid algorithm names for private key generation are RSA, RSA-PSS, ED25519, ED448
pkey_algorithm ?= RSA-PSS

pki-settings:
	echo "######################################################################"
	echo "#"
	echo "# Settings:"
	echo "# - PKI_CN  = $(PKI_CN)"
	echo "# - PKI_SAN = $(PKI_SAN)"
	echo "#"
	echo "######################################################################"

###############################################################################
# General PKI
###############################################################################
all: pki-root-crt pki-signing-crt pki-server-crt

pki-new: pki-prompt pki-clean pki-root-db pki-signing-db

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

$(signing_crt): $(root_crt) $(signing_csr)
	openssl ca -config etc/root-ca.conf -in $(signing_csr) -extensions signing_ca_ext -passin pass:$(PKI_ROOT_PASSWD) -out $@

pki-signing-db: $(signing_db) $(signing_crl)

pki-signing-crt: $(root_crt) $(signing_crt)

###############################################################################
# Servers PKI
###############################################################################
root_ca    := certs/certificate-authority.crt
server_key := certs/$(PKI_CN).key
server_csr := certs/$(PKI_CN).csr
server_crt := certs/$(PKI_CN).crt
server_p12 := certs/$(PKI_CN).p12
server_pem := certs/$(PKI_CN).pem

$(root_ca): $(root_crt) $(signing_crt)
	cat $(root_crt) $(signing_crt) > $@

$(server_key):
	openssl genpkey -algorithm $(pkey_algorithm) -aes-128-cbc -pass pass:$(PKI_SERVER_PASSWD) -out $@

$(server_csr): $(server_key)
	openssl req -new -config etc/server.conf -key $(server_key) -passin pass:$(PKI_SERVER_PASSWD) -out $@

$(server_crt): $(signing_crt) $(server_csr)
	openssl ca -config etc/signing-ca.conf -in $(server_csr) -extensions server_ext -passin pass:$(PKI_SIGNING_PASSWD) -out $@

$(server_p12): $(server_key) $(server_crt) $(root_ca)
	openssl pkcs12 -export -inkey $(server_key) -in $(server_crt) -chain -CAfile $(root_ca) -name $(PKI_CN) -nodes -passout pass:$(PKI_SERVER_PASSWD) -passin pass:$(PKI_SERVER_PASSWD) -out $@

pki-server-crt: $(server_crt) $(server_p12) $(root_ca)

pki-show-key:
	openssl pkey -in $(server_key) -passin pass:$(PKI_SERVER_PASSWD)

pki-show-csr:
	openssl req -text -noout -in $(server_csr)

pki-show-crt:
	openssl x509 -text -noout -in $(server_crt)

pki-show-p12:
	openssl pkcs12 -nodes -info -in $(server_p12) -passin 'pass:$(PKI_SERVER_PASSWD)'

###############################################################################
# Errors Check
###############################################################################
ifndef PKI_CN
$(error | Define PKI_CN: export PKI_CN=pki.lab5.ca |)
endif

ifndef PKI_SAN
$(error | Define PKI_CN: export PKI_SAN=DNS:pki.lab5.ca,DNS:pki-dev.lab5.ca,IP:10.0.0.1 |)
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

pki-prompt:
	echo "######################################################################"
	echo "# WARRNING! - All TLS private keys will be destroyed!"
	echo "######################################################################"
	echo
	read -p "Continue destruction? (yes/no): " INP
	if [ "$${INP}" != "yes" ]; then 
	  echo "Deployment aborted"
	  exit 100
	fi