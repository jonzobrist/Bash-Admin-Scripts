
function try_get_old {
        FILE=$1
        URL=$2
        TRIES=$3
        I=0
        if [ -z ${TRIES} ] || [ ${TRIES} -eq 0 ]; then TRIES=3; fi
        while [ ! -f ${FILE} ]
         do
                curl -s -o ${FILE} ${URL}
                let "SLEEP_TIME = ${I} * ${I}"
                sleep ${SLEEP_TIME}
                ((I++))
        done
}



function try_get {
	# Bash download file via curl w/retry, exponential back off, and error handling
        FILE=$1
        URL=$2
        TRIES=$3
        I=0
        if [ -z ${TRIES} ] || [ ${TRIES} -eq 0 ]; then TRIES=3; fi
        while [ ! -f ${FILE} ]
         do
                let "SLEEP_TIME = ${I} * ${I}"
                sleep ${SLEEP_TIME}
                RESP=$(curl -s -w '%{http_code}\n' -o ${FILE} ${URL})
                if [ ${RESP} -ne 200 ]
                 then
                        if [ "${DEBUG}" ]; then echo "Failed, HTTP ${RESP}, deleting file"; fi
                        /bin/rm ${FILE}
                else
                        if [ "${DEBUG}" ]; then echo "Return code was ${RESP}"; fi
                        echo "Got ${FILE} from ${URL}"
                fi
                ((I++))
        done
}
