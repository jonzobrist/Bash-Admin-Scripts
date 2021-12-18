# This should be sourced before running docker pihole commands

declare -x WEB_PASS="UseARealPassword"

declare -x PI_BASE="${HOME}/pihole"
declare -x PI_LOG="${PI_BASE}/var-log-pihole:/var/log"
declare -x PI_ETC="${PI_BASE}/etc-pihole/:/etc/pihole"
declare -x PI_DNSM="${PI_BASE}/etc-dnsmasq.d:/etc/dnsmasq.d"
declare -x PI_LIGHTTPD="${PI_BASE}/etc-lighttpd:/etc/lighttpd"

declare -x VIRTUAL_HOST="myhost.local"
declare -x SERVER_PORT="8080"
declare -x M_DNS="127.0.0.1"
declare -x N_DNS="1.1.1.1"
declare -x TZ="US/Pacific"
declare -x IP_LOOKUP="$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')"
declare -x IP="${IP_LOOKUP}"
