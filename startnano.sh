#! /bin/sh
sh /usr/share/examples/bhyve/vmrun.sh -c 1 -m 4G -t tap0 -d /dev/zvol/zroot/nanovtest nanovtest
