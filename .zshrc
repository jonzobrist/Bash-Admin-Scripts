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
##################################
# .zshrc is sourced in interactive shells.
# It should contain commands to set up aliases,
# functions, options, key bindings, etc.
#
# To get this working to the max do these steps after installing ZSH
#
# Put this file (.zshrc) in your home dir
# $ curl -o ${HOME}/.zshrc https://raw.githubusercontent.com/jonzobrist/Bash-Admin-Scripts/master/.zshrc
# Setup zpresto from https://github.com/sorin-ionescu/prezto
# $ git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
# $ setopt EXTENDED_GLOB
# $ for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
# $   ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
# $ done
#
# Now change your default shell to zsh
# $ chsh -s `which zsh`
# Now logout and back in
##################################

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi
UNAME=$(uname)

# HISTORY settings
setopt EXTENDED_HISTORY        # store time in history
setopt HIST_EXPIRE_DUPS_FIRST  # unique events are more usefull to me
setopt HIST_VERIFY             # Make those history commands nice
setopt INC_APPEND_HISTORY      # immediatly insert history into history file
HISTSIZE=160000                # spots for duplicates/uniques
SAVEHIST=150000                # unique events guaranteed
HISTFILE=~/.history

autoload -U compinit
compinit
bindkey    "^[[3~"          delete-char
bindkey "^[OH" beginning-of-line
bindkey "^[OF" end-of-line
bindkey "^H" backward-delete-word

#allow tab completion in the middle of a word
setopt COMPLETE_IN_WORD

#Fix zsh being stupid and not printing lines without newlines
setopt nopromptcr

## keep background processes at full speed
setopt NOBGNICE
## restart running processes on exit
#setopt HUP

## never ever beep ever
setopt NO_BEEP

## disable mail checking
MAILCHECK=0

autoload -U colors

# I really hate when BSD vs. *Nix (Linux)
# Crap like this comes up, c'mon guys
# let's all MD5 the *right* way
if [ "${UNAME}" = "Darwin" ]
 then
    alias md5sum='md5 -r '
fi

jitter() {
    unset J1
    J1=${RANDOM}
    unset J2
    J2=${RANDOM}
    unset M1
    M1=$(echo "${J1} * ${J2}" | bc)
    JIT=$(echo "${M1} % 10 * .1" | bc)
    echo "${JIT}"
}

retry() {
    i=1
    mi=60
    while true
     do
        if [ "${DEBUG}" ]; then echo "trying $@ at `date` [attempt: ${i}]"; fi
        $@
        let "sleep_time = ${i} * ${i}"
        echo "sleeping ${sleep_time}"
        sleep ${sleep_time}
        sleep $(jitter)
        if [ ${i} -gt ${mi} ]; then i=1; fi
        ((i++))
    done
}

# System aliases
alias sshrm="ssh-keygen -R "
alias lsort="sort | uniq -c | sort -n"
alias auxyul="retry ssh ${yul}"
alias ll='ls -FAlh'
alias l='ls -FAlh'
alias lg='ls -FAlh | grep -i '
alias lh='ls -FAlht | head -n 20 '
alias grep="grep --color=auto"
alias gvg=" grep -v 'grep' "
alias ducks='du -chs * | sort -rn | head'
alias duckx='du -chsx * | sort -rn | head'
pskill() {
   ps -efl | grep $1 | grep -v grep | awk '{print $4}' | paste -sd " "
}

