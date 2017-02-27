#! /bin/sh
set -ex

PM_HOSTNAME=wintermute
TEMP_FILE=~/cm_ip
NANO_TOOLS=/usr/src/tools/tools/nanobsd

# Generate known_hosts entry for Control Machine
ifconfig `ifconfig -l | awk '{print $1}'` | grep -w inet | cut -w -f3 > $TEMP_FILE && cat /etc/ssh/ssh_host_ed25519_key.pub >> $TEMP_FILE && cat $TEMP_FILE | tr "\n" " " | sed 's/root.*//' > $NANO_TOOLS/Files/etc/ssh/known_hosts && rm $TEMP_FILE

# Create temp user
echo "$PM_HOSTNAME-tempuser:::::::/grim/$PM_HOSTNAME::" > $NANO_TOOLS/tempuser.txt
adduser -f $NANO_TOOLS/tempuser.txt

# Generate SSH keys for temp user
su -l $PM_HOSTNAME-tempuser -c 'mkdir -p $HOME/crypto/ssh'
su -l $PM_HOSTNAME-tempuser -c 'mkdir -p $HOME/.ssh'
su -l $PM_HOSTNAME-tempuser -c 'ssh-keygen -f $HOME/crypto/ssh/id_ed25519 -t ed25519 -N "" -E sha256'

# Generate authorized_keys
cat /grim/$PM_HOSTNAME/crypto/ssh/id_ed25519.pub > /grim/$PM_HOSTNAME/crypto/ssh/authorized_keys
cat /home/ansible/.ssh/id_ed25519.pub >> /grim/$PM_HOSTNAME/crypto/ssh/authorized_keys
cat /grim/$PM_HOSTNAME/crypto/ssh/id_ed25519.pub >> /grim/$PM_HOSTNAME/.ssh/authorized_keys
chown $PM_HOSTNAME-tempuser /grim/$PM_HOSTNAME/.ssh/authorized_keys
chown $PM_HOSTNAME-tempuser /grim/$PM_HOSTNAME/crypto/ssh/authorized_keys

# Copy the authorized_keys to the image
cp -v /grim/$PM_HOSTNAME/crypto/ssh/authorized_keys $NANO_TOOLS/Files/root/.ssh

# Copy the tempuser private+public keys to the image
cp -v /grim/$PM_HOSTNAME/crypto/ssh/id_ed25519* $NANO_TOOLS/Files/root/.ssh

# Build the new image
$NANO_TOOLS/nanobuild.sh

# Start the vm
$NANO_TOOLS/startnano.sh
