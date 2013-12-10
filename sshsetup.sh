#!/usr/bin/perl
###############
## written by: Jon Zobrist <jon@jonzobrist.com>
## updated on 6.18.03
###############
# usage: run sshsetup.sh when you login, follow the instructions i gives
# this will start ssh-agent, and copy your current agent info to a file ($myfile)
# i put my myfile in ~/.ssh/myagent
# then put a line in your startup script (.bashrc or .bash_profile)
# like "source ~/.ssh/myagent"
# now every time you login it will connect you to your current ssh-agent
# I recommend highly using a password on your private key file
###############
#
# here's a quick how to run down of how to use ssh-agent and public/private keys
# for ssh
# first create your private/public keys, run "ssh-keygen -t dsa" as the user you
# want to create keys for
# store them in your home directory under .ssh
# NEVER EVER EVER EVER give your private key (id_dsa) to anyone ever
# ALWAYS ALWAYS ALWAYS use a password for any key that will connect you to a
# box with root access, it's a good idea anyways
# Now, ssh into the box you want to setup passwordless ssh on
# edit ~/.ssh/authorized_keys
# copy and paste your public key into that file (hint: your public key is
# in ~/.ssh/id_dsa.pub if you followed ssh-keygen)
# make sure it's all on one line, and no new spaces/changes
# if it's the only key to be used you can just copy id_dsa.pub on your
# box to authorized_keys on the server box
# The one thing you may need to change is the hostname in the key, 
# especially if you're behind nat. This will need to be the IP/hostname of
# the box that the server will think you're conneting from.
# if you go through a NAT box it will be the external IP of the NAT box
# if you're a real host on the internet with working reverse dns then
# you're all set
# now you may need to edit the last


@myagent = `ssh-agent`;
$myfile = "$ENV{'HOME'}/.ssh/myagent";
$chmod_cmd = "/bin/chmod og-rwx";
$debug = 0;

open (MYFILE,">$myfile") || die "could not ompen myfile $myfile: $!\n";

print "ssh-agent started\nCopy and paste these lines into your terminal to run them:\n\n";

foreach $myline (@myagent) {
if ($myline =~ m/SSH_/) {
	print "$myline";
	print MYFILE "$myline";
	$hit = 1;
	} 
	else {
		if ($debug ) { print "BIG FAST MISS ON $myline\n"; }
	}
}

if (!$hit) {
	print "\n\n\#\#\#\#\#\#\#\nsomething bad happened\n\#\#\#\#\#\#\#\n";
}
else {
	print "\nthen run ssh-add to add your private key\n";
}
$my_chmod_cmd = "$chmod_cmd $myfile";
$result = system($my_chmod_cmd);
