#!/bin/bash
#
# upload_ssh_keys_to_ec2.sh
# Uploads public ssh keys to EC2 in all regions
# Usage: upload_ssh_keys_to_ec2.sh <keyname> <keyfile>
# 

aws=$(which aws)

if [ "${1}" ] && [ -f "${2}" ] && [ -x "${aws}" ]
 then
    regions=$(aws ec2 describe-regions --output text --query 'Regions[*].RegionName') 
    if [ "${regions}" ]
     then
        echo "Uploading SSH key ${2} as keyname ${1} to all regions"
        for r in $(echo $regions)
         do
            echo $r
            ${aws} ec2 import-key-pair --region ${r} --key-name ${1} --public-key-material "file://${2}"
        done
    else
        echo "Failed to get regions, exiting at $(date)"
        exit 1
    fi
else
    echo "Usage ${0} keyname keyfile"
    exit 1
fi

