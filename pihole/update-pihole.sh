#!/bin/bash
DEBUG () {
	if [ "${DEBUG}" ]
	then
		echo "${1}"
	fi
}

if [ -f "env.sh" ]
 then
    source env.sh
 else
    declare -x WEB_PASS="tempRandom${RANDOM}"
    echo "Using random web password ${WEB_PASS}"
    declare -x PI_BASE="${PI_BASE:-$PWD}"
    declare -x PI_LOG="${PI_BASE}/var-log-pihole:/var/log"
    declare -x PI_ETC="${PI_BASE}/etc-pihole/:/etc/pihole"
    declare -x PI_DNSM="${PI_BASE}/etc-dnsmasq.d:/etc/dnsmasq.d"
    declare -x PI_LIGHTTPD="${PI_BASE}/etc-lighttpd:/etc/lighttpd"
    declare -x IP_LOOKUP="$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')"
    declare -x IP="${IP:-$IP_LOOKUP}"
    declare -x VIRTUAL_HOST="${VIRTUAL_HOST:-taco.zlyxy.me}"
    declare -x SERVER_PORT="${SERVER_PORT:-80}"
    declare -x M_DNS="${M_DNS:-127.0.0.1}"
    declare -x N_DNS="${N_DNS:-1.1.1.1}"
    declare -x TZ="${TZ:-US/Pacific}"
fi

if [ -z ${IP} ] || [ -z ${IP_LOOKUP} ] || [ -z ${N_DNS} ] || [ -z ${PI_BASE} ] || [ -z ${PI_DNSM} ] || [ -z ${PI_ETC} ] || [ -z ${PI_LIGHTTPD} ] || [ -z ${PI_LOG} ] || [ -z ${SERVER_PORT} ] || [ -z ${TZ} ] || [ -z ${VIRTUAL_HOST} ] || [ -z ${WEB_PASS} ]
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
    exit 1
else
    UPDATE_OUTPUT=$(docker pull pihole/pihole)
    RETCODE=$?
    DEBUG "UPDATE_OUTPUT:"
    DEBUG "${UPDATE_OUTPUT}"
    NO_UPDATE=$(echo ${UPDATE_OUTPUT} | grep 'Image is up to date')
    DEBUG "Var NO_UPDATE = ${NO_UPDATE}"
    if [ ${RETCODE} == 0 ] && [ -z "${NO_UPDATE}" ]
     then
        docker rm -f pihole
        docker run -d --name pihole --hostname taco --net=host -e TZ="${TZ}" -e WEBPASSWORD="${WEB_PASS}" -e IPV4_ADDRESS="${IP}" -e VIRTUAL_HOST="${VIRTUAL_HOST}" -v ${PI_ETC} -v ${PI_DNSM} --dns=${M_DNS} --dns=${N_DNS} --restart=unless-stopped --cap-add=NET_ADMIN pihole/pihole:latest
    else
        echo "Docker images not updated, skipping restart at $(date)"
    fi
fi