# Net aliases
alias p6='ping -c 6 -W 100 '
alias ra="dig +short -x "
alias ns="dig +short "
alias ds="dig +short "
alias wa="whois -h whois.arin.net "
alias tcurl='curl -w "%{remote_ip} time_namelookup: %{time_namelookup} tcp: %{time_connect} ssl:%{time_appconnect} start_transfer:%{time_starttransfer} total:%{time_total}\n" -sk -o /dev/null'
alias tcurlc='curl -w "%{remote_ip} time_namelookup: %{time_namelookup} tcp: %{time_connect} ssl:%{time_appconnect} start_transfer:%{time_starttransfer} total:%{time_total}\n" -sk -o /dev/null --cookie ${cookie} '
alias tcurlo='curl -w "%{remote_ip} time_namelookup: %{time_namelookup} tcp: %{time_connect} ssl:%{time_appconnect} start_transfer:%{time_starttransfer} total:%{time_total}\n" -sk '
alias tcurloc='curl -w "%{remote_ip} time_namelookup: %{time_namelookup} tcp: %{time_connect} ssl:%{time_appconnect} start_transfer:%{time_starttransfer} total:%{time_total}\n" -sk --cookie ${cookie} '
alias curlc='curl -skL --cookie ${cookie} '
alias watip="curl -s -X GET "https://www.dangfast.com/ip" -H  "accept: application/json" | jq -r '.origin'"
alias watproxyip="curl -s -X GET "http://www.dangfast.com/ip" -H  "accept: application/json" | jq -r '.origin'"
# Retry ssh as EC2 user! Get it!?
rse() {
    retry ssh ec2-user@${1}
}
# Retry ssh as Ubuntu user! Get it!?
# Also RSU = stocks = money
# This function is money
rsu() {
    retry ssh ubuntu@${1}
}

# Git aliases
alias gl='git lol'
alias gbl='git branch --list'

# Dev aliases
alias ipy="ipython -i ~/helpers.py"
nosetests () {
    ./runpy -m nose.core "$@" --verbose --nocapture
}

# Math aliases and functions
function is_int() { return $(test "$@" -eq "$@" > /dev/null 2>&1); }

autoload -U promptinit
promptinit
declare -x PATH="${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/sbin:/usr/sbin:/usr/local/sbin:${HOME}/.local/bin"

possible_path_dirs=("/usr/local/app1/bin" "${HOME}/app2/bin")
for path_dir in ${possible_path_dirs[@]}
 do
   if [ -d ${apollo_dir} ]; then
     declare -x PATH=$PATH:${apollo_dir}
   fi
done

# Workflow aliases & functions
alias quicklinks="cat ${HOME}/notes/quicklinks"
alias notes="cd ${HOME}/notes"
alias src="cd ${HOME}/src"
alias elbdate="date -u +%FT%H:%M:%SZ "
function get_dropped_hosts_dmesg() {
    for S in $(dmesg | grep DROPPED | awk '{ print $8, "\n", $9 }' | sed -e 's/ //g' | sed -e 's/DST=//' | sed -e 's/SRC=//' | sort | uniq); do echo $(dig +short -x ${S} | sed -e 's/\.$//'); done | sort | uniq
}

function get_dropped_hosts_kernlog() {
    for S in $(grep DROPPED /var/log/kern.log* | awk '{ print $13, "\n", $14 }' | sed -e 's/ //g' | sed -e 's/DST=//' | sed -e 's/SRC=//' | sort | uniq); do echo $(dig +short -x ${S} | sed -e 's/\.$//'); done | sort | uniq
}

# I keep my local ssh agent info in this file, and if it's there we should source it
if [ -f "${HOME}/.ssh/myagent" ]
then
    source ${HOME}/.ssh/myagent
fi

# Keep the HTTP address for my S3 bucket handy
declare -x ZS3="http://mybucket.s3-website-us-east-1.amazonaws.com"

# Common Iterables
UPPER="A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
lower="a b c d e f g h i j k l m n o p q r s t u v w x y z"
nums="0 1 2 3 4 5 6 7 8 9"
nums_and_such="0 1 2 3 4 5 6 7 8 9 - _"
hex_upper="0 1 2 3 4 5 6 7 8 9 A B C D E F"
HEX="0 1 2 3 4 5 6 7 8 9 A B C D E F"
hex="0 1 2 3 4 5 6 7 8 9 a b c d e f"
hour_list="00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23"

###################################################################
# TICKET WORKING ALIASES & FUNCTIONS
###################################################################
# We all work ticket like things, right?
# I like to keep information about specific tickets
# in the same place
# This brings consistency and I can later find information easily
# when looking for related info
# I also often backup this data to encrpyted S3 buckets
# these functions enable this type of workflow
function nott() {
	# TT = working ticket identifier, matches dir name
	# TD = working directory for that ticket, dir name matches ticket id/name
	unset TT
	unset TD
}

