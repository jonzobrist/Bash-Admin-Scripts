#!/bin/bash
#
# Author : Jon Zobrist <jon@jonzobrist.com>
# Homepage : http://www.jonzobrist.com
# License : BSD http://en.wikipedia.org/wiki/BSD_license
# Copyright (c) 2012, Jon Zobrist
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
# Purpose : This script aims to gather all public ssh keys on a server and put them in a directory, with appropriate names
# Usage : gather-public-ssh-keys.sh [Directory]

# VARIABLES
#HOST_NAME=''
IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4/)
HOST_NAME="$(curl http://169.254.169.254/latest/user-data/ 2>&1 | grep HOST_NAME | awk '{ print $2 }').tiwipro.com"
echo "${HOST_NAME}"

# CONSTANT VARIABLES
ERROR='0'
ZABBIX_USER='administrator' #Make user with API access and put name here
ZABBIX_PASS='password' #Make user with API access and put password here
ZABBIX_SERVER='zabbix.example.com' #DNS or IP hostname of our Zabbix Server
API='https://zabbix.example.com/api_jsonrpc.php'
HOSTGROUPID=10 #What host group to create the server in
TEMPLATEID=10001 #What is the template ID that we want to assign to new Servers?


# Install zabbix-agent in case it's not already installed
apt-get install -y zabbix-agent

echo "Server=${ZABBIX_SERVER}" > /etc/zabbix/zabbix_agentd.conf
echo "Hostname=${HOST_NAME}" >> /etc/zabbix/zabbix_agentd.conf
echo "StartAgents=5" >> /etc/zabbix/zabbix_agentd.conf
echo "DebugLevel=3" >> /etc/zabbix/zabbix_agentd.conf
echo "PidFile=/var/run/zabbix-agent/zabbix_agentd.pid" >> /etc/zabbix/zabbix_agentd.conf
echo "LogFile=/var/log/zabbix-agent/zabbix_agentd.log" >> /etc/zabbix/zabbix_agentd.conf
echo "Timeout=3" >> /etc/zabbix/zabbix_agentd.conf

# stop zabbix agent
service zabbix-agent stop

# Authenticate with Zabbix API
authenticate() {
curl -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"params\": {\"password\": \"$ZABBIX_PASS\", \"user\": \"$ZABBIX_USER\"}, \"jsonrpc\":\"2.0\", \"method\": \"user.authenticate\",\"auth\": \"\", \"id\": 0}" $API | grep -Eo 'Set-Cookie: zbx_sessionid=.+' | head -n 1 | cut -d '=' -f 2 | tr -d '\r'
}
AUTH_TOKEN=$(authenticate)

# Create Host
create_host() {
  curl -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\",\"method\":\"host.create\",\"params\":{\"host\":\"$HOST_NAME\",\"ip\":\"$IP\",\"dns\":\"$HOST_NAME\",\"port\":10050,\"useip\":1,\"groups\":[{\"groupid\":$HOSTGROUPID}],\"templates\":[{\"templateid\":$TEMPLATEID}]},\"auth\":\"$AUTH_TOKEN\",\"id\":0}" $API
}
output=$(create_host)

echo $output | grep -q "hostids"
rc=$?
if [ $rc -ne 0 ]
 then
	echo -e "Error in adding host ${HOST_NAME} at `date`:\n"
	echo $output | grep -Po '"message":.*?[^\\]",'
	echo $output | grep -Po '"data":.*?[^\\]"'
	exit
else
	echo -e "\nHost ${HOST_NAME} added successfully, starting Zabbix Agent\n"
	# start zabbix agent
	service zabbix-agent start
	exit
fi

