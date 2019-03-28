##################################
# Author : Jon Zobrist <jon@jonzobrist.com>
# Homepage : http://www.jonzobrist.com
# License : BSD http://en.wikipedia.org/wiki/BSD_license
# Copyright (c) 2019, Jon Zobrist
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
# Purpose: Useful aliases for interacting with AWS from the CLI
#     Put into a .bashrc/aliases/.zshrc file, use from the command line
# Usage : varies
# Get Amazon Linux 2 latest AMI
#     get_am2_ami <region>
# Get Ubuntu 18.04 latest AMI
#     get_ubuntu_ami <region>
# Get a list of EC2 regions into a local regions-ec2 file (I'm lazy and use this file as a temp data store)
#     update_ec2_regions
##################################

function get_am2_ami() {
  # Searches for the latest Amazon Linux 2 x86 64-bit ami
  if [ "${1}" ] && [ ! "${R}" ]
   then
    R=${1}
  fi
  if [ "${R}" ]
   then
    aws ec2 describe-images --owners amazon --region ${R} --filters 'Name=name,Values=amzn2-ami-hvm-2.0.????????-x86_64-gp2' 'Name=state,Values=available' --output json | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId'
  else
    echo "Usage: ${0} region; or export R=region; ${0}"
  fi
}

function get_ubuntu_ami() {
  # Searches for the latest Amazon Linux 2 x86 64-bit ami
  if [ "${1}" ] && [ ! "${R}" ]
   then
    R=${1}
  fi
  if [ "${R}" ]
   then
    aws ec2 describe-images --owners 099720109477 --region ${R} --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-????????' 'Name=state,Values=available' --output json | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId'
  else
    echo "Usage: ${0} region; or export R=region; ${0}"
  fi
}

update_ec2_regions() {
        MY_TMP_FILE=$(mktemp)
	aws ec2 describe-regions --output json | jq -r '.Regions[].RegionName' > ${MY_TMP_FILE}
        OC=$(wc -l ~/regions-ec2 | awk '{ print $1 }')
        NC=$(wc -l ${MY_TMP_FILE} | awk '{ print $1 }')
        if (( ${NC} >= ${OC})) # We are assuming the number of regions will only go up,
                               # so let's ignore it if we somehow ended up with fewer regions than in the current file
         then
                /bin/mv ${MY_TMP_FILE} ~/regions-ec2
        else
                echo "new file (${MY_TMP_FILE}) is not larger, did we lose regions?"
        fi
}

