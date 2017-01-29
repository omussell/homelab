#! /bin/sh
read -p "Enter hostname: " hostname
zfs create -V16G -o volmode=dev zroot/$hostname
sh /usr/share/examples/bhyve/vmrun.sh -c 1 -m 512M -t tap0 -d /dev/zvol/zroot/$hostname -i -I install.iso $hostname

