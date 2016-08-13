#!/bin/bash
#
# Author : Jon Zobrist <jon@jonzobrist.com>
# Homepage : http://www.jonzobrist.com
# License : BSD http://en.wikipedia.org/wiki/BSD_license
# Copyright (c) 2016, Jon Zobrist
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
# Purpose : Script to set net.ipv4.tcp_challenge_ack_limit to something random
# This helps mitigate CVE-2016-5696
# THIS IS NOT A FIX FOR CVE-2016-5696
# https://www.usenix.org/system/files/conference/usenixsecurity16/sec16_paper_cao.pdf


unset TCAL
TCAL=$(grep net.ipv4.tcp_challenge_ack_limit /etc/sysctl.conf)
if [ ! "${TCAL}" ]
 then
    if [[ $EUID -ne 0 ]]
     then
        echo "Setting does not exist in /etc/sysctl.conf, re-run as root to set"
        exit 0
    fi
    echo "Setting does not exist in /etc/sysctl.conf, adding:"
    LIMIT=$(echo "999999999 - ${RANDOM} * ${RANDOM}" | bc)
    echo "net.ipv4.tcp_challenge_ack_limit = ${LIMIT}" >> /etc/sysctl.conf
    sudo sysctl -p
else echo "Setting exists in /etc/sysctl.conf"
    grep -n net.ipv4.tcp_challenge_ack_limit /etc/sysctl.conf
fi

