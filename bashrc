# ~/.bashrc
# Author: Jon Zobrist <jon@jonzobrist.com>
# Date: 2018-05-11

# Path should prefer my ~/bin over all else
# WARNING: This makes it easy for someone with access to your bin folder to trick you into giving up your secrets

# Handy ls aliases
# so often i'm looking for a file in cwd, alias it!
# Usage: lg <pattern>
# shows files that match <pattern>
# note this includes file data so rwx would show files with rwx perms
alias lg='ls -halF | grep -i '
# looking for new files in a big directory
alias lh="ls -Falht | head -n 15"
# Make ll better
alias ll='ls -alF'


# ph: print hostname, path, file
# often I want to grab a file or directory when I'm working remote
# Usage: ph <filename|dirname>
# Output:
# scp -r <user>@<host>:<full-path>/<file>
#
# File example:
# ph capture-2018-05-10-1525911190.pcap.gz
# scp ubuntu@server1.example.com:/home/ubuntu/capture-2018-05-10-1525911190.pcap.gz ./
# Dir example:
# ph access-logs-2018-05-10
# scp -r ubuntu@server1.example.com:/home/ubuntu/access-logs-2018-05-10 ./
#
ph () {
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


# try_get: download file from url with exponential backoff and max tries
# Everyone knows retries should include exponential backoff
# Now everyone has an alias for it!
# Usage: try_get <url> [output-filename] [attempts]

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


# from https://www.networkworld.com/article/2694433/unix-good-coding-practices-for-bash.html
function lower()
{
    local str="$@"
    local output
    output=$(tr '[A-Z]' '[a-z]'<<<"${str}")
    echo $output
}


