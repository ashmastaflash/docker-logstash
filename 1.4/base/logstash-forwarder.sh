#!/bin/bash

# Fail fast, including pipelines
set -e -o pipefail

# Set LOGSTASH_TRACE to enable debugging
[[ $LOGSTASH_TRACE ]] && set -x

LF_SSL_DIR='/opt/ssl'

# The default logstash-forwarder keys are insecure. Please do not
# use them in production.
#
LF_SSL_CERT_KEY_URL=${LF_SSL_CERT_KEY_URL:-"https://gist.githubusercontent.com/pblittle/8994708/raw/insecure-logstash-forwarder.key"}
LF_SSL_CERT_URL=${LF_SSL_CERT_URL:-"https://gist.githubusercontent.com/pblittle/8994726/raw/insecure-logstash-forwarder.crt"}

LF_SSL_CERT_KEY_FILE="${LF_SSL_DIR}/logstash-forwarder.key"
LF_SSL_CERT_FILE="${LF_SSL_DIR}/logstash-forwarder.crt"
LF_SSL_CSR_FILE="${LF_SSL_DIR}/logstash-forwarder.csr"
LF_SSL_CSR_SUBJECT="/C=US/ST=CA/L=SF/O=NotSoSecure/OU=YoMomma/CN=barfola.com"

function forwarder_create_ssl_dir() {
    local ssl_dir="$LF_SSL_DIR"

    if ! mkdir -p "${ssl_dir}" ; then
        echo "Unable to create ${ssl_dir}" >&2
    fi
}

function forwarder_create_cert() {
    openssl x509 -req -days 365 -in $LF_SSL_CSR_FILE -signkey $LF_SSL_CERT_KEY_FILE -out $LF_SSL_CERT_FILE

}

function forwarder_create_key_and_csr() {
    openssl req -nodes -newkey rsa:2048 keyout $LF_SSL_CERT_KEY_FILE -out $LF_SSL_CSR_FILE -subj $LF_SSL_CSR_SUBJECT
}

function forwarder_download_cert() {
    wget "$LF_SSL_CERT_URL" -O "$LF_SSL_CERT_FILE"
}

function forwarder_download_key() {
    wget "$LF_SSL_CERT_KEY_URL" -O "$LF_SSL_CERT_KEY_FILE"
}
