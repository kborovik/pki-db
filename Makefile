.ONESHELL:
.SILENT:
.EXPORT_ALL_VARIABLES:

SELL := /usr/bin/env bash

GPG_KEY ?= D9EC1DBD6CB9C69E187DA9EE7CC32F3151DB9DC8
PKI_CN ?=
PKI_SAN ?=

# Valid algorithm names for private key generation are RSA, RSA-PSS, ED25519, ED448
pkey_algorithm ?= ED25519

###############################################################################
# General PKI
###############################################################################
all: settings prompt-create root-crt signing-crt server-crt

new: clean secrets-encrypt root-db signing-db

clean: prompt-destroy
	-rm -rf ca crl certs .initialized etc/*.asc

settings: .initialized
	echo "GPG_KEY=$(GPG_KEY)"
	echo "PKI_CN=$(PKI_CN)"
	echo "PKI_SAN=$(PKI_SAN)"

dirs := ca/root-ca/private ca/root-ca/db ca/signing-ca/private ca/signing-ca/db certs

$(dirs):
	mkdir -p $@

.initialized:
	$(info ==> initializing PKI DB <==)
	test -f $(root_key) && touch $(root_key) && sleep 1
	test -f $(root_csr) && touch $(root_csr) && sleep 1
	test -f $(root_crt) && touch $(root_crt) && sleep 1
	test -f $(signing_key) && touch $(signing_key) && sleep 1
	test -f $(signing_csr) && touch $(signing_csr) && sleep 1
	test -f $(signing_crt) && touch $(signing_crt) && sleep 1
	test -f $(root_ca) && touch $(root_ca) && sleep 1
	test -f $(server_key) && touch $(server_key) && sleep 1
	test -f $(server_csr) && touch $(server_csr) && sleep 1
	test -f $(server_crt) && touch $(server_crt) && sleep 1
	test -f $(server_p12) && touch $(server_p12) && sleep 1
	touch $@

###############################################################################
# Root PKI
###############################################################################
root_db := ca/root-ca/db/root-ca.db ca/root-ca/db/root-ca.db.attr
root_crl := ca/root-ca/db/root-ca.crt.srl ca/root-ca/db/root-ca.crl.srl
root_key := ca/root-ca/private/root-ca.enc
root_csr := ca/root-ca.csr
root_crt := ca/root-ca.crt

$(root_db): $(dirs)
	cp /dev/null $@

$(root_crl): $(dirs)
	echo 01 > $@

$(root_key):
	openssl genpkey -algorithm $(pkey_algorithm) -aes-256-cbc -pass pass:$(PKI_ROOT_PASSWD) -out $@

$(root_csr): $(root_key)
	openssl req -new -config etc/root-ca.conf -key $(root_key) -passin pass:$(PKI_ROOT_PASSWD) -out $@

$(root_crt): $(root_csr)
	openssl ca -selfsign -config etc/root-ca.conf -in $(root_csr) -extensions root_ca_ext -passin pass:$(PKI_ROOT_PASSWD) -out $@

root-db: $(root_db) $(root_crl)

root-crt: $(root_crt)

###############################################################################
# Signing PKI
###############################################################################
signing_db := ca/signing-ca/db/signing-ca.db ca/signing-ca/db/signing-ca.db.attr
signing_crl := ca/signing-ca/db/signing-ca.crt.srl ca/signing-ca/db/signing-ca.crl.srl
signing_key := ca/signing-ca/private/signing-ca.enc
signing_csr := ca/signing-ca.csr
signing_crt := ca/signing-ca.crt

$(signing_db): $(dirs)
	cp /dev/null $@

$(signing_crl): $(dirs)
	echo 01 > $@

$(signing_key):
	openssl genpkey -algorithm $(pkey_algorithm) -aes-256-cbc -pass pass:$(PKI_SIGNING_PASSWD) -out $@

$(signing_csr): $(signing_key)
	openssl req -new -config etc/signing-ca.conf -key $(signing_key) -passin pass:$(PKI_SIGNING_PASSWD) -out $@

$(signing_crt): $(root_crt) $(signing_csr)
	openssl ca -config etc/root-ca.conf -in $(signing_csr) -extensions signing_ca_ext -passin pass:$(PKI_ROOT_PASSWD) -out $@

signing-db: $(signing_db) $(signing_crl)

signing-crt: $(root_crt) $(signing_crt)

###############################################################################
# CA certificates
###############################################################################
root_ca := certs/ca-certificates.crt

$(root_ca): $(root_crt) $(signing_crt)
	cat $(root_crt) $(signing_crt) > $@

###############################################################################
# Servers PKI
###############################################################################
server_key := certs/$(PKI_CN).enc
server_csr := certs/$(PKI_CN).csr
server_crt := certs/$(PKI_CN).crt
server_p12 := certs/$(PKI_CN).p12

$(server_key):
	openssl genpkey -algorithm $(pkey_algorithm) -aes-256-cbc -pass pass:$(PKI_SERVER_PASSWD) -out $@

$(server_csr): $(server_key)
	openssl req -new -config etc/server.conf -key $(server_key) -passin pass:$(PKI_SERVER_PASSWD) -out $@

$(server_crt): $(signing_crt) $(server_csr)
	openssl ca -config etc/signing-ca.conf -in $(server_csr) -extensions server_ext -passin pass:$(PKI_SIGNING_PASSWD) -out $@

$(server_p12): $(server_key) $(server_crt) $(root_ca)
	openssl pkcs12 -export -legacy -inkey $(server_key) -in $(server_crt) -chain -CAfile $(root_ca) -name $(PKI_CN) -passout pass:$(PKI_SERVER_PASSWD) -passin pass:$(PKI_SERVER_PASSWD) -out $@

server-crt: $(server_crt) $(server_p12) $(root_ca)

show-key:
	openssl pkey -in $(server_key) -passin pass:$(PKI_SERVER_PASSWD)

show-csr:
	openssl req -text -noout -in $(server_csr)

show-crt:
	openssl x509 -text -noout -in $(server_crt)

show-p12:
	openssl pkcs12 -noenc -legacy -info -in $(server_p12) -passin 'pass:$(PKI_SERVER_PASSWD)'

###############################################################################
# PGP Secrets
###############################################################################

pki_root_pass := etc/root-ca
pki_signing_pass := etc/signing-ca
pki_server_pass := etc/server

ifneq ($(wildcard $(pki_root_pass).asc),)
PKI_ROOT_PASSWD := $(shell gpg --decrypt --no-options --no-greeting --quiet $(pki_root_pass).asc)
else
PKI_ROOT_PASSWD := $(shell gpg --gen-random --armor 1 64)
endif

ifneq ($(wildcard $(pki_signing_pass).asc),)
PKI_SIGNING_PASSWD := $(shell gpg --decrypt --no-options --no-greeting --quiet $(pki_signing_pass).asc)
else
PKI_SIGNING_PASSWD := $(shell gpg --gen-random --armor 1 64)
endif

ifneq ($(wildcard $(pki_server_pass).asc),)
PKI_SERVER_PASSWD := $(shell gpg --decrypt --no-options --no-greeting --quiet $(pki_server_pass).asc)
else
PKI_SERVER_PASSWD := $(shell uuidgen)
endif

define encrypt_file
gpg --encrypt --no-options --no-greeting --armor --recipient=$(GPG_KEY) $(1) && shred -u $(1)
endef

define decrypt_text
gpg --decrypt --no-options --no-greeting --quiet $(1).asc
endef

secrets-encrypt: secrets-new
	$(call encrypt_file,$(pki_root_pass))
	$(call encrypt_file,$(pki_signing_pass))
	$(call encrypt_file,$(pki_server_pass))

secrets-new: $(dirs)
	gpg --gen-random --armor 1 64 >| $(pki_root_pass)
	gpg --gen-random --armor 1 64 >| $(pki_signing_pass)
	uuidgen >| $(pki_server_pass)

###############################################################################
# Errors Check
###############################################################################
prompt-destroy:
	echo "######################################################################"
	echo "# WARNING! - All TLS private keys will be destroyed!"
	echo "######################################################################"
	echo
	read -p "Continue destruction? (yes/no): " INP
	if [ "$${INP}" != "yes" ]; then 
	  echo "Deployment aborted"
	  exit 100
	fi

prompt-create:
	echo
	read -p "Create certificate? (yes/no): " INP
	if [ "$${INP}" != "yes" ]; then 
	  echo "Deployment aborted"
	  exit 100
	fi

ifndef PKI_CN
$(error Set PKI_CN ==> vim hosts/www.lab5.ca && source hosts/www.lab5.ca <==)
endif

ifndef PKI_SAN
$(error Set PKI_SAN ==> vim hosts/www.lab5.ca && source hosts/www.lab5.ca <==)
endif

ifeq ($(strip $(PKI_ROOT_PASSWD)),)
$(error PKI_ROOT_PASSWD is not set <==)
endif

ifeq ($(strip $(PKI_SIGNING_PASSWD)),)
$(error PKI_SIGNING_PASSWD is not set <==)
endif

ifeq ($(strip $(PKI_SERVER_PASSWD)),)
$(error PKI_SERVER_PASSWD is not set <==)
endif

ifeq ($(shell which openssl),)
$(error Missing command 'openssl'. https://www.openssl.org/)
endif

ifeq ($(shell which gpg),)
$(error Missing command 'gpg'. https://gnupg.org/)
endif

