#! /bin/sh
for jail in `cat ~/jails/listofjails.txt`
do
	echo "ansible:::::::::password" > /usr/local/jails/$jail/root/ansibleuser
	jexec $jail adduser -f /root/ansibleuser
	jexec $jail su -m ansible -c 'ssh-keygen -N "" -f /home/ansible/.ssh/id_rsa'
	rm /usr/local/jails/$jail/root/ansibleuser
done
