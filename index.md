Homelab
=======

###Bootstrapping a Secure Infrastructure###

- [Overview](/homelab/design/overview.html)
- [Design](/homelab/design/design.html)
- [Implementation](/homelab/design/implementation.html)


Hardware
--------

    Virtualisation Host
    Gigabyte Brix Pro GB-BXI7-4770R
    - Intel Core i7-4770R (quad core 3.2GHz)
    - 16GB RAM
    - 250GB mSATA SSD
    - 250GB 2.5 inch SSD

    NAS
    HP ProLiant G8 Microserver G1610T
    - Intel Celeron G1610T (dual core 2.3 GHz)
    - 16GB RAM
    - 2 x 250GB SSD
    - 2 x 3TB HDD

    Management
    Raspberry Pi 2 Model B
    - Quad core 1GB RAM
    - 8GB MicroSD (w/ NOOBS)

Automating FreeBSD Jail Creation
--------------------------------

    Creating the template:
    zfs create -o mountpoint=/usr/local/jails zroot/jails
    zfs create -p zroot/jails/template

    Download the base files into a new directory
    mkdir ~/jails
    fetch ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/10.2-RELEASE/base.txz -o ~/jails
    fetch ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/10.2-RELEASE/lib32.txz -o ~/jails
    fetch ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/10.2-RELEASE/ports.txz -o ~/jails

    Extract the base files
    tar -xf ~/jails/base.txz -C /usr/local/jails/template
    tar -xf ~/jails/lib32.txz -C /usr/local/jails/template
    tar -xf ~/jails/ports.txz -C /usr/local/jails/template

    Copy files from host to template
    cp /etc/resolv.conf /usr/local/jails/template/etc/resolv.conf
    cp /etc/localtime /usr/local/jails/template/etc/localtime
    mkdir -p /usr/local/template/home/username/.ssh
    cp /home/username/.ssh/authorized_keys /usr/local/jails/template/home/username/.ssh

    When finished, take a snapshot
    zfs snapshot zroot/jails/template@1

    Edit /etc/jail.conf
    # Global settings applied to all jails

    interface = "re0";
    host.hostname = "$name";
    ip4.addr = 192.168.1.$ip;
    path = "/usr/local/jails/$name";

    exec.start = "/bin/sh /etc/rc";
    exec.stop = "/bin/sh /etc/rc.shutdown";
    exec.clean;
    mount.devfs;

    # Jail Definitions
    testjail {
        $ip = 15;
    }

    Run the jail
    jail -c testjail

    View running jails
    jls

    Login to the jail
    jexec $jailname sh

New Template Script
-------------------

    #! /bin/sh

    # Create mountpoint
    zfs create -o mountpoint=/usr/local/jails zroot/jails
    zfs create -p zroot/jails/template

    # Copy pre-downloaded base files
    scp -r "user@freenas:/mnt/SSD_storage/jails/*.txz" /tmp

    # Extract the files to the template location
    tar -xf /tmp/base.txz -C /usr/local/jails/template
    tar -xf /tmp/lib32.txz -C /usr/local/jails/template
    tar -xf /tmp/ports.txz -C /usr/local/jails/template

    # Copy files from host/hypervisor to template
    cp /etc/resolv.conf /usr/local/jails/template/etc/resolv.conf
    cp /etc/localtime /usr/local/jails/template/etc/localtime
    mkdir -p /usr/local/template/home/user/.ssh
    cp /home/user/.ssh/authorized_keys /usr/local/jails/template/home/user/.ssh

    # Create the snapshot
    zfs snapshot zroot/jails/template@1

    # Copy the pre-configured jail.conf file
    scp -r "user@freenas:/mnt/SSD_storage/jails/jail.conf" /usr/local/jails/template/etc/

    echo "Run the jails using jail -c jailname"
    echo "View running jails with jls"
    echo "Log into the jail using jexec jailname sh"

