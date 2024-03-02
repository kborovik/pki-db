.ONESHELL:
.SILENT:
.EXPORT_ALL_VARIABLES:

###############################################################################
# Variables
###############################################################################

GPG_KEY ?= 79A09C51CF531E16444D6871B59466C2C0CCF0BF
PKI_CN ?=
PKI_SAN ?=

# Valid algorithm names for private key generation are RSA, RSA-PSS, ED25519, ED448
pkey_algorithm ?= ED25519
pkey_pass_size ?= 64

###############################################################################
# General Targets
###############################################################################

.PHONY: default clean settings

default: settings prompt-create root signing server

clean: prompt-destroy
	-rm -rf ca crl certs .initialized
	$(MAKE) db

settings: $(dirs)
	echo "######################################################################"
	openssl version
	echo "GPG_KEY=$(GPG_KEY)"
	echo "PKI_CN=$(PKI_CN)"
	echo "PKI_SAN=$(PKI_SAN)"
	echo "######################################################################"

dirs := ca/root/db ca/signing/db certs

$(dirs):
	mkdir -p $(@)

###############################################################################
# Root PKI
###############################################################################

root_db := ca/root/db/root.db ca/root/db/root.db.attr
root_asc := ca/root.asc
root_key := ca/root.key
root_csr := ca/root.csr
root_crt := ca/root.crt

$(root_db): $(dirs)
	touch $(@)

$(root_asc):
	$(call gen_pass,$(pkey_pass_size)) > $(@)

$(root_key): $(root_asc)
	openssl genpkey -algorithm $(pkey_algorithm) -aes-256-cbc -pass pass:$(shell gpg -dq $(root_asc)) -out $(@)

$(root_csr): $(root_key)
	openssl req -new -config etc/root.conf -key $(root_key) -passin pass:$(shell gpg -dq $(root_asc)) -out $(@)

$(root_crt): $(root_csr)
	openssl ca -selfsign -rand_serial -config etc/root.conf -in $(root_csr) -extensions root_ca_ext -passin pass:$(shell gpg -dq $(root_asc)) -out $(@)
	$(call clean_cert,$(@))

###############################################################################
# Signing PKI
###############################################################################

signing_db := ca/signing/db/signing.db ca/signing/db/signing.db.attr
signing_asc := ca/signing.asc
signing_key := ca/signing.key
signing_csr := ca/signing.csr
signing_crt := ca/signing.crt

$(signing_db): $(dirs)
	touch $(@)

$(signing_asc): $(root_crt)
	$(call gen_pass,$(pkey_pass_size)) > $(@)

$(signing_key): $(signing_asc)
	openssl genpkey -algorithm $(pkey_algorithm) -aes-256-cbc -pass pass:$(shell gpg -dq $(signing_asc)) -out $(@)

$(signing_csr): $(signing_key)
	openssl req -new -config etc/signing.conf -key $(signing_key) -passin pass:$(shell gpg -dq $(signing_asc)) -out $(@)

$(signing_crt): $(signing_csr)
	openssl ca -rand_serial -config etc/root.conf -in $(signing_csr) -extensions signing_ca_ext -passin pass:$(shell gpg -dq $(root_asc)) -out $(@)
	$(call clean_cert,$(@))

###############################################################################
# CA certificates
###############################################################################

root_ca := certs/ca-certificates.crt

$(root_ca): $(root_crt) $(signing_crt)
	cat $(root_crt) $(signing_crt) > $(@)

###############################################################################
# Servers PKI
###############################################################################

server_asc := certs/$(PKI_CN).asc
server_key := certs/$(PKI_CN).key
server_csr := certs/$(PKI_CN).csr
server_crt := certs/$(PKI_CN).crt
server_p12 := certs/$(PKI_CN).p12

$(server_asc):
	$(call gen_pass,15) > $(@)

$(server_key): $(server_asc)
	openssl genpkey -algorithm $(pkey_algorithm) -aes-256-cbc -pass pass:$(shell gpg -dq $(server_asc)) -out $(@)

$(server_csr): $(server_key)
	openssl req -new -config etc/server.conf -key $(server_key) -passin pass:$(shell gpg -dq $(server_asc)) -out $(@)

$(server_crt): $(signing_crt) $(server_csr)
	openssl ca -rand_serial -config etc/signing.conf -in $(server_csr) -extensions server_ext -passin pass:$(shell gpg -dq $(signing_asc)) -out $(@)
	$(call clean_cert,$(@))

$(server_p12): $(server_key) $(server_crt) $(root_ca)
	openssl pkcs12 -export -legacy -inkey $(server_key) -in $(server_crt) -chain -CAfile $(root_ca) -name $(PKI_CN) -passout pass:$(shell gpg -dq $(server_asc)) -passin pass:$(shell gpg -dq $(server_asc)) -out $(@)

.PHONY: show-pass show-key show-csr show-crt show-p12

show-pass:
	gpg -dq $(server_asc)

show-key:
	openssl pkey -in $(server_key) -passin pass:$(shell gpg -dq $(server_asc))

show-csr:
	openssl req -text -noout -in $(server_csr)

show-crt:
	openssl x509 -text -noout -in $(server_crt)

show-p12:
	openssl pkcs12 -noenc -legacy -info -in $(server_p12) -passin 'pass:$(shell gpg -dq $(server_asc))'

###############################################################################
# General Targets
###############################################################################
.PHONY: init db root signing server

init_files := $(root_asc) $(root_key) $(root_csr) $(root_crt) $(signing_asc) $(signing_key) $(signing_csr) $(signing_crt) $(root_ca) $(server_asc) $(server_key) $(server_csr) $(server_crt) $(server_p12)

.initialized:
	$(info ==> initializing PKI DB <==)
	for file in $(init_files); do
		test -f $${file} && touch $${file} && echo $${file} && sleep 1
	done
	touch $(@)

init:
	rm -rf .initialized
	$(MAKE) .initialized

db: $(root_db) $(signing_db)

root: $(root_crt)

signing: $(signing_crt)

server: $(root_ca) $(server_crt) $(server_p12) .initialized

###############################################################################
# Functions
###############################################################################

define clean_cert
openssl x509 -outform PEM -in $(1) -out $(1)
endef

define gen_pass
gpg --gen-random --armor 1 128 | tr -d '/=+' | cut -c -$(1) | tr -d '[:space:]' | gpg -e -r $(GPG_KEY)
endef

###############################################################################
# Demo
###############################################################################

.PHONY: demo-record

demo-record:
	asciinema rec -t "pki-db make"

###############################################################################
# Prompts
###############################################################################

.PHONY: prompt-destroy prompt-create

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

###############################################################################
# Errors Check
###############################################################################

ifndef PKI_CN
$(error Set PKI_CN ==> vim hosts/www.lab5.ca && source hosts/www.lab5.ca <==)
endif

ifndef PKI_SAN
$(error Set PKI_SAN ==> vim hosts/www.lab5.ca && source hosts/www.lab5.ca <==)
endif

ifeq ($(shell which openssl),)
$(error Missing command 'openssl'. https://www.openssl.org/)
endif

ifeq ($(shell which gpg),)
$(error Missing command 'gpg'. https://gnupg.org/)
endif

