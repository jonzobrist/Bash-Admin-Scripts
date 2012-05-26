#!/bin/bash
echo "${0} called with ${@}" >> /var/log/bluesun-setup-init.log 2>&1
case "${1}" in
	start)
		/etc/init.d/bluesun-setup.sh start 2>&1 >> /var/log/bluesun-setup-start.log 2>&1
	;;
	stop)
		/etc/init.d/bluesun-setup.sh stop 2>&1 >> /var/log/bluesun-setup-stop.log 2>&1
	;;
	*)
		echo "/etc/init.d/bluesun-setup.sh start 2>&1 >> /var/log/bluesun-setup-wildcard.log 2>&1"
	;;
esac
