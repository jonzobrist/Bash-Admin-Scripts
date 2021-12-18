# This should be sourced before running docker pihole commands

declare -x WEB_PASS="UseARealPassword${RANDOM}"

declare -x PI_BASE="${HOME}/pihole"
declare -x PI_LOG="${PI_BASE}/var-log-pihole:/var/log"
declare -x PI_ETC="${PI_BASE}/etc-pihole/:/etc/pihole"
declare -x PI_DNSM="${PI_BASE}/etc-dnsmasq.d:/etc/dnsmasq.d"
declare -x PI_LIGHTTPD="${PI_BASE}/etc-lighttpd:/etc/lighttpd"

declare -x VIRTUAL_HOST="pihole.local"
declare -x SERVER_PORT="8080"
declare -x M_DNS="127.0.0.1"
declare -x N_DNS="1.1.1.1"
declare -x TZ="US/Pacific"
declare -x IP_LOOKUP="$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')"
declare -x IP="${IP_LOOKUP}"

# declare -x IP="192.168.1.254" #Or set it statically
# declare -x IPV4_ADDRESS="192.168.1.254" #Override IPv4 manually
# declare -x IPV6_ADDRESS="::" #Override IPv6 manually

declare -x NET_TYPE="bridge" # can change to host if you want to use pihole DHCP