New Jail Creation Script
------------------------

    #! /bin/sh
    read -p "Enter jail name:" hostname
    zfs clone zroot/jails/template@1 zroot/jails/$hostname
    echo hostname=\"$hostname\" > /usr/local/jails/$hostname/etc/rc.conf
    # Disable sendmail to speed up start time
    echo sendmail_submit_enable=\"NO\" >> /usr/local/jails/$hostname/etc/rc.conf
    echo sendmail_outbound_enable=\"NO\" >> /usr/local/jails/$hostname/etc/rc.conf
    echo sendmail_msp_queue_enable=\"NO\" >> /usr/local/jails/$hostname/etc/rc.conf

Automating Bhyve VM Creation
----------------------------

    Edit /etc/sysctl.conf
    net.link.tap.up_on_open=1

    Edit /boot/loader.conf
    vmm_load="YES"
    nmdm_load="YES"
    if_bridge_load="YES"
    if_tap_load="YES"

    Edit /etc/rc.conf
    cloned_interfaces="bridge0 tap0"
    ifconfig_bridge0="addm re0 addm tap0"

    Create ZFS volume
    zfs create -V16G -o volmode=dev zroot/testvm

    Download the installation image
    fetch ftp://ftp.freebsd.org/pub/FreeBSD/releases/ISO-IMAGES/10.2/FreeBSD-10.2-RELEASE-amd64-disc1.iso 

    Start the VM
    sh /usr/share/examples/bhyve/vmrun.sh -c 1 -m 512M -t tap0 -d /dev/zvol/zroot/testvm -i -I FreeBSD-10.2-RELEASE-amd64-disc1.iso testvm

    Install as normal, following the menu options

New VM Creation Script
----------------------

    #! /bin/sh
    read -p "Enter hostname: " hostname
    zfs create -V16G -o volmode=dev zroot/$hostname
    sh /usr/share/examples/bhyve/vmrun.sh -c 1 -m 512M -t tap0 -d /dev/zvol/zroot/$hostname -i -I ~/FreeBSD-10.2-RELEASE-amd64-disc1.iso $hostname

Creating a Linux guest
----------------------

    Create a file for the hard disk
    truncate -s 16G linux.img

    Create the file to map the virtual devices for kernel load
    cat device.map (use the full path)
    (hd0) /root/linux.img
    (cd0) /root/linux.iso

    Load the kernel
    grub-bhyve -m device.map -r cd0 -M 1024M linuxguest

    Grub should start, choose install as normal

    Start the VM
    bhyve -A -H -P -s 0:0,hostbridge -s 1:0,lpc -s 2:0,virtio-net,tap0 -s 3:0,virtio-blk,/root/linux.img -l com1,/dev/nmdm0A -c 1 -m 512M linuxguest

    Access through the serial console
    cu -l /dev/nmdm0B

Backing up VMs
--------------

    In the FreeNAS web interface, create a new user
    Account
    Add User
    Fill in the fields
    Allow sudo
    Ensure the public key is pasted into the SSH key field

    Connect to the NAS over SSH
    # sysctl vfs.usermount=1
    # echo vfs.usermount=1 >> /etc/sysctl.conf
    # zfs create SSD_storage/backup
    # zfs allow -u user create,mount,receive SSD_storage/backup

    Allow user to send snapshots
    # zfs allow -u user send,snapshot zroot

    Create the snapshot
    $ zfs snapshot zroot/testvm@1

    Send the snapshot to the NAS
    $ zfs send zroot/testvm@1 | ssh user@freenas zfs recv -dvu SSD_storage/backup

    After a full snapshot is taken, incremental backups can be performed
    $ zfs send -i zroot/testvm@1 zroot/testvm@2 | ssh user@freenas zfs recv -dvu SSD_storage/backup

