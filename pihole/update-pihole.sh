#!/bin/bash
# This script updates a running pihole, but it can also start a new one
# Requires Docker to be installed (see install-docker.sh) and the current user to have permissions
# Also needs to listen on the port you configure, and the DNS ports (53 on TCP & UDP)
# Disable or stop any other DNS servers or caches before running / if it doens't work right
# Configure in env.sh or in this file

DEBUG () {
	if [ "${DEBUG}" ]
	then
		echo "${1}"
	fi
}

if [ -f "env.sh" ]
 then
    # shellcheck source=/dev/null
    source env.sh
 else
    WEB_PASS="tempRandom${RANDOM}"
    export WEB_PASS
    echo "Using random web password ${WEB_PASS}"
    PI_BASE="${PI_BASE:-$PWD}"
    export PI_BASE
    PI_LOG="${PI_BASE}/var-log-pihole:/var/log"
    export PI_LOG
    PI_ETC="${PI_BASE}/etc-pihole/:/etc/pihole"
    export PI_ETC
    PI_DNSM="${PI_BASE}/etc-dnsmasq.d:/etc/dnsmasq.d"
    export PI_DNSM
    PI_LIGHTTPD="${PI_BASE}/etc-lighttpd:/etc/lighttpd"
    export PI_LIGHTTPD
    IP_LOOKUP="$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')"
    export IP_LOOKUP
    IP="${IP:-$IP_LOOKUP}"
    export IP
    VIRTUAL_HOST="${VIRTUAL_HOST:-pihole.local}"
    export VIRTUAL_HOST
    SERVER_PORT="${SERVER_PORT:-8080}"
    export SERVER_PORT
    M_DNS="${M_DNS:-127.0.0.1}"
    export M_DNS
    N_DNS="${N_DNS:-1.1.1.1}"
    export N_DNS
    TZ="${TZ:-US/Pacific}"
    export TZ
    NET_TYPE="${NET_TYPE:-bridge}" # can change to host if you want to use pihole DHCP
    export NET_TYPE
fi


FORCE_UPDATE=${FORCE_UPDATE:-0}
export FORCE_UPDATE
UPDATE=0
export UPDATE

if [ -z "${IP}" ] || [ -z "${IP_LOOKUP}" ] || [ -z "${N_DNS}" ] || [ -z "${PI_BASE}" ] || [ -z "${PI_DNSM}" ] || [ -z "${PI_ETC}" ] || [ -z "${PI_LIGHTTPD}" ] || [ -z "${PI_LOG}" ] || [ -z "${SERVER_PORT}" ] || [ -z "${TZ}" ] || [ -z "${VIRTUAL_HOST}" ] || [ -z "${WEB_PASS}" ] || [ -z "${NET_TYPE}" ]

 then
    echo "Exiting, not all variables are set, check env.sh"
    DEBUG "Var IP = ${IP}"
    DEBUG "Var IP_LOOKUP = ${IP_LOOKUP}"
    DEBUG "Var N_DNS = ${N_DNS}"
    DEBUG "Var PI_BASE = ${PI_BASE}"
    DEBUG "Var PI_DNSM = ${PI_DNSM}"
    DEBUG "Var PI_ETC = ${PI_ETC}"
    DEBUG "Var PI_LIGHTTPD = ${PI_LIGHTTPD}"
    DEBUG "Var PI_LOG = ${PI_LOG}"
    DEBUG "Var SERVER_PORT = ${SERVER_PORT}"
    DEBUG "Var TZ = ${TZ}"
    DEBUG "Var VIRTUAL_HOST = ${VIRTUAL_HOST}"
    DEBUG "Var WEB_PASS = ${WEB_PASS}"
    DEBUG "Var NET_TYPE = ${NET_TYPE}"
    exit 1
else
    UPDATE_OUTPUT=$(docker pull pihole/pihole)
    RETCODE=$?
    DEBUG "UPDATE_OUTPUT:"
    DEBUG "${UPDATE_OUTPUT}"
    NO_UPDATE=$(echo "${UPDATE_OUTPUT}" | grep 'Image is up to date')
    DEBUG "Var NO_UPDATE = ${NO_UPDATE}"
    if [ ${RETCODE} -eq 0 ] && [ -z "${NO_UPDATE}" ]
     then
        UPDATE=1
        export UPDATE
    fi
    if [ "${FORCE_UPDATE}" -eq 1 ]
     then
        UPDATE=1
        export UPDATE
    fi
    if [ ${UPDATE} -eq 1 ]
     then
        DEBUG "Wipping pihole: docker rm -f pihole"
        # Note that this is a docker rm -f, not a filesystem rm
        docker rm -f pihole
        DEBUG "Running Pihole in Docker:"
        DEBUG "docker run -d --name pihole --hostname pihole --net=${NET_TYPE} -e TZ=\"${TZ}\" -e WEBPASSWORD=\"${WEB_PASS}\" -e IPV4_ADDRESS=\"${IP}\" -e VIRTUAL_HOST=\"${VIRTUAL_HOST}\" -e VIRTUAL_PORT=${SERVER_PORT} -v ${PI_ETC} -v ${PI_DNSM} -p 53:53/tcp -p 53:53/udp -p ${SERVER_PORT}:80 --dns=${M_DNS} --dns=${N_DNS} --restart=unless-stopped --cap-add=NET_ADMIN pihole/pihole:latest"
        docker run -d --name pihole --hostname pihole --net="${NET_TYPE}" -e TZ="${TZ}" -e WEBPASSWORD="${WEB_PASS}" -e IPV4_ADDRESS="${IP}" -e VIRTUAL_HOST="${VIRTUAL_HOST}" -e VIRTUAL_PORT="${SERVER_PORT}" -p 53:53/tcp -p 53:53/udp -p "${SERVER_PORT}:80" -v "${PI_ETC}" -v "${PI_DNSM}" --dns="${M_DNS}" --dns="${N_DNS}" --restart=unless-stopped --cap-add=NET_ADMIN pihole/pihole:latest

    else
        echo "Docker images not updated, skipping restart at $(date)"
    fi
fi

