#!/usr/bin/env bash
# 
#
# Author : Jon Zobrist <jon@jonzobrist.com>
# Homepage : http://www.jonzobrist.com
# License : BSD http://en.wikipedia.org/wiki/BSD_license
# Copyright (c) 2012, Jon Zobrist
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Purpose : This script aims to provide dynamic DNS names using Amazon Route 53
# It attempts to detected your public IP, track if it has changed, 
# and update Route 53 if it has
# Usage : update-dns-external.sh
# Typically from crontab something like
# */15 * * * * /home/ubuntu/bin/update-dns-external.sh >> ${HOME}/logs/dns-external.log

# Everything should have a debug statement that is easily toggled
# This will trip if you set DEBUG to 1
# DEBUG=1
DEBUG () {
    if [ "${DEBUG}" ]
     then
        if [ ${DEBUG} -eq 1 ]
         then
        echo "DEBUG $(date +%s): ${1}"
        fi
    fi
}

# If you want to separate config from code. If not, do'nt have config file and set values in the else block
CONFIG_FILE="${HOME}/etc/update-dns-external.conf"
if [ "${CONFIG_FILE}" ]
 then
    if [ -e "${CONFIG_FILE}" ]
     then
        DEBUG "Using config file"
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
    fi
else
    DEBUG "NOT using a config file, variables loaded from script"
    # Do you want DEBUG on? Anything true will be on (1, true, randomstring), false (0/unset) will be off
    DEBUG=${DEBUG:-0}
    export DEBUG

    # TODO: add test only mode
    # Maybe you only want to test the API call to Route 53, set this true
    TEST_ONLY_MODE=1
    export TEST_ONLY_MODE

    # FQDN can be static or use this hosts hostname output for it
    FQDN=$(hostname)
    export FQDN

    # Host is everything left of the first '.'
    HOST=${FQDN%%.*}
    export HOST

    # Apex domain is everything after the first '.', note this won't work for all sub-domains/configurations
    # for example it won't work if your FQDN is www.subdomain.example.com and the apex record you want is example.com and not subdomain.example.com
    APEXD=${FQDN#*.}
    export APEXD

    # Hosted zone ID from Route53
    # aws --profile ${P} route53 list-hosted-zones-by-name --output text --dns-name "example.com." --query 'HostedZones[0].Id'
    HOSTED_ZONE_ID="AWSZONEID"
    export HOSTED_ZONE_ID

    # Location of a file to record the last public IP we saw
    # This used to be used but I now check R53 setting instead of tracking
    # todo: remove last_ip
    LAST_IP_FILE="${HOME}/etc/lastpublicip"
    export LAST_IP_FILE

    # Which AWS profile you want to use, if you don't have one set to 'default'
    AWS_PROFILE="default"
    export AWS_PROFILE

    # This is the JSON template file for the Route 53 update
    # Ideally Route 53 wouldn't need this, but I did it this way years ago and am too lazy rn to change
    # Feel free to send me a PR with a single script version or change the API to a better one
    EXTERNAL_JSON_TEMPLATE="${HOME}/etc/external.json"
    export EXTERNAL_JSON_TEMPLATE

    # Where to get the IP from, can return almost any text
    # We'll grep -o out the IP address, and only use the first 1
    # This may break if your page has multiple IPs in it
    # I use www.dangfast.com/ip as it's my test site using httpbin.org
    # HTTPBin has /ip built in, and returns JSON format by default
    # No guarantee it'll be up forever. 
    # Note, using HTTPS is more reliable to get your actual IP
    # As HTTP is more commonly proxied than HTTPS, which is more commoly routed
    IP_HTTP_URL="https://www.dangfast.com/ip"
    export IP_HTTP_URL

    # print a debug of the CSV file to track changes over time to
    # Todo: make this a live google spreadsheet
    CSV_HISTORY="${HOME}/ip-log-change-$(date +%Y).csv"
    export CSV_HISTORY

    # Do you want to use the Route 53 API to check your IP?
    # API calls are more expensive, potentially in $$$ than DNS queries
    USE_R53_API=1
    export USE_R53_API
fi

# I install awscli via PIP and prefer to specify --user, like
# pip3 install --user awscli
# And my cron doesn't source my .zshrc, where I set a path
# So I use this for cron jobs
PIP_LOCAL_DIR="${HOME}/.local/bin"

if [ -d "${PIP_LOCAL_DIR}" ]
then
    export PATH="${PATH}:${PIP_LOCAL_DIR}"
fi

################################################################
# END OF CONFIGURATION SECTION
################################################################

################################################################
# Dependency checking
# This script depends on the AWS CLI being installed
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
AWS_CMD=$(command -v aws)
# This script depends on the curl command being installed)
# https://curl.se/download.html
CURL_CMD=$(command -v curl)
GREP_CMD=$(command -v egrep)
DIG_CMD=$(command -v dig)
NSLOOKUP_CMD=$(command -v nslookup)
################################################################

# Make sure we have our required executables
if [ -x "${AWS_CMD}" ] || [ -x "${CURL_CMD}" ] || [ -x "${GREP_CMD}" ] || { [ -x "${DIG_CMD}" ] || [ -x "${NSLOOKUP_CMD}" ]; }
 then

    ################################################################
    # Determine our last known IP, the Route 53 IP (via R53 API or DNS), 
    # and what we are seen as publicly/public IP
    ################################################################
    # Do we have a last IP file?
    # If so, grep the first IP out of it!
    # re-bootstrapping can start without a LAST_IP_FILE
    # or be initiated by deleting the LAST_IP_FILE
    if [ -f "${LAST_IP_FILE}" ]
     then
        LAST_IP=$(${GREP_CMD} -o '(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}' "${LAST_IP_FILE}" | head -n 1)
        DEBUG "${LAST_IP_FILE} exists at $(date), and the last IP was ${LAST_IP}"
     else
        # Don't have a LAST_FILE_FILE?
        # Move ahead with NONE
        LAST_IP='NONE'
    fi

    # Above we parsed our last IP out of the last IP file or set it to NONE
    # This should trigger if we had a LAST_IP_FILE but failed to match it in our regex
    # In which case we want to overwrite that file with a new, garbage IP
    if [ ! "${LAST_IP}" ]
    then
        LAST_IP='NONE'
        /bin/rm "${LAST_IP_FILE}"
        echo ${LAST_IP} > "${LAST_IP_FILE}"
        chmod og-rwx "${LAST_IP_FILE}"
        DEBUG "${LAST_IP_FILE} created with NONE at $(date)"
    fi

    # Route 53 API can tell us the current IP if we prefer it over DNS
    # Toggle w/USE_R53_API flag
    if [ "${USE_R53_API}" ]
     then
        # print our command if DEBUG is true
        DEBUG "We're using Route 53 API to check for the current IP, since USE_R53_API is true"
        DEBUG "${AWS_CMD} --profile ${AWS_PROFILE:-default} route53 list-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --query \"ResourceRecordSets[?Name == '${FQDN}'].ResourceRecords[].Value\" --output text"

        # Execute our Route 53 API call to get the last IP
        R53IP=$("${AWS_CMD}" --profile ${AWS_PROFILE:-default} route53 list-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --query "ResourceRecordSets[?Name == '${FQDN}'].ResourceRecords[].Value" --output text)
    DEBUG "Got R53IP from Route 53 API and it's value is ${R53IP}"
    else
        DEBUG "Using DNS and NOT using Route 53 API to find currently configured IP"
        if [ -x "${DIG_CMD}" ]
         then
            DEBUG "We have dig at ${DIG_CMD}, and USE_R53_API is not set"
            R53IP=$("${DIG_CMD}" +short "${FQDN}" | "${GREP_CMD}" -o '(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}' | head -n 1)
        elif [  -x "${NSLOOKUP_CMD}" ]
         then
            DEBUG "We have no dig, but do have nslookup at ${NSLOOKUP_CMD}, and USE_R53_API is not set"
            R53IP=$("${NSLOOKUP_CMD}" "${FQDN}" | "${GREP_CMD}" -o '(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}' | head -n 1)
        fi
    fi
    # print a debug summary of what we've got and what we're doing
    DEBUG "CURR R53 IP ${R53IP}, Last IP ${LAST_IP}, FQDN ${FQDN}, HOST ${HOST}, APEXD ${APEXD}"

    # Get our external / publicly viewable IP address
    IP=$(${CURL_CMD} -s ${IP_HTTP_URL} | ${GREP_CMD} -o '(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}')
    DEBUG "Got IP:${IP} from ${IP_HTTP_URL} at $(date)"
    ################################################################
    # END OF IP INFORMATION FINDING SECTION
    ################################################################


    ################################################################
    # Let's compare and update if we don't match
    # If they string match, we are golden (DNS/R53 IP matches our external/public IP) - no action required
    # If they DO NOT string match, we need to update the DNS w/Route 53
    if [ "${R53IP}" ] && [ "${IP}" ] && [ ! "${R53IP}" == "${IP}" ]
     then
        DEBUG "Route53/DNS IP ${R53IP} is not current IP ${IP} updating at $(date)"
        # JSON_RECORD=$(sed "s/RECORD_VALUE/${IP}/" < "${EXTERNAL_JSON_TEMPLATE}")
        JSON_RECORD=$(sed -e "s/RECORD_VALUE/${IP}/" -e "s/RECORD_NAME/${FQDN}/" < "${EXTERNAL_JSON_TEMPLATE}")
    DEBUG "JSON_RECORD"
    DEBUG "${JSON_RECORD}"

        if [ "${CSV_HISTORY}" ]
     then
        #Lets update our csv for long term IP tracking
        #CSV Format is:
        #DAY, Unix time, current IP, last IP
        DEBUG "CSV file is ${CSV_HISTORY}"
        echo "$(date +%F),$(date +%s),${IP},${R53IP}" >> "${CSV_HISTORY}"
    else
        DEBUG "CSV file is NOT set, not emitting"
        DEBUG "$(date +%F),$(date +%s),${IP},${R53IP}"
        fi

    # http://docs.aws.amazon.com/cli/latest/reference/route53/change-resource-record-sets.html
    # We want to use the string variable command so put the file contents (batch-changes file) in the following JSON
    INPUT_JSON="{ \"ChangeBatch\": $JSON_RECORD}"
    DEBUG "${AWS_CMD}" --profile ${AWS_PROFILE:-default} route53 change-resource-record-sets --hosted-zone-id "${HOSTED_ZONE_ID}" --cli-input-json "${INPUT_JSON}"
         "${AWS_CMD}" --profile ${AWS_PROFILE:-default} route53 change-resource-record-sets --hosted-zone-id "${HOSTED_ZONE_ID}" --cli-input-json "${INPUT_JSON}"
        /bin/rm "${LAST_IP_FILE}"
        echo "${IP}" > "${LAST_IP_FILE}"
    else
        DEBUG "Public IP ${IP} matches last public DNS ${R53IP}, skipping updating at $(date)"
	echo "IP (${IP}) unchanged from R53IP(${R53IP}), skipping updating at $(date)"
        exit 0
    fi
################################################################
# END OF COMPARE/ACTION SECTION
################################################################

# Dependency/settings ailure handling
else
    echo "Missing dependencies or settings, this is what we have"
    echo "CURR R53 IP:${R53IP}, Last IP:${LAST_IP}, FQDN:${FQDN}, HOST:${HOST}, APEXD:${APEXD}"
    echo "curl is ${CURL_CMD}"
    echo "aws is ${AWS_CMD}"
    echo "grep is ${GREP_CMD}"
    echo "dig is ${DIG_CMD}"
    echo "nslookup is ${NSLOOKUP_CMD}"
fi
