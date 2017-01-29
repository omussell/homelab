echo "net.link.tap.up_on_open=1" >> /etc/sysctl.conf
echo "vmm_load=\"YES\"" >> /boot/loader.conf
echo "nmdm_load=\"YES\"" >> /boot/loader.conf
echo "if_bridge_load=\"YES\"" >> /boot/loader.conf
echo "if_tap_load=\"YES\"" >> /boot/loader.conf
echo "cloned_interfaces=\"bridge0 tap0\"" >> /etc/rc.conf
echo "ifconfig_bridge0=addm re0 addm tap0" >> /etc/rc.conf
