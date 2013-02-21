#!/bin/bash
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
# Purpose : This script aims to gather all public ssh keys on a server and put them in a directory, with appropriate names
# Usage : gather-public-ssh-keys.sh [Directory]


if [ -f "${1}" ]
 then
	echo "ARE YOU SURE YOU WANT TO NUKE the following instances in file ${1} at `date`"
	cat ${1}
	read -p "Do you want to proceed? --[Will cancel automatically in 15 seconds]- (yes/no)? " -t 15 ANSWER

	if [ "$?" != "0" ]
	 then
		echo
		echo "You didn't answer in 15 seconds, cancelling"
		ANSWER="no"
	fi

	if [ "${ANSWER}" == "no" ] || [ "${ANSWER}" == "n" ] || [ "${ANSWER}" == "NO" ] || [ "${ANSWER}" == "N" ]
	 then
		echo "NO: Exiting."
		exit 0
	elif [ "${ANSWER}" == "yes" ] || [ "${ANSWER}" == "y" ] || [ "${ANSWER}" == "YES" ] || [ "${ANSWER}" == "Y" ]
	 then
		echo "YES: Proceeding."
	else
		echo "Did not understand your choice, please choose again (yes or no)"
		confirm
	fi

	sleep 5
	for I in $(cat ${1})
	 do 
		#TO DO, add checking to see if string looks like an instance ID and that the instance is available
		echo "${I}"
		ec2-modify-instance-attribute --disable-api-termination false ${I}
		ec2-stop-instances -f ${I}
		while !  ec2-describe-instances ${I} | grep -q stopped; do echo -n "."; sleep 1; done
		for V in $(ec2-describe-instances ${I} | grep '^BLOCKDEVICE' | awk '{ print $3 }')
		 do
			echo "nuking volume ${V}"
                        echo -n "Detaching."
                        while ec2-detach-volume ${V} 2>&1 | grep -q detached; do echo -n "."; sleep 1; done
                        echo -n "Deleting."
			while ec2-delete-volume ${V} 2>&1 | grep -q 'does not exist'; do echo -n "."; sleep 1; done
		done
		echo "disabling termination protection on ${I}"
		ec2-modify-instance-attribute --disable-api-termination false ${I}
		sleep 5
		echo "terminating instance ${I}"
		ec2-terminate-instances ${I}
	done
else
	echo "Usage : ${0} <filename> - where filename has instances one per line that will be nuked"
fi
