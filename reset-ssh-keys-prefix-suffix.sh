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
# Purpose : This script takes a list of prefixes, and suffixes, creates a list of hostnames
# and deletes the local users key for those hosts and adds a new one.
# I created this for use on Amazon Web Services EC2 since we are re-using similar name aliases
# and need an easy way to update the ssh keys.
#
# WARNING : from man ssh-keyscan 
# If an ssh_known_hosts file is constructed using ssh-keyscan without verifying the keys, users will be
# vulnerable to man in the middle attacks.  On the other hand, if the security model allows such a risk,
# ssh-keyscan can help in the detection of tampered keyfiles or man in the middle attacks which have
# begun after the ssh_known_hosts file was created.
#
# Usage : reset-ssh-keys-prefix-suffix.sh

HOST_PREFIXES="qa dev web prod"
HOST_SUFFIXES="webserver.example.com dbserver.example.com"
KNOWN_HOSTS_FILE="${HOME}/.ssh/known_hosts"
if [ ! -f "${KNOWN_HOSTS_FILE}" ]
then
    touch ${KNOWN_HOSTS_FILE}
    chmod og-rwx ${KNOWN_HOSTS_FILE}
fi

for S in ${HOST_PREFIXES}
do
    echo -n "${S} "
    for HS in ${HOST_SUFFIXES}
    do
        echo -n "${S}-${HS} "
        ssh-keygen -R ${S}-${HS} 2>/dev/null
        ssh-keyscan -H -t rsa ${S}-${HS} 2>/dev/null >> ${KNOWN_HOSTS_FILE}
    done
    echo ""
done

