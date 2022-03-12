## Dynamic DNS with Amazon Route 53 in Bash/command line ##

### Purpose : This script aims to provide dynamic DNS names using Amazon Route 53 ###

It attempts to detected your public IP, track if it has changed, and update it in Route 53
### Requires: ###
aws command (awscli) - https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
curl - https://curl.se/download.html
And egrep, dig or nslookup

### Setup: ###
Mark script executable, put where you want it, for me that's usually ${HOME}/bin/ (aka ~/bin), and the conf and template json in ${HOME}/etc/.

```
chmod uog+x update-dns-external.sh
mkdir -p ${HOME}/bin/
cp update-dns-external.sh ${HOME}/bin/
mkdir -p ${HOME}/etc/
cp update-dns-external.conf ${HOME}/etc/
cp external.json ${HOME}/etc/
crontab -l > ${HOME}/cron
mkdir -p ${HOME}/logs/
echo "*/15 * * * * ${HOME}/bin/update-dns-external.sh >> ${HOME}/logs/dns-external.log" >> ${HOME}/cron
crontab ${HOME}/cron
```

Edit config file, or script to taste. You will need a working AWS account, to know your Route 53 hosted zone ID, change the aws CLI profile if you aren't using default.

```
aws route53 list-resource-record-sets --hosted-zone-id AWSHOSTEDZONEID --query "ResourceRecordSets[?Name == 'www.example.com.'].ResourceRecords[].Value" --output text
```

Usage : update-dns-external.sh
Typically from crontab something like

```
*/15 * * * * /home/ubuntu/bin/update-dns-external.sh >> ${HOME}/logs/dns-external.log
```

