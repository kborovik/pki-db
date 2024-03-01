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

###############################################################################
# General Targets
###############################################################################

all: settings prompt-create db root signing server

clean: prompt-destroy
	-rm -rf ca crl certs .initialized

settings:
	echo "GPG_KEY=$(GPG_KEY)"
	echo "PKI_CN=$(PKI_CN)"
	echo "PKI_SAN=$(PKI_SAN)"

dirs := ca/root/db ca/signing/db certs

$(dirs):
	mkdir -p $(@)

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
	touch $(@)

###############################################################################
# Root PKI
###############################################################################

root_db := ca/root/db/root.db ca/root/db/root.db.attr
root_crl := ca/root/db/root.crt.srl ca/root/db/root.crl.srl
root_asc := ca/root.asc
root_key := ca/root.key
root_csr := ca/root.csr
root_crt := ca/root.crt

$(root_db): $(dirs)
	touch $(@)

$(root_crl): $(dirs)
	echo 01 > $(@)

$(root_asc):
	$(call gen_pass) > $(@)

$(root_key): $(root_asc)
	openssl genpkey -algorithm $(pkey_algorithm) -aes-256-cbc -pass pass:$(shell gpg -dq $(root_asc)) -out $(@)

$(root_csr): $(root_key)
	openssl req -new -config etc/root.conf -key $(root_key) -passin pass:$(shell gpg -dq $(root_asc)) -out $(@)

$(root_crt): $(root_csr)
	openssl ca -selfsign -config etc/root.conf -in $(root_csr) -extensions root_ca_ext -passin pass:$(shell gpg -dq $(root_asc)) -out $(@)
	$(call cert_clean,$(@))

###############################################################################
# Signing PKI
###############################################################################

signing_db := ca/signing/db/signing.db ca/signing/db/signing.db.attr
signing_crl := ca/signing/db/signing.crt.srl ca/signing/db/signing.crl.srl
signing_asc := ca/signing.asc
signing_key := ca/signing.key
signing_csr := ca/signing.csr
signing_crt := ca/signing.crt

$(signing_db): $(dirs)
	touch $(@)

$(signing_crl): $(signing_db)
	echo 01 > $(@)

$(signing_asc): $(root_crt)
	$(call gen_pass) > $(@)

$(signing_key): $(signing_asc)
	openssl genpkey -algorithm $(pkey_algorithm) -aes-256-cbc -pass pass:$(shell gpg -dq $(signing_asc)) -out $(@)

$(signing_csr): $(signing_key)
	openssl req -new -config etc/signing.conf -key $(signing_key) -passin pass:$(shell gpg -dq $(signing_asc)) -out $(@)

$(signing_crt): $(signing_csr)
	openssl ca -config etc/root.conf -in $(signing_csr) -extensions signing_ca_ext -passin pass:$(shell gpg -dq $(root_asc)) -out $(@)
	$(call cert_clean,$(@))

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
	$(call gen_pass) > $(@)

$(server_key): $(server_asc)
	openssl genpkey -algorithm $(pkey_algorithm) -aes-256-cbc -pass pass:$(shell gpg -dq $(server_asc)) -out $(@)

$(server_csr): $(server_key)
	openssl req -new -config etc/server.conf -key $(server_key) -passin pass:$(shell gpg -dq $(server_asc)) -out $(@)

$(server_crt): $(signing_crt) $(server_csr)
	openssl ca -config etc/signing.conf -in $(server_csr) -extensions server_ext -passin pass:$(shell gpg -dq $(signing_asc)) -out $(@)
	$(call cert_clean,$(@))

$(server_p12): $(server_key) $(server_crt) $(root_ca)
	openssl pkcs12 -export -legacy -inkey $(server_key) -in $(server_crt) -chain -CAfile $(root_ca) -name $(PKI_CN) -passout pass:$(shell gpg -dq $(server_asc)) -passin pass:$(shell gpg -dq $(server_asc)) -out $(@)

.PHONY: show-key show-csr show-crt show-p12

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

.PHONY: db root signing server

init: .initialized

db: $(root_db) $(root_crl) $(signing_db) $(signing_crl)

root: $(root_crt)

signing: $(signing_crt)

server: $(root_ca) $(server_crt) $(server_p12)

###############################################################################
# Functions
###############################################################################

define cert_clean
openssl x509 -outform PEM -in $(1) -out $(1)
endef

define gen_pass
gpg --gen-random --armor 1 96 | tr -d '/=+' | cut -c -64 | tr -d '[:space:]' | gpg -e -r $(GPG_KEY)
endef

define header
clear
echo "######################################################################"
echo "# $(1)"
echo "######################################################################"
endef

define pause
read -p "Press [Enter] to continue..." INP && [ "$${INP}" != "yes" ]
endef

###############################################################################
# Demo
###############################################################################

.PHONY: demo record

demo:
	$(call header,"Remove Old PKI Data")
	$(MAKE) clean
	$(call header,"Show Directory Structure")
	tree
	$(call pause)
	$(call header,"Create New Certificates Authority and Server Certificates")
	$(MAKE) all
	$(call header,"Show Directory Structure")
	tree
	$(call pause)
	$(call header,"Show Server Private Key")
	$(MAKE) show-key
	$(call pause)
	$(call header,"Show Server Certificate Signing Request")
	$(MAKE) show-csr
	$(call pause)
	$(call header,"Show Server Certificate")
	$(MAKE) show-crt
	$(call pause)
	$(call header,"Show Server PKCS")
	$(MAKE) show-p12

record:
	asciinema rec -t "pki-db make" -c "make demo"

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

