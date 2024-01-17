After creating a proxmox VM based on the alpine-virt ISO, from the console:

```
apk add curl
wget raw.githubusercontent.com/omussell/homelab/master/alpine/standard.cfg
setup-alpine -f standard.cfg
```

It will prompt for root password either leave blank or set as something basic
Might prompt to overwrite sda disk, if so then yes
Reboot

Should create oem user with your github ssh keys
