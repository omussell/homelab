#! /bin/sh

# armitage
pkg -j armitage install -y git

pkg -j armitage install -y ansible

# wintermute
pkg -j wintermute install -y unbound
jexec wintermute echo "local_unbound_enable=\"YES\"" >> /etc/rc.conf
jexec wintermute service local_unbound onestart

pkg -j wintermute install -y isc-dhcp43-server
jexec wintermute cp /usr/local/etc/dhcpd.conf.sample /usr/local/etc/dhcpd.conf

jexec wintermute echo "ntpd_enable=\"YES\"" >> /etc/rc.conf
jexec wintermute service ntpd start

# neuromancer 
pkg -j neuromancer install -y unbound
jexec neuromancer echo "local_unbound_enable=\"YES\"" >> /etc/rc.conf
jexec neuromancer service local_unbound onestart

pkg -j neuromancer install -y isc-dhcp43-server
jexec neuromancer cp /usr/local/etc/dhcpd.conf.sample /usr/local/etc/dhcpd.conf

jexec neuromancer echo "ntpd_enable=\"YES\"" >> /etc/rc.conf
jexec neuromancer service ntpd start

# finn 
pkg -j finn install -y git

jexec finn echo "rpcbind_enable=\"YES\" >> /etc/rc.conf"
jexec finn echo "nfs_server_enable=\"YES\" >> /etc/rc.conf"
jexec finn echo "mountd_flags=\"-r\" >> /etc/rc.conf"
jexec finn service nfsd start


# hideo 
jexec hideo echo "syslogd_enable=\"YES\" >> /etc/rc.conf"
jexec hideo echo "syslogd_flags=\"-a armitage -v -v\" >> /etc/rc.conf"
jexec hideo touch /var/log/armitage.log

# maelcum 
jexec maelcum cp /etc/mail/access.sample /etc/mail/access
jexec maelcum echo "Connect\:armitage\tOK" >> /etc/mail/access

# case 

# molly 

jexec hideo service syslogd restart
jexec maelcum makemap hash /etc/mail/access < /etc/mail/access
jexec maelcum service sendmail restart

