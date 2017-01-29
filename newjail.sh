#!/bin/sh
read -p "Enter jail name:" hostname
zfs clone zroot/jails/template@1 zroot/jails/$hostname
echo hostname=\"$hostname\" > /usr/local/jails/$hostname/etc/rc.conf

# Disable sendmail to speed up start time
echo sendmail_submit_enable=\"NO\" >> /usr/local/jails/$hostname/etc/rc.conf
echo sendmail_outbound_enable=\"NO\" >> /usr/local/jails/$hostname/etc/rc.conf
echo sendmail_msp_queue_enable=\"NO\" >> /usr/local/jails/$hostname/etc/rc.conf

