## Auto Remote Shell ##

What is this?
Auto remote shell is a simple set of tools to configure a Linux box to keep a shell open to a configured remote server. This is useful if you need to troubleshoot the Linux boxes of your friends and families, or for keeping devices in the field updated as they move about with varying connectivity.

### Notes ###

This script assumes you use the same username on the target machine as the homebase server.
No warranty implied or otherwise should be assumed, this is open source software and you assume full responsibility for using it.
For my use I also setup NordVPN, PiHole (in Docker), and a remote Dynamic DNS using Amazon Route 53.
Having Dynamic DNS is nice, but this helps when the remote network doesn't allow ingress to the public IPs things egress as.

### Fast Setup on Raspberry Pi running Raspbian 11 (bullseye) ###
Not done yet
```
git clone https://github.com/jonzobrist/Bash-Admin-Scripts
cd Bash-Admin-Scripts/auto-remote-shell
./install.sh
```

### Configure ###
To set this up you need to:
1. Install the required dependencies / programs
1. Create the user
1. Configure SSH keys and access
1. Configure & install autossh script in watchdog

```
SSH_USER="ubuntu"
# This is the FQDN or IP of the place your SSH client will connect to
TARGET_SERVER="homebase.example.com"
# The remote port is what the shell will open a listener on
R_PORT="2222"
```

### Manual Setup on Generic Linux w/dpkg###

Walk through of the steps the install script tries to do

```
git clone https://github.com/jonzobrist/Bash-Admin-Scripts
cd Bash-Admin-Scripts/auto-remote-shell
sudo apt-get install autossh watchdog

sudo cp autossh_script /etc/watchdog.d/autossh_script
perl -pi -e "s/SSH_USER/${SSH_USER}/g" /etc/watchdog.d/autossh_script
perl -pi -e "s/TARGET_SERVER/${TARGET_SERVER}/g" /etc/watchdog.d/autossh_script
```

### Confirm your setup is working ###
With the above default / example settings you would do this to connect to your remote host
```
$ ssh homebase.example.com
homebase $ ssh -p 2222 localhost
```

