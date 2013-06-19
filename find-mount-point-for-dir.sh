#!/bin/bash
#DEBUG=1

if [ "${1}" ]
then
    DIR="${1}"
    MOUNT_POINT="$(df ${DIR} | grep '^\/dev' | awk '{ print $6 }')"
    if [ "${DEBUG}" ]
    then
        echo "${DIR} is mounted on ${MOUNT_POINT}"
    else
        echo "${MOUNT_POINT}"
    fi
else
    echo "Usage ${0} <dir|file>"
fi
