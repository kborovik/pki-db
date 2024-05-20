.EXPORT_ALL_VARIABLES:
.ONESHELL:
.SILENT:

MAKEFLAGS += --no-builtin-rules --no-builtin-variables

###############################################################################
# Variables
###############################################################################

COMMON_NAME ?= www.lab5.ca
SUBJECT_ALT_NAME ?= DNS:www.lab5.ca,IP:127.0.0.1,email:user@email.com

###############################################################################
# Variables
###############################################################################

GPG_KEY ?= 1A4A6FC0BB90A4B5F2A11031E577D405DD6ABEA5
pkey_pass_size ?= 64
openssl_version := $(shell openssl version)

###############################################################################
# General Targets
###############################################################################

.PHONY: default clean settings

default: settings prompt-create root signing server .initialized

settings: $(dirs)
	$(call header,Certificate)
	$(call var,COMMON_NAME,$(COMMON_NAME))
	$(call var,SUBJECT_ALT_NAME,$(SUBJECT_ALT_NAME))
	$(call header,Software)
	$(call var,OpenSSL Version,$(openssl_version))
	$(call var,GPG_KEY,$(GPG_KEY))

clean: prompt-delete
	$(call header,Cleaning PKI DB)
	-rm -rf ca crl certs .initialized
	$(MAKE) db

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
	openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -aes-256-cbc -pass pass:$(shell gpg -dq $(root_asc)) -out $(@)

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
	openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -aes-256-cbc -pass pass:$(shell gpg -dq $(signing_asc)) -out $(@)

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

server_env := hosts/$(COMMON_NAME)
server_asc := certs/$(COMMON_NAME).asc
server_key := certs/$(COMMON_NAME).key
server_csr := certs/$(COMMON_NAME).csr
server_crt := certs/$(COMMON_NAME).crt
server_p12 := certs/$(COMMON_NAME).p12

$(server_asc):
	$(call gen_pass,15) > $(@)

$(server_key): $(server_asc)
	openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -aes-256-cbc -pass pass:$(shell gpg -dq $(server_asc)) -out $(@)

$(server_csr): $(server_key) $(server_env)
	openssl req -new -config etc/server.conf -key $(server_key) -passin pass:$(shell gpg -dq $(server_asc)) -out $(@)

$(server_crt): $(signing_crt) $(server_csr)
	openssl ca -rand_serial -config etc/signing.conf -in $(server_csr) -extensions server_ext -passin pass:$(shell gpg -dq $(signing_asc)) -out $(@)
	$(call clean_cert,$(@))

$(server_p12): $(server_key) $(server_crt) $(root_ca)
	openssl pkcs12 -export -legacy -inkey $(server_key) -in $(server_crt) -chain -CAfile $(root_ca) -name $(COMMON_NAME) -passout pass:$(shell gpg -dq $(server_asc)) -passin pass:$(shell gpg -dq $(server_asc)) -out $(@)

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
	$(call header,Initialize PKI DB)
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

server: $(root_ca) $(server_crt) $(server_p12)

###############################################################################
# NSSDB
###############################################################################

nssdb := ~/.pki/nssdb

.PHONY: nssdb-import nssdb-list nssdb-clean

.nssdb-import-ca: $(root_crt) $(signing_crt)
	certutil -A -n "RootCA" -t "CT,C,C" -i $(root_crt) -d $(nssdb)
	certutil -A -n "SigningCA" -t "C,C,C" -i $(signing_crt) -d $(nssdb)
	touch $(@)

nssdb-import: .nssdb-import-ca $(server_p12)
	pk12util -i $(server_p12) -W $(shell gpg -dq $(server_asc)) -d $(nssdb)

nssdb-list:
	certutil -L -d $(nssdb)

nssdb-clean:
	certutil -D -n "RootCA" -d $(nssdb)
	certutil -D -n "SigningCA" -d $(nssdb)
	certutil -D -n $(COMMON_NAME) -d $(nssdb)
	rm .nssdb-import-ca

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
# Errors Check
###############################################################################

ifndef COMMON_NAME
$(error COMMON_NAME is not exported ==> source hosts/www.lab5.ca <==)
endif

ifndef SUBJECT_ALT_NAME
$(error SUBJECT_ALT_NAME is not exported ==> source hosts/www.lab5.ca <==)
endif

ifeq ($(shell which openssl),)
$(error Missing command 'openssl'. https://www.openssl.org/)
endif

ifeq ($(shell which gpg),)
$(error Missing command 'gpg'. https://gnupg.org/)
endif

###############################################################################
# Repo Version
###############################################################################

.PHONY: version

version:
	version=$$(date +%Y.%m.%d-%H%M)
	echo "$$version" >| VERSION
	$(call header,Version: $$(cat VERSION))
	git add VERSION

commit: version
	git add --all
	git commit -m "$$(cat VERSION)"

tag:
	version=$$(date +%Y.%m.%d)
	git tag "$$version" -m "Version: $$version" --force

release: commit tag
	git push --tags --force

###############################################################################
# Colors and Headers
###############################################################################

black := \033[30m
red := \033[31m
green := \033[32m
yellow := \033[33m
blue := \033[34m
magenta := \033[35m
cyan := \033[36m
white := \033[37m
reset := \033[0m

define header
echo "$(blue)==> $(1) <==$(reset)"
endef

define help
echo "$(green)$(1)$(reset) - $(white)$(2)$(reset)"
endef

define var
echo "$(magenta)$(1)$(reset): $(yellow)$(2)$(reset)"
endef

prompt-create:
	echo -n "$(blue)Create Certificates?$(reset) $(white)(yes/no)$(reset)"
	read -p ": " answer && [ "$$answer" = "yes" ] || exit 1

prompt-delete:
	echo -n "$(blue)Delete PKI DB?$(reset) $(yellow)(yes/no)$(reset)"
	read -p ": " answer && [ "$$answer" = "yes" ] || exit 1
