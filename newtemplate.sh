#! /bin/sh

# Create mountpoint
zfs create -o mountpoint=/usr/local/jails zroot/jails
zfs create -p zroot/jails/template

# Copy pre-downloaded base files
scp -r "pi@freenas:/mnt/SSD_storage/jails/*.txz" /tmp

# Extract the files to the template location
tar -xf /tmp/base.txz -C /usr/local/jails/template
tar -xf /tmp/lib32.txz -C /usr/local/jails/template
tar -xf /tmp/ports.txz -C /usr/local/jails/template

# Copy files from host/hypervisor to template
cp /etc/resolv.conf /usr/local/jails/template/etc/resolv.conf
cp /etc/localtime /usr/local/jails/template/etc/localtime
mkdir -p /usr/local/jails/template/home/pi/.ssh
cp /home/pi/.ssh/authorized_keys /usr/local/jails/template/home/pi/.ssh

# Create the snapshot
zfs snapshot zroot/jails/template@1

# Copy the pre-configured jail.conf file
scp -r "pi@freenas:/mnt/SSD_storage/jails/jail.conf" /usr/local/jails/template/etc/

echo "Run the jails using jail -c jailname"
echo "View running jails with jls"
echo "Log into the jail using jexec jailname sh"
