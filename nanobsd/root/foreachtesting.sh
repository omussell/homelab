for jail in `cat ~/jails/listofjails.txt`
do
	zfs clone zroot/jails/template@1 zroot/jails/$jail
	echo hostname=$jail> /usr/local/jails/$jail/etc/rc.conf

# Disable sendmail to speed up start time
	echo sendmail_submit_enable=\"NO\" >> /usr/local/jails/$jail/etc/rc.conf
	echo sendmail_outbound_enable=\"NO\" >> /usr/local/jails/$jail/etc/rc.conf
	echo sendmail_msp_queue_enable=\"NO\" >> /usr/local/jails/$jail/etc/rc.conf

done