After creating a proxmox VM based on the alpine-virt ISO, from the console:

```
setup-alpine -q # press enter once should be enough to get internet
wget raw.githubusercontent.com/omussell/homelab/master/alpine/standard.cfg
setup-alpine -f standard.cfg
```

It will prompt for root password either leave blank or set as something basic
Might prompt to overwrite sda disk, if so then yes
Poweroff
Remove ISO disk
Poweron

Set hostname

Should create oem user with your github ssh keys
