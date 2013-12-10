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
#
# Author : Jon Zobrist <jon@jonzobrist.com>
# Homepage : http://www.jonzobrist.com
# License : BSD http://en.wikipedia.org/wiki/BSD_license
# Copyright (c) 2013, Jon Zobrist
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
# Purpose : This script uses the s3ls command to list all files in a bucket, root dir
# Usage : gather-public-ssh-keys.sh [Directory]


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