function tt() {
    # Function to jump into a working directory for $1 (${TT}) if it exists
    # If it doesn't exist, create it, and an env.sh file
    if [ "${TT}" ]
     then
        declare -x TD="${HOME}/work/${TT}"
     else
        declare -x TD="${HOME}/work/${1}"
        declare -x TT=${1}
    fi
    if [ ! -d "{TD}" ]
     then
        mkdir -p ${TD}
    fi
    ENV_FILE="${TD}/env.sh"
    if [ ! -f ${ENV_FILE} ]
     then
        echo "declare -x TT=\"${TT}\"" > ${ENV_FILE}
    fi
    if [ ! -x ${ENV_FILE} ]
     then
        chmod uog+x ${ENV_FILE}
    fi
    DEBUG "Changing dir to ~/${TD}. TT=${TT}"
    cd ${TD}
    . ${ENV_FILE}
}

# I frequently use the pattern of setting F to the current file
# (like a pointer)
# I'm working on, so these aliases let me do common things with
# the current file
#
# less the file, display it in my pager less
function lf() {
     if [ "${F} ]; then less ${F} 2>/dev/null
     elif [ "${1} ]; then less ${F} 2>/dev/null
     else echo "Usage lsf filename, or export F=filename"
     fi
}

# wireshark the file
# often times I'm doing tshark -nn -r ${F}
# so this makes it easy to jump into wireshark
function wf() {
     if [ "${F} ]; then wireshark ${F} 2>/dev/null &
     elif [ "${1} ]; then wireshark ${F} 2>/dev/null &
     else echo "Usage wf filename.pcap, or export F=filename.pcap"
     fi
}

function rtt() {
    # Function to 'return-to-ticket'
    # looks at only your env variable ${TT}
    # if it's set, it cd's to it
    if [ "${TT}" ] && [ -d ${TD} ]
     then
        cd "${TD}"
    else
        echo "No active work item"
    fi
}

###################################################################
# EC2 / AWS helper functions & aliases
###################################################################
#
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
  if [ "${UBU}" ]
   then
    case ${UBU} in
        12)
            UBUNTU="precise-12.04"
        ;;
        14)
            UBUNTU="trusty-14.04"
        ;;
        16)
            UBUNTU="xenial-16.04"
        ;;
        18)
            UBUNTU="bionic-18.04"
        ;;
        19)
            UBUNTU="disco-19.04"
        ;;
    esac
   else
        UBUNTU="bionic-18.04"
   fi
  if [ "${R}" ]
   then
    aws ec2 describe-images --owners 099720109477 --region ${R} --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-${UBUNTU}-amd64-server-????????" 'Name=state,Values=available' --output json | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId'
  else
    echo "Usage: ${0} region; or export R=region; ${0}"
  fi
}

S3_BACKUP_BUCKET="my-s3-bucket" # Obviously you should change this
function ttup() {
    # Given a work ticket (TT) you're working on, uploading to S3 bucket ${S3_BACKUP_BUCKET}
    # This uses aws s3 sync, which should de-dupe uploads
    # but will clobber objects
    # Useful if you want to work on a ticket in multiple places
    # or share data from a ticket with others
    # Dont' forget to enable encryption on the bucket!
    if [ ! "${TD}" ]
       then
        TD="${PWD##*/}"
    fi
    DEBUG "Backing up tt dir ${TT} at $(date)" | tee -a ~/tt-backup-$(date +%F).log
    sleep 1.5
    aws s3 sync ${TD} s3://${S3_BACKUP_BUCKET}/${TT}
}

function ttdown() {
    # Given a TT, download it to ${TD}
    if [ ! "${TT}" ]
       then
        TT="${PWD##*/}"
    fi
    DEBUG "Download tt dir ${TT} at $(date)" | tee -a ~/tt-download-$(date +%F).log
    sleep 1.5
    aws s3 sync s3://${S3_BACKUP_BUCKET}/${TT} ${TD}
}

