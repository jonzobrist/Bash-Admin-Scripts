#!/usr/bin/env bash
# Pulls latest pihole scripts and starts
# Requires you have docker running already, and you're using a linux host

# Get the env.sh, and source it
TF=$(mktemp)
curl -o ${TF} https://raw.githubusercontent.com/jonzobrist/Bash-Admin-Scripts/master/pihole/env.sh
perl -pi -e "s/pihole.local/$(hostname)/g" ${TF}
. ${TF}
mkdir -p ${PI_BASE}
pushd ${PI_BASE} 
mv ${TF} ./env.sh

curl -O https://raw.githubusercontent.com/jonzobrist/Bash-Admin-Scripts/master/pihole/update-pihole.sh
chmod uog+x update-pihole.sh

# This takes the output of your local hostname command and replaces all pihole.local in the env.sh
./update-pihole.sh

popd

