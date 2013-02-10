#!/usr/bin/python
#Author : jon@jonzobrist.com
#License : BSD/public/freeware

import smtplib
import sys

def prompt(prompt):
    return raw_input(prompt).strip()

fromaddr = "noreply@example.com"
#toaddrs = ['userA@example.com','userB@example.com','Phone1@txt.att.net','Phone2@txt.att.net','userC@example.com']
toaddrs = ['userA@example.com']
subject = "[ALERT] Alert from localhost"


msg = ("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n"
		 % (fromaddr,toaddrs,subject))
msg = msg + sys.argv[1]
server = smtplib.SMTP('server.ip.or.hostname')
#server.set_debuglevel(1)
server.sendmail(fromaddr, toaddrs, msg)
server.quit()