pfSense in a VM
---------------

    Download the pfSense disk image from the website using fetch
    fetch https://frafiles.pfsense.org/mirror/downloads/pfSense-CE-2.3.1-RELEASE-2g-amd64-nanobsd.img.gz -o ~/pfSense.img.gz

    Create the storage
    zfs create -V2G -o volmode=dev zroot/pfsense

    Unzip the file, and redirect output to the storage via dd
    gzip -dc pfSense.img.gz | dd of=/dev/zvol/zroot/pfsense obs=64k

    Load the kernel and start the boot process
    bhyveload -c /dev/nmdm0A -d /dev/zvol/zroot/pfsense -m 256MB pfsense

    Start the VM
    /usr/sbin/bhyve -c 1 -m 256 -A -H -P -s 0:0,hostbridge -s 1:0,virtio-net,tap0 -s 3:0,ahci-hd,/dev/zvol/zroot/pfsense -s 4:1,lpc -l com1,/dev/nmdm0A pfsense

    Connect to the VM via the serial connection with nmdm
    cu -l /dev/nmdm0B

    Perform initial configuration through the shell to assign the network interfaces

    Once done, use the IP address to access through the web console 

    When finished, you can shutdown/reboot

    To de-allocate the resources, you need to destroy the VM
    bhyvectl --destroy --vm=pfsense

NanoBSD
-------

    NanoBSD docs
    PDF: NanoBSD, ZFS and Jails

    cd to NanoBSD build directory
    cd /usr/src/tools/tools/nanobsd

    Run the build script, using default values for now
    sh nanobsd.sh

    Wait a while for buildworld to finish

    Go to output directory
    cd /usr/obj/nanobsd.full

    Create a new ZFS device
    zfs create -V5G -o volmode=dev zroot/testnano

    Copy the NanoBSD full image to the ZFS device
    dd if=_.disk.full of=/dev/zvol/zroot/testnano

    Run Bhyve using the ZFS device for boot
    sh /usr/share/examples/bhyve/vmrun.sh -c 1 -m 512M -t tap0 -d /dev/zvol/zroot/testnano testnano

    It boots! But, it cant mount root on a device... yet....

    ***
    Got it to boot by changing the NANO_DRIVE variable from ad0 to vtbd0 in the
    nanobsd.sh file

    Cloning NanoBSD vms
    zfs snapshot zroot/nanotest@1
    zfs clone zroot/nanotest@1 zroot/nanoclone
    ***

    nanobsdv.conf

    cust_nobeastie() (
        touch ${nano_worlddir}/boot/loader.conf
        echo "beastie_disable=\"yes\"" >> ${nano_worlddir}/boot/loader.conf
    )

    customize_cmd cust_install_files
    customize_cmd cust_nobeastie

    Got internet and zfs working
    Check that the files are configured exactly as in the handbook
    Make sure to run ifconfig tap0 up and ifconfig bridge0 up
    For zfs, the NANO_MODULES variable needs zfs and opensolaris added e.g.
    NANO_MODULES="zfs opensolaris"
    Simply adding this to the conf file was causing errors, needed to
    build kernel and world again.
    Also, it kept saying the usual "filesystem is full error", but this time
    the file system really was full.
    Added "FlashDevice SanDisk 4G" in the conf file to give it 4GB instead 
    of 1GB.
    Compiled it again and it works now.

    sh nanobsdv.sh -b -c nanobsdv.conf

    Base system:
    Hostname + IP
    Change root password using OPIE
    Create admin user with random password
    Create SSH keys
    Remove root login access
    Setup security: 
	TCP wrapper
	Firewall
	IDS
    Pull config from gold server
    Start jails/applications


Multiple VMs using bhyve
------------------------

To allow networking on multiple vms, there should be a tap assigned to each vm, connected to the same bridge. 

So to set up the bridge and an initial tap interface:

    Edit /etc/sysctl.conf
    net.link.tap.up_on_open=1

    Edit /boot/loader.conf
    vmm_load="YES"
    nmdm_load="YES"
    if_bridge_load="YES"
    if_tap_load="YES"

    Edit /etc/rc.conf
    cloned_interfaces="bridge0 tap0"
    ifconfig_bridge0="addm re0 addm tap0"

    You then add multiple tap interfaces, by adding them to cloned_interfaces and ifconfig_bridge0 in /etc/rc.conf.
    cloned_interfaces="bridge0 tap0 tap1 tap2"
    ifconfig_bridge0="addm re0 addm tap0 addm tap1 addm tap2"

    Then when you provision vms, assign one of the tap interfaces to them.





