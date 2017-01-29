#! /bin/sh
read -p " Enter hostname: " hostname
sh /usr/share/examples/bhyve/vmrun.sh -c 1 -m 512M -t tap0 -d /dev/zvol/zroot/$hostname $hostname