function gt() {
    # gt = Get Ticket
    # Get a ticket directory from a host
    if [ ! "${1}" ] || [ ! -d "${TD}" ] || [ ! "${TT}" ]
     then
        echo "Get TT, Usage ${0} host"
	echo "Must have TD and TT envs set, and TD must be an existing directory"
    else
        TT="${PWD##*/}"
        S=${2}
        rsync -avz ${S}:${TD} ${TD}
    fi
}

function pt() {
    if [ ! "${1}" ] || [ ! -d "${TD}" ] || [ ! "${TT}" ]
     then
        echo "Push TT, Usage ${0} region"
	echo "Must have TD and TT envs set, and TD must be an existing directory"
    else
        rsync -avz ${TD} ${S}:${TD}
    fi
}

# I keep a list of regions in a local file
# This enables me to iterate easily over all AWS regions without calling the describe-regions API
update_ec2_regions() {
	MY_TMP_FILE=$(mktemp)
	aws ec2 describe-regions |grep 'RegionName' | awk -F'"' '{ print $4 }' | tee ${MY_TMP_FILE}
	OC=$(cat ~/regions-ec2 | wc -l | sed -e 's/ //g')
	NC=$(cat ${MY_TMP_FILE} | wc -l | sed -e 's/ //g')
	if (( ${NC} >= ${OC}))
	 then
		/bin/mv ${MY_TMP_FILE} ~/regions-ec2
	else
		echo "new file (${MY_TMP_FILE}) is not larger, did we lose regions?"
	fi
}

# I often find myself on remote systems with files
# that I want locally
# instead of figuring out the hostname or exiting and pasting
# things to make an scp command
# just use this (if you use real hostnames)
# example: you want to get http80.pcap
# ph http80.pcap
# This will print out "scp username@my-server-name:http80.pcap ./
# Which I can copy and paste easily
# I tried having it push the file, but prefer this way
# as often I can connect to a remote system, but it cannot connect to me
# ala NAT
ph() {
        FILE=$1
        if [ -f $(pwd)/${FILE} ]
         then
                echo "scp ${USER}@$(hostname):$(pwd)/${FILE} ./"
        elif [ -d ${FILE} ]
	 then
                echo "scp -r ${USER}@$(hostname):${FILE} ./${FILE}"
        else
                echo "scp -r ${USER}@$(hostname):$(pwd) ./"
        fi
}


# I often copy paths that I want to expore
# And a lot of the time the paths have a file at the end
# Some applications & computers handle this better than others
# But it's enough of a PITA that I use cdd <PASTE>
# Which looks to see if the thing I pasted is a file
# and cd's to its dirname if it is
#
function cdd() {
    if [ ! -f "{1}" ]
     then
        D=$(dirname ${1})
    else
        D="${1}"
    fi
    cd ${F}
}

# What is with Apple lately?
# I feel like OS X is now as reliable as Windows 98 at its peak
# This puts me into a VIM temp file that I can rant into
# and then :x and easily save these tirades
# it has never come to anything
# and I honestly thing Apple doesn't care anymore
# RIP Steve Jobs
function newcrash() {
    CRASH_DIR="${HOME}/mac-crashes-$(date +%Y)"
    if [ ! -d "{CRASH_DIR}" ]
     then
        mkdir -p ${CRASH_DIR}
    fi
    CRASH_FILE="mac-crash-ya-$(date +%F-%s).txt"
    vi ${CRASH_FILE}
}

# I like to leave old code around
# in case the new version turns on me while I'm sleeping
# function try_get {
#     FILE=$1
#     URL=$2
#     TRIES=$3
#     I=0
#     if [ -z ${TRIES} ] || [ ${TRIES} -eq 0 ]; then TRIES=3; fi
#     while [ ! -f ${FILE} ]
#      do
#         curl -s -o ${FILE} ${URL}
#         let "SLEEP_TIME = ${I} * ${I}"
#         sleep ${SLEEP_TIME}
#         ((I++))
#     done
# }

