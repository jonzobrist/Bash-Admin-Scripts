#!/bin/bash
#
# Author : Jon Zobrist <jon@jonzobrist.com>
# Homepage : http://www.jonzobrist.com
# License : BSD http://en.wikipedia.org/wiki/BSD_license
# Copyright (c) 2013, Jon Zobrist
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
# Purpose : This script takes a list of hostnames in a file
# and deletes the local users key for those hosts and adds a new one from the server.
#
# WARNING : from man ssh-keyscan 
# If an ssh_known_hosts file is constructed using ssh-keyscan without verifying the keys, users will be
# vulnerable to man in the middle attacks.  On the other hand, if the security model allows such a risk,
# ssh-keyscan can help in the detection of tampered keyfiles or man in the middle attacks which have
# begun after the ssh_known_hosts file was created.
#
# Usage : reset-ssh-keys-list-of-hosts.sh HOST_FILE

if [ ! "${1}" ]
then
    echo "Usage : ${0} HOST_FILE"
    exit 1
fi

HOST_FILE="${1}"
if [ ! -f "${HOST_FILE}" ]
then
    echo "${HOST_FILE} does not exist, exiting at $(date)"
    exit 1
fi

KNOWN_HOSTS_FILE="${HOME}/.ssh/known_hosts"

if [ ! -f "${KNOWN_HOSTS_FILE}" ]
then
    touch ${KNOWN_HOSTS_FILE}
    chmod og-rwx ${KNOWN_HOSTS_FILE}
fi

for S in $(cat ${HOST_FILE} | sort | uniq)
do
    echo -n "${S} "
    ssh-keygen -R ${S}-${HS} 2>/dev/null
    echo ""
done

ssh-keyscan -f ${HOST_FILE} -H -t rsa 2>/dev/null >> ${KNOWN_HOSTS_FILE}