Jails setup in NanoBSD bhyve vm
-------------------------------

    jail.conf | listofjails | newtemplate.sh | createalljails | startalljails.sh

Jails Infrastructure
--------------------

    createalljails.sh

    cat /etc/jail.conf | grep -E \{$ | sed "s/{//" > ~/jails/listofjails.txt
    #}} - ignore these braces, the previous command messes with the syntax higlighting

    for jail in `cat ~/jails/listofjails.txt`
    do
        zfs clone zroot/jails/template@1 zroot/jails/$jail
        echo hostname=$jail > /usr/local/jails/$jail/etc/rc.conf

        # Disable sendmail to speed up start time
        echo sendmail_submit_enable=\"NO\" >> /usr/local/jails/$jail/etc/rc.conf
        echo sendmail_outbound_enable=\"NO\" >> /usr/local/jails/$jail/etc/rc.conf
        echo sendmail_msp_queue_enable=\"NO\" >> /usr/local/jails/$jail/etc/rc.conf

    cat ~/jails/listofjails.txt | sed "s/^/jail \-c /"

/etc/jail.conf
--------------

    # Global settings applied to all jails

    interface = "re0";
    host.hostname = "$name";
    ip4.addr = 192.168.1.$ip;
    path = "/usr/local/jails/$name";

    exec.start = "/bin/sh /etc/rc";
    exec.stop = "/bin/sh /etc/rc.shutdown";
    exec.clean;
    mount.devfs;

    # Jail Definitions

    wintermute {
        $ip = 15;
    }

    neuromancer {
        $ip = 16;
    }

    armitage {
        $ip = 17;
    }

    finn {
        $ip = 18;
    }

    hideo {
        $ip = 19;
    }

    maelcum {
        $ip = 20;
    }

    case {
        $ip = 21;
    }

    molly {
        $ip = 22;
    }

Jail names
----------

    Armitage
    - Version control - Git
    - Host install tools - Ansible, shell scripts
    - Ad hoc change tools - Ansible, shell scripts

    Wintermute - Neuromancer
    - Directory servers -- DNS, NIS, LDAP
    - Authentication servers -- NIS, Kerberos 
    - Time Synchronisation -- NTP
    - Host IP addressing -- DHCP

    Finn
    - Network File servers -- NFS
    - File Replication servers -- Git, Ansible, SUP

    Maelcum
    - Mail -- SMTP

    Hideo
    - Logging -- Syslogd
    - Security -- OPIE, SSH, PKI
    - Performance monitoring -- collectd

    Case - Molly
    - Web servers -- Apache

Updating Jails
--------------

    Update the host system first:
    freebsd-update fetch
    freebsd-update install

    Find out current version:
    $VERSION=freebsd-version | sed 's/-/ /' | awk '{print $1}'

    Fetch the base files from the FreeBSD FTP:
    fetch ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/$VERSION-RELEASE/base.txz -o ~/jails
    fetch ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/$VERSION-RELEASE/lib32.txz -o ~/jails
    fetch ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/$VERSION-RELEASE/ports.txz -o ~/jails

    Remove the previous template and all cloned jails
    zfs destroy -R zroot/jails/template@1

    Create the template directory:
    zfs create -p zroot/jails/template

    Extract the downloaded base files:
    tar -xf ~/jails/*.txz -C /usr/local/jails/template

    Copy needed files:
    cp /etc/resolv.conf /usr/local/jails/template/etc
    mkdir -p /usr/local/jails/template/home/username/.ssh
    cp /home/username/.ssh/authorized_keys /usr/local/jails/template/home/username/.ssh

    Create the new snapshot:
    zfs snapshot zroot/jails/template@1

    Run the createalljails.sh script

    Run the startalljails.sh script



Thin jails
---

	Update the template
	freebsd-update -b /usr/local/jails/template fetch install







Ansible Setup
-------------

    # Create the "ansible" user
    adduser -f filename
    ansible:::::::::password
    # Generate the SSH key for the ansible user
    ssh-keygen -N "" -f /home/ansible/.ssh/id_rsa
    su -m ansible -c 'ssh-keygen -N "" -f /home/ansible/.ssh/id_rsa'
    cat /home/ansible/.ssh/id_rsa.pub

    echo "ansible:::::::::$RANDOMPASSWORD" > /usr/local/jails/$JAILNAME/root/ansibleuser
    jexec $JAILENAME adduser -f /root/ansibleuser

    rm /usr/local/jails/$JAILNAME/root/ansibleuser

Crypto
------

    Supersingular isogeny Diffie-Hellman key exchange (SIDH)
    Efficient algorithms for SIDH (PDF)
    SIDH library

    Instant Messaging client
    Irssi IRC client with OTR for authentication
    Irssi-OTR
    Irssi
    OTR
    DANE

DNS
---

    Unbound working as an authoritative resolver for LAN. You need to run 
    unbound-control reload after changing the conf file, otherwise it wont work!
    You also need to change /etc/resolv.conf so that nameserver 127.0.0.1 
    appears ABOVE the bthomehub resolver, so that the local unbound server 
    is queried first before it goes to bthomehub. (in prod resolv.conf would just
    have the proper name servers, but this can stay for now)
    unbound.conf

    You also need to make sure that local-* is inside the server: block, 
    otherwise it doesnt work...
    server:
        unblock-lan-zones: yes
        username stuff...
        interface: 0.0.0.0
        local-zone: "local." static
        local-data: "finn.local. A 192.168.1.18"
        
    NSD (name server daemon) is an authoritative only, memory efficient, highly
    secure and simple to configure open source domain name server. NSD acts as 
    the authoritative name server, while Unbound acts as the validating, 
    resolving and caching DNS server.

    The Unbound servers act as validating, recursive and caching DNS servers
    that LAN clients can query. Then NSD is an authoritative server which
    can resolve internal LAN names only. NSD never goes to the internet,
    and its only job is to serve internal names to Unbound.

    Zones can be signed with the OpenDNSSEC tool. Private keys associated
    with DNSSEC signing are secured using HSMs (hardware security modules).
    This can be done using OpenHSM for testing, however, in production a 
    real HSM would be used.

SSH
---

	# Jails ssh config
	# Remove existing host keys and generate ed25519 host key
	if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
		rm /etc/ssh/ssh_*host*
		ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -t ed25519 -N "" -E sha256
	fi
	
	# Generate SSHFP records
	ssh-keygen -r $(hostname) | awk '$4 == && $5 == 2 {print $0}'


Mount ZFS datasets over NFS
---

	zfs create zroot/test
	zfs set sharenfs="rw=@192.168.1/24" zroot/test

	


SSH with X.509 v3 Certificate Support (PKIX-SSH)
---

    Running inside a jail for testing

    fetch http://roumenpetrov.info/secsh/src/pkixssh-9.2.tar.xz
    tar -xvf pkixssh-9.2.tar.xz
    vi Makefile.in
    Uncomment the SHELL variable line
    ./configure
    make
    make install
    Follow the instructions in README.privsep
    mkdir /var/empty/
    chown root:sys /var/empty/
    chmod 755 /var/empty/
    pw groupadd sshd
    pw usermod sshd -c 'sshd privsep' -d /var/empty -s /bin/false sshd
    The default install location was /usr/local/bin
    Test generating a key:
    /usr/local/bin/ssh-keygen -b 384 -t ecdsa -f /etc/ssh/ssh_host_key -N ""


Compiling NGINX with ChaCha20 support
---

    # Make a working directory
    mkdir ~/nginx
    cd ~/nginx

    # Install some dependencies
    pkg install ca_root_nss
    pkg install pcre
    pkg install perl5

    # Pull the source files
    fetch https://nginx.org/download/nginx-1.13.0.tar.gz
    fetch https://www.openssl.org/source/openssl-1.1.0e.tar.gz

    # Extract the tarballs
    tar -xzvf nginx-1.13.0.tar.gz
    tar -xzvf openssl-1.1.0e.tar.gz
    rm *.tar.gz
   
    # Compile openssl
    cd ~/nginx/openssl-1.1.0e.tar.gz
    ./config
    make
    make install

    # openssl should default to /usr/local/bin unless prefixdir variable has been specified
    /usr/local/bin/openssl version
    # Should output OpenSSL 1.1.0e

    # Compile NGINX
    # Use the compile script listing modules to include
    #!/bin/sh
    cd ~/nginx/nginx-1.13.0/
    #make clean
    
    ./configure \
    	--with-http_ssl_module \
    #	--with-http-spdy_module \
    	--with-http_gzip_static_module \
    	--with-file-aio \
    	--with-ld-opt="-L /usr/local/lib" \
    
    #	--without-http_autoindex_module \
    	--without-http_browser_module \
    	--without-http_fastcgi_module \
    	--without-http_geo_module \
    	--without-http_map_module \
    	--without-http_proxy_module \
    	--without-http_memcached_module \
    	--without-http_ssi_module \
    	--without-http_userid_module \
    	--without-http_split_clients_module \
    	--without-http_uwsgi_module \
    	--without-http_scgi_module \
    	--without-http_limit_conn_module \
    	--without-http_referer_module \
    	--without-http_http-cache \
    	--without_upstream_ip_hash_module \
    	--without-mail_pop3_module \
    	--without-mail-imap_module \
    	--without-mail_smtp_module
    
    	--with-openssl=~/nginx/openssl-1.1.0e/
    
    make
    make install

    # After running the compile script, NGINX should be installed in /usr/local/nginx
    # Start the service
    /usr/local/nginx/sbin/nginx

    # If there are no issues, update the config file in /usr/local/nginx/conf/nginx.conf. 
    # Reload NGINX to apply the new config
    /usr/local/nginx/sbin/nginx -s reload

    # Generate an EC certificate
    /usr/local/bin/openssl ecparam -list_curves
    /usr/local/bin/openssl ecparam -name secp384r1 -genkey -param_enc explicit -out private-key.pem
    /usr/local/bin/openssl req -new -x509 -key private-key.pem -out server.pem -days 365
    cat private-key.pem server.pem > server-private.pem



    # Currently having trouble getting a ECDSA signed certificate to work when loading the site in a browser. So far it works with TLSv1.2, ECDHE_RSA, X25519 and CHACHA20-POLY1305. At the moment if I generate a ECDSA cert and use it, the site fails to load at all. So using RSA for now.

    # Current NGINX config:

    worker_processes  1;
    
    events {
        worker_connections  1024;
    }
    
    
    http {
        include       mime.types;
        default_type  application/octet-stream;
        sendfile        on;
        keepalive_timeout  65;
    
        server {
            listen       80;
            server_name  localhost;
            location / {
                root   /usr/local/www/;
                index  index.html index.htm;
            }
    
            error_page   500 502 503 504  /50x.html;
            location = /50x.html {
                root   html;
            }
    
        }
    
        server {
            listen       443 ssl;
            server_name  localhost;
    
    	ssl on;
            #ssl_certificate      /root/nginx/server.pem;
            #ssl_certificate_key  /root/nginx/private.pem;
    	ssl_certificate /usr/local/www/nginx-selfsigned.crt;
    	ssl_certificate_key /usr/local/www/nginx-selfsigned.key;
    	#ssl_ciphers HIGH;
    	ssl_ciphers "ECDHE-RSA-CHACHA20-POLY1305";
            ssl_prefer_server_ciphers  on;
    	ssl_protocols TLSv1.2;
    	ssl_ecdh_curve X25519;
    	
    	location / {
                root   /usr/local/www/;
                index  index.html index.htm;
            }
        }
    
    }
