#!/usr/bin/env bash

### Configure ###
# Overview
# 1. Install the required dependencies / programs
# 2. Create the user
# 3. Configure SSH keys and access
# 4. Configure & install autossh script in watchdog


# 1. Install the required dependencies / programs
sudo apt-get -y install autossh watchdog

# 2. Create the user if they don't exist
R_USER="ubuntu"
R_PORT="2222"
AUTO_SSH_SCRIPT="/etc/watchdog.d/autossh_script"

if id "$R_USER" &>/dev/null; then
    echo 'user ${R_USER} already exists, not creating at $(date)'
else
    echo 'user ${R_USER} does not exists, creating at $(date)'
    useradd -D ${R_USER}
fi

# now that the user was created, we get the path to their home dir
USER_HOME=$(eval echo "~${R_USER}"
if [ ! -d  ${USER_HOME} ]
then
    echo "defaults did not create user dir at ${USER_HOME}, making one from /etc/skel"
    cp -R /etc/skel ${USER_HOME}
    chown -R ${R_USER}:${R_USER} ${USER_HOME}
else
    # If you're having problems and you saw this on first run, check it's permissions, other users don't need access to it
    echo "User ssh dir exists at $(date)"
fi

# Maybe we shouldn't do this, as it should be created by ssh-keygen?
USER_SSH_DIR="${USER_HOME}/.ssh"
if [ ! -d  ${USER_SSH_DIR} ]
then
    echo "User ssh dir does not exist, creating at $(date)"
    sudo mkdir -p ${USER_SSH_DIR}
    sudo chown -R ${R_USER}:${R_USER} ${USER_SSH_DIR}
    sudo chmod -R og-rwx ${USER_SSH_DIR}
else
    echo "User ssh dir exists, not creating at $(date)"
fi

# 3. Configure SSH keys and access
USER_SSH_SKEY="${USER_SSH_DIR}/id_rsa"
USER_SSH_PKEY="${USER_SSH_DIR}/id_rsa.pub"
if [ ! -e ${USER_SSH_SKEY} ] && [ ! -e ${USER_SSH_PKEY} ] && [ -d ${USER_SSH_DIR} ]
then
    echo "User does not have SSH keys at $(date)"
    # related: https://unix.stackexchange.com/questions/69314/automated-ssh-keygen-without-passphrase-how#69318
    # ssh-keygen -b 2048 -t rsa -f /tmp/sshkey -q -N ""
    # pr1="sudo -u user ssh-keygen -t rsa -N '' <<<''; echo '$ID' | sudo -u user tee -a ~user/.ssh/authorized_keys"
    sudo -u ${R_USER} ssh-keygen -t rsa -N '' <<<''
else
    echo "User ${R_USER} has SSH public and private keys at $(date)"
fi
# Dump the public key to variable ${ID} for later use
ID=$(cat ${USER_SSH_DIR}/id_rsa.pub)

# 4. Configure & install autossh script in watchdog
echo "Changing the SSH_USER place holder text in the autossh script"
sudo perl -pi -e "s/SSH_USER/${SSH_USER}/g" 
# change the TARGET_SERVER place holder text in the autossh script
sudo perl -pi -e "s/TARGET_SERVER/${TARGET_SERVER}/g" /etc/watchdog.d/autossh_script

# 5. Check everything looks right & restart
# validate


# start/restart


# 5. Print what they need to do on target server
echo "Done here, everything looks good. Now you need to go to your remote server and make sure the key is in the target user's authorized_keys file"
echo "Target server is ${TARGET_SERVER}"
echo "User on target server is ${R_USER}"
echo "They need the next line in their ~/.ssh/authorized_keys file (~ means home dir of the user, like ~${R_USER}"
echo "ID line to add to authorized_keys:"
echo ${ID}
echo "the file needs to be owned and readable by them, and nobody else, if problems try:"
echo "sudo chown -R ${R_USER}:${R_USER} ${USER_SSH_DIR}"
echo "sudo chmod u+rwx,og-rwx -R ${USER_SSH_DIR}"
echo "sudo find ${USER_SSH_DIR} -type f -exec chmod u+rw,og-rwx {}\;"


# 7. Profit!
echo "Shold be done now, try to ssh to ${TARGET_SERVER} and the from there ssh to port ${R_PORT} on localhost, e.g.:"
echo "ssh -t ${TARGET_SERVER} \"ssh -t -p ${R_PORT} localhost\""
