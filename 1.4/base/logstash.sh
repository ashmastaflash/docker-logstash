#!/bin/bash

# Fail fast, including pipelines
set -e -o pipefail

# Set LOGSTASH_TRACE to enable debugging
[[ $LOGSTASH_TRACE ]] && set -x

# If you don't provide a value for the LOGSTASH_CONFIG_URL env
# var, your install will default to our very basic logstash.conf file.
#
LOGSTASH_DEFAULT_CONFIG_URL='https://gist.githubusercontent.com/ashmastaflash/fd83e5d87b337889aaf4/raw/ab02152ac1f271d05fd25f527c7456985f592f1a/logstash.conf'
LOGSTASH_CONFIG_URL=${LOGSTASH_CONFIG_URL:-${LOGSTASH_DEFAULT_CONFIG_URL}}

LOGSTASH_SRC_DIR='/opt/logstash'

LOGSTASH_CONFIG_DIR="${LOGSTASH_SRC_DIR}/conf.d"
LOGSTASH_CONFIG_FILE="${LOGSTASH_CONFIG_DIR}/logstash.conf"

LOGSTASH_BINARY="${LOGSTASH_SRC_DIR}/bin/logstash"

LOGSTASH_LOG_DIR='/var/log/logstash'
LOGSTASH_LOG_FILE="${LOGSTASH_LOG_DIR}/logstash.log"

# Create the logstash conf dir if it doesn't already exist
#
function logstash_create_config_dir() {
    local config_dir="$LOGSTASH_CONFIG_DIR"

    if ! mkdir -p "${config_dir}" ; then
        echo "Unable to create ${config_dir}" >&2
    fi
}

# Download the logstash config if the config directory is empty
#
function logstash_download_config() {
    local config_dir="$LOGSTASH_CONFIG_DIR"
    local config_file="$LOGSTASH_CONFIG_FILE"
    local config_url="$LOGSTASH_CONFIG_URL"

    if [ ! "$(ls -A $config_dir)" ]; then
        wget "$config_url" -O "$config_file"
    fi
}

# Replace ES_HOST and ES_PORT in your logstash.conf file
# if they exist with the IP and port dynamically generated
# by docker.
#
# Note: Don't use this on a file mounting using a docker
# volume, as the inode switch will cause `device or resource busy`
# Instead download your file as normal
#
function logstash_sanitize_config() {
    local embedded="$(es_service_embedded)"
    local host="$(es_service_host)"
    local port="$(es_service_port)"

    sed -e "s|ES_EMBEDDED|${embedded}|g" \
        -e "s|ES_HOST|${host}|g" \
        -e "s|ES_PORT|${port}|g" \
        -i "$LOGSTASH_CONFIG_FILE"
}

function logstash_create_log_dir() {
    local log_dir="$LOGSTASH_LOG_DIR"

    if ! mkdir -p "${log_dir}" ; then
        echo "Unable to create ${log_dir}" >&2
    fi
}

function logstash_start_agent() {
    local binary="$LOGSTASH_BINARY"
    local config_dir="$LOGSTASH_CONFIG_DIR"
    local log_file="$LOGSTASH_LOG_FILE"

    case "$1" in
    # run just the agent
    'agent')
        exec "$binary" \
             agent \
             --config "$config_dir" \
             --log "$log_file" \
             --
        ;;
    # test the logstash configuration
    'configtest')
        exec "$binary" \
             agent \
             --config "$config_dir" \
             --log "$log_file" \
             --configtest \
             --
        ;;
    # run just the web
    'web')
        exec "$binary" \
             web
        ;;
    # run agent+web (default operation)
    *)
        exec "$binary" \
             agent \
             --config "$config_dir" \
             --log "$log_file" \
             -- \
             web
        ;;
    esac
}
