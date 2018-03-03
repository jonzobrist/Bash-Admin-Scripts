#!/bin/bash
# Get ssl cert from a given IP:PORT
# writes to stdout
# Usage: get_server_ssl_certs.sh server port
#
# Useful if you are using self-signed certs and need a client to trust them
# Instead of finding your sysadmin and getting the public certs
# this just downloads them directly from the server
# Note: This collects PUBLIC certificate information ONLY, you will NOT get the private info
# This means you can use this to configure your client to TRUST a server's certificate
# But NOT to get what is required to use that certificate as a server
# 
# Example usage for Rsyslog testing
# mkdir -p /etc/rsyslog.d/certs
# get_server_ssl_certs.sh ssl.example.com:6514 > /etc/rsyslog.d/certs/example-com.pem 
# chown -R syslog:syslog /etc/rsyslog.d/certs

TEMP_FILE=$(mktemp)
if [ ! -w ${TEMP_FILE} ]; then echo "Failed to create temp file, exiting at $(date)"; fi
if [ ! $(which openssl) ]; then echo "Missing openssl, exiting at $(date)"; fi

HOST=${1}
PORT=${2}
if [ ${1} ] && [ ${2} ]
 then
    echo "" | openssl s_client -showcerts -connect ${HOST}:${PORT} > ${TEMP_FILE}
    cat ${TEMP_FILE} | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p'
else
    echo "Usage: ${0} HOST PORT"
    exit 1
fi

