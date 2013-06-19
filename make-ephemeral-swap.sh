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
# Purpose : given a path, default is current working directory, find all files named .deb and highlight their name only
# Usage : make-ephemeral-swap.sh <DIR> <SIZE_IN_BYTES> <NUM_TO_MAKE>
#DEBUG=1

# Check options for overriding values
while getopts "d:s:n:" optionName
 do
        case "$optionName" in
		d) BASEDIR="${OPTARG}";;
		s) SIZE="${OPTARG}";;
		n) NUM="${OPTARG}";;
		[?]) PRINT_ERROR_HELP_AND_EXIT;;
	esac
done

if [ ! "${BASEDIR}" ]; then BASEDIR="/mnt/swapfiles"; fi
if [ ! "${NUM}" ]; then NUM=7; fi
if [ ! "${SIZE}" ]; then SIZE=10240000; fi

if [ ! -d "${BASEDIR}" ]
 then
  echo "Base dir ${BASEDIR} doesn't exist, creating"
  mkdir -p ${BASEDIR}
fi

MOUNT_POINT=$(df ${BASEDIR} | grep '^\/dev' | awk '{ print $6 }')
FREE_SPACE_MOUNT_POINT=$(df -k | grep ${MOUNT_POINT} | head -n 1 | awk '{ print $4 }')
let TOTAL_SPACE_NEEDED=(${NUM} * ${SIZE})
echo -n "${FREE_SPACE_MOUNT_POINT} free on ${MOUNT_POINT}"
echo " Need a total of ${TOTAL_SPACE_NEEDED}"

echo "${TOTAL_SPACE_NEEDED} -lt ${FREE_SPACE_MOUNT_POINT}"
if [ ${TOTAL_SPACE_NEEDED} -lt ${FREE_SPACE_MOUNT_POINT} ]
then
	if [ "${DEBUG}" ]; then echo "Have enough free space on ${MOUNT_POINT} for ${TOTAL_SPACE_NEEDED}"; fi
else
	echo "Not enough free space on base mount ${MOUNT_POINT}, exiting"
	exit 1
fi

echo "Started at `date`"

 for (( i = 1 ; i <= ${NUM}; i++ ))
 do
         if [ ! -f ${BASEDIR}/swap-1.img ]
         then
                 echo "Creating initial swapfile swap-${i}.img at `date`"
                 if [ "${DEBUG}" ]
                 then
			time dd if=/dev/zero of=${BASEDIR}/swap-${i}.img bs=1024 count=${SIZE}
                 else
			dd if=/dev/zero of=${BASEDIR}/swap-${i}.img bs=1024 count=${SIZE}
                 fi
                 chmod og-rwx ${BASEDIR}/swap-${i}.img
        #        echo "time dd if=/dev/zero of=${BASEDIR}/swap-${i}.img bs=1024 count=10240000"
                 mkswap -f ${BASEDIR}/swap-${i}.img
                 echo "${BASEDIR}/swap-${i}.img       none    swap    sw      0 0" >> /etc/fstab
                 if [ "${DEBUG}" ]; then echo "Created ${BASEDIR}/swap-${i}.img"; fi
         else
                 if [ "${DEBUG}" ]; then echo "Initial swapfile exists, not re-creating"; fi
         fi

         if [ ! -f ${BASEDIR}/swap-${i}.img ]
         then
                 if [ "${DEBUG}" ]; then echo "Creating swapfile swap-${i}.img at `date`"; fi
                 cp ${BASEDIR}/swap-1.img ${BASEDIR}/swap-${i}.img
                 chmod og-rwx ${BASEDIR}/swap-${i}.img
                 mkswap -f ${BASEDIR}/swap-${i}.img
                 echo "${BASEDIR}/swap-${i}.img       none    swap    sw      0 0" >> /etc/fstab
                 if [ "${DEBUG}" ]; then echo "Created ${BASEDIR}/swap-${i}.img"; fi
         else
                 if [ "${DEBUG}" ]; then echo "Swapfile ${BASEDIR}/swap-${i}.img already exists, skipping!"; fi
         fi
 done

if [ "${DEBUG}" ]; then echo "Done creating swapfiles at `date`, swapping on"; fi
swapon -a
if [ "${DEBUG}" ]; then echo "Done swapping on `date`, swapfile status :"; swapon -s; fi
