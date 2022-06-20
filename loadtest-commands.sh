# Just some bash snippets for load testing different things

# x parallel (19k max), x^2 reqs
echo 'S="www.example.com"; export S' | tee -a env.sh
echo 'URI="/"; export URI' | tee -a env.sh
echo 'P="443"; export P' | tee -a env.sh
# URI="/images/test.png"
S="www.example.com"; export S
P="443"; export P
URI="/"; export URI
. ./env.sh; for x in {1000..100000..50}; do z=$((x*x)); date; if [ ${x} -gt 19000 ]; then C=19000; else C=${x}; fi; echo "Starting AB C ${C} N ${z} at $(date)"; ab -c ${C} -n ${z} https://${S}/${URI}; echo "Done at $(date)"; done | tee -a loadtest-${S}-$(date +%F-%s).log

# x parallel (19k max), x*100 reqs
. ./env.sh; for x in {1000..100000..50}; do z=$((x*100)); date; if [ ${x} -gt 19000 ]; then C=19000; else C=${x}; fi; echo "Starting AB C ${C} N ${z} at $(date)"; ab -c ${C} -n ${z} https://${S}/${URI}; echo "Done at $(date)"; done | tee -a loadtest-${S}-$(date +%F-%s).log

. ./env.sh; for x in {1..100}; do for y in {1..${x}}; do R=$((${RANDOM} % 109 + 1)); z=$((x*x*${R})); ab -c ${x} -n ${z} https://${S}/${URI}; done; done | tee -a ab-load-random-$(date +%F).log

; done | tee -a loadtest-${S}-$(date +%F-%s).log

# Bash function for getting each AB to start at slightly different times to avoid hitting the same instances
function randsleep() {
    if [ -z "${1}" ]
     then
        range=10
     else
        range=${1}
    fi
    R=$((${RANDOM} % ${range} + 1));
    sleep ${R}
}

# run this in tmux to run the same commands on all panes
set synchronize-panes off
set synchronize-panes on

# Make networking suck for all ports except SSH
sudo iptables -A INPUT -m statistic --mode random --probability 0.1 -p tcp ! --dport 22 -j DROP

# Make it suck bad for a specific container listener
sudo iptables -A INPUT -m statistic --mode random --probability 0.8 -p tcp ! --dport ${P} -j DROP

# Make it suck bad for a specific container listener

function choose() {
    R=$((${RANDOM} % 2))
}
sudo iptables -A INPUT -m statistic --mode random --probability 0.8 -p tcp ! --dport ${P} -j DROP