# Ever want to download something and NOT slip up and overwrite it
# while wildly CTRL+R'ing through your shell history?
# Also maybe you're cool and want to respect servers
# and try to get things with exponential backoff?
function try_get {
    URL=$1
    FILE=$2
    TRIES=$3
    START=$(date +%s)
    I=0
    if [ -z ${2} ]; then FILE_PREFIX=${URL##*/}; FILE=${FILE_PREFIX%%\?*}; fi
    if [ -z ${TRIES} ] || [ ${TRIES} -eq 0 ]; then TRIES=3; fi
    if [ "${DEBUG}" ]; then echo "Getting ${URL} to ${FILE} max ${TRIES} attempts at $(date)"; fi
    while [ ! -f ${FILE} ]
     do
        if [ "${DEBUG}" ]; then echo "calling curl for attempt ${I}"; fi
        CURL="curl -s -o ${FILE} ${URL}"
        if [ "${DEBUG}" ]; then echo "${CURL}"; fi
        ${CURL}
        RETURN=$?
        if [ "${DEBUG}" ]; then echo "Return code: ${RETURN}"; fi
        let "SLEEP_TIME = ${I} * ${I}"
        if [ "${DEBUG}" ]; then echo "sleeping ${SLEEP_TIME}"; fi
        sleep ${SLEEP_TIME}
        ((I++))
    done
    END=$(date +%s)
    let "ELAPSED_TIME = ${END} - ${START}"
    if [ ! ${RETURN} ]
     then
        echo "file exists"
        /bin/ls -hl ${FILE}
    elif [ ${RETURN} -gt 0 ]
     then
        echo "Failed to get ${FILE} from ${URL} after ${I} attempts and ${ELAPSED_TIME} seconds"
        cat ${FILE}
    else
        if [ "${DEBUG}" ]
         then
            echo "Got $(/bin/ls -1 ${FILE}) ${I} attempts after and ${ELAPSED_TIME} seconds"
        else
            echo "${FILE} ${I}"
        fi
    fi
}

# Ansible is a great way to easily control a bunch of hosts
# I put them in ~/hosts and use this to remote ssh to all of them
alias arun="ansible -m shell --user ubuntu --become -i ~/hosts -a "
alias arun2="ansible -m shell --user ec2-user --become -i ~/hosts -a "

# I often want to just have a specific string *highlighted*
# while preserving the original contents of a text file
# grepe string filename
# just like you would grep string filename, but with more file
function grepe {
    grep --color -E "$1|$" $2
}

# I often want to know the time in UTC vs Pacific
ddu() {
	if [ ${TZ} ]; then PTZ=${TZ}; else PTZ=":US/Pacific"; fi
	export TZ=":US/Pacific"
	echo "Pacific time: $(date)"
	export TZ=":UTC"
	echo "UTC: $(date)"
	export TZ=${PTZ}
}

# I often want to know the time in Pacific vs Eastern
edu() {
  if [ ${TZ} ]; then PTZ=${TZ}; else PTZ=":US/Pacific"; fi
  export TZ=":US/Pacific"
  echo "Pacific time: $(date)"
  export TZ=":US/Eastern"
  echo "Eastern time: $(date)"
  export TZ=${PTZ}
}

# Print current date in MY time format rounded to an hour
# YYYY-MM-DDTHH:00:00Z
# I use this for getting things like dates for metric analysis
my-time() {
	echo "NOW $(date +%FT%H:00:00Z)"
    echo "24HR AGO $(date +%FT%H:00:00Z)"
}

# This makes the left side of your command prompt so much cleaner
function collapse_pwd {
    echo $(pwd | sed -e "s,^$HOME,~,")
}

# Everyone loves PRINT (errrr echo) statements right!
# I do
# I love DEBUG variables even more though
# and with this I can use this in my bash scripts like:
# DEBUG "this process just did something I really cared about when I was writing the code at $(date) on $(hostname)"
# and not be bugged by it after I'm less interested
function DEBUG() {
    if [ "${DEBUG}" ]
     then
        echo "${1}"
    fi
}

function used_mem() {
    # This function reports the anon allocated memory
    # Interesting because this is used by #@%REDACTED#@#@%@#
    # Use like this to monitor % used memory
    # while true; do echo "$(date) $(used_anon_mem)%"; sleep .1; done
    MEM_TOT=$(grep MemTotal /proc/meminfo | awk '{ print $2 }')
    MEM_FREE=$(grep MemFree /proc/meminfo | awk '{ print $2 }')
    COMMIT_MEM=$(grep Committed_AS /proc/meminfo | awk '{ print $2 }')
    ANON_MEM=$(grep AnonPages  /proc/meminfo | awk '{ print $2 }')
    ANON_USED_PERCENT=$(echo "scale=2; (${ANON_MEM} / ${MEM_TOT}) * 100" | bc -l)
    COMMIT_USED_PERCENT=$(echo "scale=2; (${COMMIT_MEM} / ${MEM_TOT}) * 100" | bc -l)
    echo "Mem Anon: ${ANON_USED_PERCENT}%, Commit ${COMMIT_USED_PERCENT}%, ${MEM_FREE} free of ${MEM_TOT} Total"
}

function used_anon_mem() {
    # This function reports the anon allocated memory
    # Interesting because this is used by #@%REDACTED#@#@%@#
    # Use like this to monitor % used memory
    # while true; do echo "$(date) $(used_anon_mem)%"; sleep .1; done
    MEM_TOT=$(grep MemTotal /proc/meminfo | awk '{ print $2 }')
    ANON_MEM=$(grep AnonPages  /proc/meminfo | awk '{ print $2 }')
    USED_PERCENT=$(echo "scale=2; (${ANON_MEM} / ${MEM_TOT}) * 100" | bc -l)
    echo ${USED_PERCENT}
}

function aws_random_subnet() {
    # Cuz' sometimes you just need a subnet...
    # This works with your AWS CLI, needs to be setup and all that
    # given region ${1} or ${R} or none
    # describe VPC subnets, sort random, pick 1
    if [ "${1}" ]
     then
        MY_REGION=${1}
    elif [ "${R}" ]
     then
        MY_REGION=${R}
    fi
    if [ "${MY_REGION}" ]
     then
        MY_SUBNET=$(aws ec2 describe-subnets --region ${MY_REGION}  | jq -r '.Subnets[].SubnetId' | sort -r | head -n 1)
    else
        MY_SUBNET=$(aws ec2 describe-subnets | jq -r '.Subnets[].SubnetId' | sort -r | head -n 1)
    fi
    echo "${MY_SUBNET}"
}

# global ZSH aliases
# SUS - get top 25 of whatever with counts
alias -g SUS=" | sort | uniq -c | sort -nr | head -n 25"
# More from  https://grml.org/zsh/zsh-lovers.html
# alias -g ...='../..'
# alias -g ....='../../..'
# alias -g .....='../../../..'
# alias -g CA="2>&1 | cat -A"
# alias -g C='| wc -l'
# alias -g D="DISPLAY=:0.0"
# alias -g DN=/dev/null
# alias -g ED="export DISPLAY=:0.0"
# alias -g EG='|& egrep'
# alias -g EH='|& head'
# alias -g EL='|& less'
# alias -g ELS='|& less -S'
# alias -g ETL='|& tail -20'
# alias -g ET='|& tail'
# alias -g F=' | fmt -'
# alias -g G='| egrep'
# alias -g H='| head'
# alias -g HL='|& head -20'
# alias -g Sk="*~(*.bz2|*.gz|*.tgz|*.zip|*.z)"
# alias -g LL="2>&1 | less"
# alias -g L="| less"
# alias -g LS='| less -S'
# alias -g MM='| most'
# alias -g M='| more'
# alias -g NE="2> /dev/null"
# alias -g NS='| sort -n'
# alias -g NUL="> /dev/null 2>&1"
# alias -g PIPE='|'
# alias -g R=' > /c/aaa/tee.txt '
# alias -g RNS='| sort -nr'
# alias -g S='| sort'
# alias -g TL='| tail -20'
# alias -g T='| tail'
# alias -g US='| sort -u'
# alias -g VM=/var/log/messages
# alias -g X0G='| xargs -0 egrep'
# alias -g X0='| xargs -0'
# alias -g XG='| xargs egrep'
# alias -g X='| xargs'


