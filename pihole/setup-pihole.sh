#!/usr/bin/env bash
# Pulls latest pihole scripts and starts

curl -O https://raw.githubusercontent.com/jonzobrist/Bash-Admin-Scripts/master/pihole/update-pihole.sh
curl -O https://raw.githubusercontent.com/jonzobrist/Bash-Admin-Scripts/master/pihole/env.sh
chmod uog+x update-pihole.sh
perl -pi -e "s/pihole.local/$(hostname)/g" env.sh
./update-pihole.sh
