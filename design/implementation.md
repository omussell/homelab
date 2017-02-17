% Bootstrapping a Secure Infrastructure
% Oliver Mussell
% 2016-2017

<!---

- Produced in Markdown with Vim, converted to HTML by Pandoc.
- Graphics created with DOT
- Hosted on Github Pages

-->

- [Overview](/homelab/design/overview.html)
- [Design](/homelab/design/design.html)
- [Implementation](/homelab/design/implementation.html)

===

Create an infrastructure with an emphasis on security, resiliency and ease of maintenance. 

End Goal
===

Produce a working implementation of a secure, resilient and easy to maintain infrastructure. This will be published in the form of version-controlled configuration documents, with the philosophy and background of the chosen configuration documented here. Anyone should be able to download the vendor supplied base operating system, and the configuration documents should convert that base OS into the desired state. The process by which this conversion is achieved could be as simple as a shell script, or as complicated as a configuration management tool backed by continuous deployment pipelines. In addition, the infrastructure should be flexible enough to be deployed in multiple configurations based on the decisions of the Infrastructure Architects and business owners. It should also be portable to other operating systems with only a little massage of the configuration code.

Background
===

The design of the environment will be similar to [Project Athena] at MIT and the [Distributed Computing Environment] by the OSF. Inspiration for this project comes from the [infrastructures.org] website, specifically their papers: [Bootstrapping an Infrastructure] and [Why Order Matters: Turing Equivalence in Automated Systems Administration]. Additionally, a paper by Paul Schenkeveld, [Building servers with NanoBSD, ZFS and Jails] served as inspiration for the use of NanoBSD as the operating system due to its unique properties.

This project aims to extend the work of infrastructures.org and Paul Schenkeveld, by emphasising security and producing a working implementation that can be used by anyone.

[infrastructures.org]: http://www.infrastructures.org
[Bootstrapping an Infrastructure]: http://www.infrastructures.org/papers/bootstrap/bootstrap.html
[Why Order Matters: Turing Equivalence in Automated Systems Administration]: http://www.infrastructures.org/papers/turing/turing.html
[Building servers with NanoBSD, ZFS and Jails]: https://2010.asiabsdcon.org/papers/abc2010-P4A-paper.pdf
[Project Athena]: https://en.wikipedia.org/wiki/Project_Athena
[Distributed Computing Environment]: https://en.wikipedia.org/wiki/Distributed_Computing_Environment

High-Level Design
===
<!---

- Control Machine - Stores operating system images and configuration files in version control. Used to create the Gold server. 
- Gold server - In the form of a created system image
- Infrastructure servers - Provides directory, domain names, authentication/authorisation services
- Data storage - Provide clients with access to their data/files via network file systems.
- Clients - End use

--->

<img src="/homelab/pic/secenv.svg">
<img src="/homelab/pic/disklayout.svg">

<!---

!!
Directory servers comes in the form of DNS, using NSD as an authoritative name server, and Unbound for validating, caching and resolving servers. DNSSEC is implemented via OpenDNSSEC. SoftHSM is used for key storage (though a physical HSM would be necessary for prod). CA using OpenSSL. DANE used for D/TLS auth. 
Heimdal Kerberos backed by OpenLDAP. Kerberized Internet Negotiation of Keys (KINK) used for the security aspect of VPN over IPsec, used to connect sites to one another. SH also uses Kerberos for password authentication in addition to public key authentication. OpenNTPd for time.

KerberizedNFSv4 for client file access.

!!

--->

Experimental
===
Features that aren't production ready, but would be interesting to implement:

- SSH using X509v3 certificates, signed by a central CA (or validated with DANE?)
- TLS using SIDH with the Microsoft Research OpenSSL patch (also validated with DANE?)

Detailed Design
===

<!---

Control machine config, Git, SSH, 2FA?
Gold server, how are changes propagated? git repo hosted on this server, which each derivative server pulls from? system images can be sent via dd over SSH.
Main servers - DNS in the form of NSD for authoritative, Unbound for resolving. OpenDNSSEC for key signing, keys stored in SoftHSM. DANE used for D/TLS auth. Kerberos for auth, with LDAP directory services. Everything should be authenticated with Kerberos, SSH, PKINIT, IPsec via KINK, inter-server communication, mail access etc. KerberizedNFSv4 for client file access.  
Clients, create a thin client build, Irssi-OTR with OpenPGP keys stored in DNS/LDAP

--->

IPv6
---

IPv6 is the latest version of the IP protocol, which offers significant advantages over IPv4. 

IPv6 uses a 128-bit address which allows a much larger address space, 2^128. A single /64 subnet has a size of 2^64 addresses which equates to the square of the entire IPv4 address space. An address is represented as eight groups of four hexadecimal digits with the groups separated by colons, e.g. 2001:0db8:0000:0042:0000:8a2e:0370:7334. Guidance for representing IPv6 addresses in text is shown in [RFC5952].

IPv6 addresses can be assigned in two ways, stateful or stateless, via Stateless Address Autoconfiguration ([SLAAC]) and/or DHCPv6. The stateless approach is used when a site is not particularly concerned with the addresses hosts use, whereas stateful DHCPv6 is used when a site requires tighter control over addresses. Both SLAAC and DHCPv6 may be used simultaneously. 

### Address Autoconfiguration (SLAAC) ###
The autoconfiguration process includes generating a link-local address, generating global addresses via stateless address autoconfiguration, and the Duplicate Address Detection procedure to verify the uniqueness of the addresses on a link. The IPv6 stateless autoconfiguration mechanism requires no manual configuration of hosts, minimal configuration of routers, and no additional servers. The stateless mechanism allows a host to generate its own addresses using a combination of locally available information and information advertised by routers. Routers advertise prefixes that identify the subnet(s) associated with a link, while hosts generate an "interface identifier" that uniquely identifies an interface on a subnet. An address is formed by combining the two. In the absence of routers, a host can only generate link-local addresses. However, link-local addresses are sufficient for allowing communication among nodes attached to the same link.

IPv6 nodes on the same link use the Neighbor Discovery protocol to discover each others presence, to determine each others link-layer addresses, to find routers, and to maintain reachability information about the paths to active neighbors.

All interfaces of IPv6 hosts require a link-local address, which is derived from the MAC address of the interface and the prefix fe80::/10. The address space is filled with prefix bits left-justified to the most-significant bit, and filling the MAC address in EUI-64 format into the least-significant bits. Any remaining bits between the two parts are set to zero.

	- The left-most 'prefix length' bits of the address are those of the link-local prefix
	- The bits in the address to the right of the link-local prefix are set to all zeroes
	- If the length of the interface identifier is Nbits, the right-most N bits of the address are replaced by the interface identifier

Global addresses are formed by appending an interface identifier to a prefix of appropriate length. Prefixes are obtained from Prefix Information options contained in Router Advertisements. RA's are sent periodically to the all-nodes multicast address. To obtain an advertisement quickly, a host send out Router Solicitations as described in [RFC4861].

PICTURE OF GLOBAL ADDRESS GENERATION

The Neighbor Discovery Protocol ([NDP]) is used by nodes to determine the link-layer addresses for neighbors known to reside on the same attached link, to find neighboring routers to forward packets, and to keep track of neighbors that are reachable or not.

The IPv6 router will be allocated a subnet by the ISP and configured with the first 64 bits of the 128-bit address. [Duplicate Address Detection] and [Neighbor Unreachability Detection] serve as error handling for the address autoconfiguration. 

Since the IPv6 addresses are generated from the prefix on the router, it is possible to renumber an entire network by changing the prefix on the router.

IPv6 address are mapped to hostnames in DNS using [AAAA resource records]. Reverse resolution uses the ip6.arpa domain.



[SLAAC]: https://tools.ietf.org/html/rfc4862
[NDP]: https://tools.ietf.org/html/rfc4861
[Duplicate Address Detection]: https://tools.ietf.org/html/rfc4862#section-5.4
[Neighbor Unreachability Detection]: https://tools.ietf.org/html/rfc4861#section-7.3
[AAAA resource records]: https://tools.ietf.org/html/rfc3596
[RFC5952]: https://tools.ietf.org/html/rfc5952
[RFC4861]: https://tools.ietf.org/html/rfc4861

### SEND ###
The SEcure Neighbor Discovery ([SEND]) protocol is designed to counter threats to the Neighbor Discovery Protocol ([NDP]) used by IPv6 to discover the presence of nodes on the same link and to find routers. SEND does not apply to addresses generated by SLAAC.

Components of SEND:

- Certification paths are expected to certify the authority of routers. A host must be configured with a trust anchor to which the router has a certification path before the host can adopt the router as its default router. 
- Cryptographically Generated Addresses are used to make sure that the sender of a Neighbor Discovery message is the owner of the claimed address.
- Timestamp and Nonce options are used to provide replay protection.

The deployment model for trust anchors can be either a globally rooted public key infrastructure, or a local decentralised deployment similar to that used for TLS. At the moment, a global root does not exist and so cannot be used. In the decentralised model, a public key can be published by the end hosts own organisation. In a roaming environment, multiple trusted public keys can be configured. Also, a SEND node can fall back to the use of a non-SEND router.

By default, a SEND-enabled node should use only CGAs for its own addresses. Cryptographically Generated Addresses ([CGA]) are IPv6 addresses for which the interface identifier is generated by computing a cryptographic one-way hash function from a public key and other parameters. The binding between the public key and the address can be verified by re-computing the hash value and by comparing the hash value with the interface identifier. Messages from an IPv6 address can be protected by attaching the public key and parameters and then signing the message with the corresponding private key.

The purpose of CGAs is to prevent stealing and spoofing of existing IPv6 addresses. The public key of the address owner is bound cryptographically to the address. The address owner can use the corresponding private key to assert its ownership and to sign SEND messages sent from the address. An attacker can create a new address from an arbitrary subnet prefix and a public key because CGAs are not certified. Hwoever, the attacker cannot impersonate somebody else's address.

### SEND SAVI ###
The SEcure Neighbor Discovery (SEND) Source Address Validation Improvement ([SAVI]) is a mechanism to provide source address validation using the SEND protocol. SEND SAVI uses the Duplicate Address Detection and Neighbor Unreachability messages to validate the address ownership claim of a node. Using the information contained in these messages, host IPv6 addresses are associated to switch ports, so that data packets will be validated by checking for consistency in this binding. In addition, SEND SAVI prevents hosts from generating packets containing off-link IPv6 source addresses.

SEND SAVI is limited to links and prefixes in which every IPv6 host and router uses the SEND protocol to protect the exchange of Neighbor Discovery information.

[SEND]: https://tools.ietf.org/html/rfc3971
[NDP]: https://tools.ietf.org/html/rfc4861
[CGA]: https://tools.ietf.org/html/rfc3972
[SAVI]: https://tools.ietf.org/html/rfc7219

### DHCPv6 ###
DHCPv6 is the stateful counterpart to SLAAC. DHCPv6 enables DHCP servers to pass IPv6 network information to IPv6 nodes, such as addresses and configuration information carried in options.

Clients transmit and receive DHCP messages over UDP using the autogenerated link-local address.

 



### IPsec ###
Security associations via IKE or KINK


### KINK ###
[Kerberized Internet Negotiation of Keys] (KINK) defines a protocol to establish and maintain security associations using the Kerberos authentication system. The central key management provided by Kerberos is efficient because it limits computational cost and limits complexity versus IKE's necessity of using public key cryptography. Initial authentication to the KDC may be performed using asymmetric keys via [Public Key Cryptography for Initial Authentication in Kerberos] (PKINIT).


[Kerberized Internet Negotiation of Keys]: https://tools.ietf.org/html/rfc4430
[Public Key Cryptography for Initial Authentication in Kerberos]: https://tools.ietf.org/html/rfc4556

OS
---
The general server design would be a generic NanoBSD image occupying a flash device such as SD card serving as the operating system. Physical drives (either spinning disk or SSD) will be formatted with ZFS, on top of which the base for the jails will reside. Data used by the applications such as databases are stored on discrete storage appliances.

### FreeBSD ###
[FreeBSD] is an advanced computer operating system used to power modern servers. Its advanced networking, security, and storage features have made FreeBSD the platform of choice for embedded networking and storage devices, and powers many of the [busiest web sites].

FreeBSD was chosen as the operating system due to the benefits of NanoBSD, Jails and ZFS. However, the tools and configurations are platform agnostic, and can be ported to other Unix-like operating systems. 

### NanoBSD ###
[NanoBSD] is built via shell script and produces a minimal implementation of FreeBSD which fits on small flash media. The image is customised with a configuration file, which specifies variables and functions to build the image as required. There are three stages to the image build: buildkernel, buildworld and the customise commands. The buildkernel stage is only required to be run once, further configuration changes can skip the buildkernel stage. However, some configuration changes do still require the kernel to be built. Compiling the kernel takes a long time (~30 minutes) and should be done sparingly.

Once the kernel and world have been built, you can customise the state of the environment using the customise commands. These are functions specified at the end of the configuration file. By skipping the buildkernel and buildworld stages, you reduce the image build time to ~20 seconds.

The image is only required to be built once, updated images are deployed via dd to the inactive slice. The system is then rebooted, and boots into the newly updated slice. If there are problems, change the slice back to the original, and reboot. Building the image offline also gives the advantage of being able to test the image easily prior to widespread deployment. You can dd the image to a zfs volume, then use bhyve to run the image as a virtual machine. You can then perform testing to ensure it is correct, before rolling out the image to production.

The flash storage is divided into three parts: the two image partitions or slices (1 and 2) containing the read-only root filesystem where only one is active, and the configuration file partition or /cfg. The /etc and /var directories are md (malloc backed) disks, which means they are located in RAM. On boot, the active slice contains the root filesystem mounted as read-only, which is beneficial since it is stored on flash media which has a limited number of writes. Configuration changes to files in /etc or /var are temporary, since they are located in RAM, and are loaded from the /cfg partition on boot. This means you can change configuration files, and if things go wrong, you can just reboot to clear the RAM. Otherwise if the new configuration is correct, you can mount /cfg, copy the changed files from /etc or /var to /cfg, then unmount again. Also, since the root filesystem is read-only, it is able to survive after an unplanned reboot. There is also no reason to run fsck after a non-graceful shutdown.

Since the configuration files are stored separately to the root filesystem, when switching the active slice, the configuration files are not changed. So updates and upgrades should not have an effect on the running configuration. It is also good operational practice to make sure that any configuration changes are saved to /cfg after testing, so that in the event the server reboots the configuration is still saved. This also gives administrators the flexibility to compile a custom kernel/image in order to include files/packages/kernel modules as part of the image. Doing so could result in faster boot times due to the kernel not having to query the hardware, and a reduced attack surface since unneeded components are removed. This comes at the cost of higher complexity and more difficult maintenance.


### Jails ###

- A process and all descendants are restricted to a chrooted directory tree
- Does not rely on virtualisation, so performance penalty is mitigated
- Easy to update or upgrade individual jails



Jail parameters (jail.conf)

- path - Directory which is the root of the jail
- vnet - jail has its own virtual network stack with interfaces, addresses, routing table etc. - !! - Is this required to allow applications access to the network?
- persist - allows a jail to exist without any processes, so it won't be removed when stopped.
- allow.mount - allow users in jail to mount jail-friendly filesystems. May be required for NFS / home directory mounts?
- exec.prestart - commands to run in the system environment before a jail is created
- exec.start - commands to run in the jail environment when a jail is created
- exec.poststart - commands to run in the system environment after a jail is created, and after any exec.start commands have completed
- exec.prestop - commands to run in the system environment before a jail is removed
- exec.stop - commands to run in the jail environment before a jail is removed, and after any exec.prestop commands have completed
- exec.poststop - commands to run in the system environment after a jail is removed
- ip_hostname - resolve the host.hostname parameter and add all IP addresses returned by the resolver to the list of addresses for this jail. - !! - Basically, rather than manually setting IP addresses, this setting means the IP is pulled from DNS (which is secured by DNSSEC). This introduces a bootstrap problem though, how do the DNS servers get IP addresses in the first place? (link-local addresses?)
- mount or mount.fstab - filesystems to mount before creating the jail
- depend - specify jails that this jail depends on. When this jail is to be created, any jails it depends on must already exist, otherwise they are created automatically up to the completion of the last exec.poststart command.
 
Configuring the jail:

- Setup /etc/resolv.conf so that name resolution works
- Run newaliases to stop sendmail warnings
- Set the root password
- Set the timezone
- Add accounts for users
- Install packages
 
- Setup bindings to other services (or get them from SRV records in DNS?)
- Setup SSH to jail environment, configure sshd_config 




### ZFS ###

- Data integrity using checksums
- Pooled storage, where all disks added to the pool are available to all filesystems
- High performance with multiple caching mechanisms
- Snapshots

A storage pool is a collection of devices that provides physical storage and data replication for ZFS datasets. All datasets within a storage pool share the same space.

**Virtual Devicer (vdevs)**

A virtual device or vdev is a device or collection of devices organised into groups:

- Disk - A block device, under /dev.
- File - A regular file
- Mirror - A mirror of two or more devices. 
- raidz - Data and parity is striped across all disks within a raidz group.
- Spare - A special psuedo-vdev which keeps track of available hot spares in a pool.
- Log - A separate-intent log device.
- Cache - A device used to cache storage pool data.

ZFS allows devices to be associated with pools as hot spares. These devices are not actively used in the pool, but when an active device fails, it is automatically replaced by a hot spare.

There are zfs datasets in a zfs storage pool:

- File system - Can be mounted within the standard system namespace and behaves like other file systems.
- Volume - A logical volume exported as a raw or block device.
- Snapshot - A read-only version of a file system or volume at a given point in time, *filesystem@name* or *volume@name*

Snapshots can be created quickly, and initially do not consume any additional space. As data in the active dataset changes, the snapshot consumes data. Snapshots of volumes can be cloned or rolled back, but cannot be access independently. File system snapshots can be access under the .zfs/snapshot directory in the root of the file system.

A clone is a writable volume or file system whose initial contents are the same as another dataset. Clones can only be created from a snapshot. When a snapshot is cloned, it creates a dependency between the parent and child, and the original cannot be destroyed as long as the clone exists. The clone can be promoted, which then allows the original to be destroyed.

ZFS automatically manages mounting and unmounting file systems without the need to edit the /etc/fstab file. All automatically managed file systems are mounted by ZFS at boot time. 

A zfs dataset can be attached to a jail. A dataset cannot be attached to one jail and the children of the same dataset to other jails. 









### Other Operating Systems/Containers/Filesystems ###
While a combination of FreeBSD, Jails and ZFS have been recommended, you are free to use other operating systems like Windows or Linux, other container formats such as LXC or Zones, and other filesystems like BTRFS or EXT. The general concepts are interchangeable.

### Host Install Tools ###

### Ad-Hoc Change Tools ###
rsync. zfs send/receive.

[FreeBSD]: https://www.freebsd.org
[busiest web sites]: https://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/nutshell.html#introduction-nutshell-users
[NanoBSD]: https://www.freebsd.org/cgi/man.cgi?query=nanobsd


DNS
---
DNS is required to provide hostname to IP mapping. 

Querying the DNS for the IP address is a mechanism employed by almost all applications, therefore it is imperative that it is secured correctly. There are a few different options, namely, DNSSEC, DNSCrypt and DNSCurve.

In addition, a high emphasis on DNS security is required given that other security protocols are dependant upon it. For example, when a client connects to a server using SSH and the public key of the server is not known to the client, a fingerprint of the key is presented to the user for verification. This fingerprint can be stored in the DNS using SSHFP records so that the fingerprint can be verified out-of-band. TLS, which is commonly used for securing websites, can also use the DNS by storing certificates using TLSA records with DANE. 

This also means that whatever method that is used to secure DNS must be verified to be secure since the DNS is considered authoritative for the security of the domain. So in DNSSEC, the security of the domain is only as secure as the KSK, so it should be stored in a HSM.



### DNSSEC ###
DNSSEC creates a secure domain name system by adding cryptographic signatures to existing DNS records. These digital signatures are stored in DNS name servers alongside other record types like AAAA, MX etc. By checking the associated signature, you can verify that a DNS record comes from its authoritative name server and hasn't been altered. DNSSEC uses public key cryptography to sign and authenticate DNS resource record sets (RRsets). When requesting a DNS record, you can verify it comes from its authoritative name server and wasn't altered en-route by verifying its signature. 

New DNS record types were added to support DNSSEC:

- DNSKEY -  A zone signs its authoritative RRsets by using a private key and stores the corresponding public key in a DNSKEY RR. A resolver can then use the public key to validate signatures covering the RRsets in the zone, and authenticate them.
- RRSIG - Digital signatures are stored in RRSIG resource records and are used in the DNSSEC authentication process. A validator can use these RRSIG RRs to authenticate RRsets from the zone. A RRSIG record contains the signature for a RRset with a particular name, class, and type. The RRSIG RR specifies a validity interval for the signature and uses the Algorithm, the Signer's Name and the Key Tag to identify the DNSKEY RR containing the public key that a validator can use to verify the signature.
- NSEC and NSEC3 - The NSEC resource record lists two separate things: the next owner name that contains authoritative data or a delegation point NS RRset, and the set of RR types present at the NSEC RR's owner name. The complete set of NSEC RR's in a zone indicates which authoritative RRsets exist in a zone and also form a chain of authoritative owner names in the zone. This information is used to provide authenticated denial of existence for DNS data. To provide protection against zone enumeration, the owner names used in the NSEC3 RR are cryptographic hashes of the original owner name prepended as a single label to the name of the zone. The NSEC3 RR indicates which hash function is used to construct the hash, which salt is used, and how many iterations of the hash function are performed over the original owner name.
- DS - The DS resource record refers to a DNSKEY RR and is used in the DNS DNSKEY authentication process. A DS RR referes to a DNSKEY RR by storing the key tag, algorithm number, and a digest of the DNSKEY RR. By authenticating the DS record, a resolver can authenticate the DNSKEY RR to which the DS record points. The DS RR and its corresponding DNSKEY RR have the same owner name, but they are stored in different locations. The DS RR appears only on the upper (parental) side of a delegation. The corresponding DNSKEY RR is stored in the child zone. This simplifies DNS zone management and zone signing but introduces processing requirements for the DS RR, which can be solved using the CDS RR.
- CDNSKEY and CDS - The CDS and CDNSKEY resource records are published in the Child zone and give the Child control of what is published for it in the parental zone. The CDS/CDNSKEY RRset expresses what the Child would like the DS RRset to look like after the change using the CDS RR, or the DNSKEY RRset with the CDNSKEY RR.

Resource records of the same type are grouped together into a resource record set or RRset. The RRset is then digitally signed, rather than individual DNS records.

<img src="/homelab/pic/rrsets.svg">

The RRset is digitally signed by the private part of the zone signing key pair (ZSK). The digital signature is then stored in a RRSIG record. This proves that the data in the RRset originates from the zone.

<img src="/homelab/pic/zsk.svg">

The signature can be verified by recording the public part of the zone signing key pair in a DNSKEY record. The RRset, RRSIG and DNSKEY (public ZSK) can then be used by a resolver to validate the response from a name server.

<img src="/homelab/pic/zskverify.svg">

The DNSKEY records containing the public zone signing keys are then organised into a RRset, and signed by the Key Signing Key (KSK), which is stored in a DNSKEY record as well. This creates a RRSIG for the DNSKEY RRset.

<img src="/homelab/pic/ksk.svg">

The private key signing key signs a zone signing key which in turn will sign other zone data. The public key signing key is also signed by the private key signing key. The public KSK can then be used to validate the public ZSK.

<img src="/homelab/pic/kskverify.svg">

The DS RRset resides at a delegation point in a parent zone and indicates the public keys corresponding to the private keys used to self-sign the DNSKEY RRset at the delegated child zones apex. The public KSK in the child zone is hashed and stored in a DS record in the parent zone.

<img src="/homelab/pic/ds.svg">

Each time the child zone changes its KSK, the new public KSK needs to be transmitted to the parent zone in order to be stored in its DS record. In most cases this is a manual process, however, this can be mitigated by used CDS/CDNSKEY records. A CDS/CDNSKEY record contains the new information that the child zone would like to be published in the parent zone. These records only exist when the child zone wishes for the DS record in the parent zone to be changed. The parent zone should periodically check the child zone for the existence of CDS/CDNSKEY records, or can be prompted to do so.

<img src="/homelab/pic/cds.svg">

The above steps produce a trusted zone that connects to its parent, but the DS record in the parent zone also needs to be trusted. The signing process is repeated for the DS records in the DS RRset, and the process repeats up the parent zones in a chain up to the root zone. 

There are now two scenarios: 

- For public DNS servers, you are reliant on the trust given to the root zone owners that they have signed the root zone correctly and stored the private root signing key securely.
- For internal-only domains, the island of security approach means that the signed zone does not have an authentication chain to its parent.

<img src="/homelab/pic/chain.svg">

A basic guide of [how DNSSEC works] is found [on the CloudFlare blog].

When a DNS resolver is looking for www.example.com, the .com name servers help the resolver verify the records returned for example, and example helps verify the records returned for www. The root DNS name servers help verify .com, and information pusblished by the root is vetted at the Root Signing Ceremony


List of DNSSEC RFCs

- 1
- 2
- 3

[how DNSSEC works]: https://www.cloudflare.com/dns/dnssec/how-dnssec-works/
[on the CloudFlare blog]: https://blog.cloudflare.com/dnssec-an-introduction/


### DANE ###
DNS-Based Authentication of Named Entities or [DANE] allows certificates, used by TLS, to be bound to DNS names using DNSSEC. DANE allows you to authenticate the association of the server's certificate with the domain name without trusting an external certificate authority. Given that the DNS administrator is authoritative for the zone, it makes sense to allow the administrator to also be authoritative for the binding between the domain name and a certificate. This is done with DNS, and the security of the information is verified with DNSSEC.

DANE is implemented by placing TLSA records in the DNS.

TLS via DANE can be used to secure websites over HTTPS, email via the [OpenPGP] and [S/MIME] extensions, instant messaging (XMPP, IRC) and other applications via SRV records.

### DANE for Email Security ###
Since SMTP was designed to be transmitted in plaintext, encryption in the form of [STARTTLS] or [Opportunistic TLS] was developed to secure email communication. However, [it is known] to be [vulnerable to downgrade attacks], since the initial handshake occurs in plain text. An attacker could perform a man-in-the-middle attack by preventing the handshake from taking place and thus make it appear that TLS is unavailable, so clients revert to plain text.  

The Electronic Frontier Foundation ([EFF]) has created a project called [STARTTLS Everywhere] in an effort to enforce TLS between popular email domains, with the help of [Let's Encrypt] to serve certificates.

However, this is only to serve as an [intermediate solution] until [DNSSEC and DANE] see widespread adoption.

Our implementation includes DNSSEC and DANE, and so email protection will be available. However, since the infrastructure is not designed to be publicly accessible, some unique challenges surrounding maintenance of the DNS and CA root domains require solutions and also how to securely send between organisations needs to be determined.

While DANE can be used to validate the connection between mail exchangers, the emails themselves are still unencrypted. S/MIME and OpenPGP allow emails to be encrypted. There are also standards in place to store DANE bind

A guide to setting up DNSSEC+DANE to guarantee secure email between organisations is [published by NIST]. It shows the experiments carried out by Microsoft Corporation, NLnet Laboratories, Secure64, Internet Systems Consortium and Fraunhofer IAO, and includes the configuration required for their respective MUA, MTA and DNS services, including: 

- [Thunderbird]
- [Dovecot]
- [Postfix]
- [Outlook]
- [Exchange]
- [NSD]
- [Unbound]
- [OpenDNSSEC]
- [ISC BIND]

	Further guides published by NIST:

	- [Secure Domain Name System Deployment Guide]
	- [Trustworthy Email]


[STARTTLS]: https://tools.ietf.org/html/rfc3207
[Opportunistic TLS]: https://en.wikipedia.org/wiki/Opportunistic_TLS
[it is known]: https://blog.filipo.io/the-sad-state-of-smtp-encryption/
[vulnerable to downgrade attacks]: https://en.wikipedia.org/wiki/Opportunistic_TLS#Weaknesses_and_mitigations
[EFF]: https://www.eff.org
[STARTTLS Everywhere]: https://github.com/EFForg/starttls-everywhere
[Let's Encrypt]: https://letsencrypt.org
[intermediate solution]: https://github.com/EFForg/starttls-everywhere#alternatives
[DNSSEC and DANE]: https://tools.ietf.org/html/draft-ietf-dane-smtp-with-dane-10
[DANE]: https://tools.ietf.org/html/rfc6698
[OpenPGP]: https://tools.ietf.org/html/rfc7929
[S/MIME]: https://tools.ietf.org/html/draft-ietf-dane-smime-14
[published by NIST]: http://nccoe.nist.gov/sites/default/files/library/sp1800/dns-secure-email-sp1800-6-draft.pdf
[Thunderbird]: https://www.mozilla.org/en-GB/thunderbird/
[Dovecot]: https://www.dovecot.org
[Postfix]: http://www.postfix.org
[Outlook]: https://en.wikipedia.org/wiki/Microsoft_Outlook
[Exchange]: https://en.wikipedia.org/wiki/Microsoft_Exchange_Server
[NSD]: https://www.nlnetlabs.nl/projects/nsd/
[Unbound]: http://unbound.net
[OpenDNSSEC]: https://www.opendnssec.org
[ISC BIND]: https://www.isc.org/downloads/bind/
[Secure Domain Name System Deployment Guide]: http://dx.doi.org/10.6028/NIST.SP.800-81-2
[Trustworthy Email]: http://dx.doi.org/10.6028/NIST.SP.800-177

### DNSCrypt ###

### DNSCurve ###




LDAP
---
### LDAPS ###
### S/MIME or PGP ###

Kerberos
---


NTP
---

### NTPsec ###


NFS
---
### KerberizedNFSv4

Application Servers
---
### NGINX ###


Security and Crypto
---
### Against DNSSEC (and DANE) ###
- Cryptography worst practices, Daniel J. Bernstein [slides], [video]
- [DNSSEC in Chrome] (2014)
- [Why not DANE in browsers], Adam Langley (2015)

Counterpoints:

- [Dan Kaminsky]
- [EasyDNS]


[slides]: http://cr.yp.to/talks/2012.03.08-1/slides.pdf
[video]: https://vimeo.com/18279777
[Dan Kaminsky]: https://dankaminsky.com/2011/01/05/djb-ccc/
[EasyDNS]: http://blog.easydns.org/2015/08/06/for-dnssec/
[DNSSEC in Chrome]: https://groups.google.com/forum/#!topic/mozilla.dev.security/xylVm_kD_WE 
[Why not DANE in browsers]: https://www.imperialviolet.org/2015/01/17/notdane.html

### TLS ###

### SSH ###

The Secure Shell ([SSH]) protocol is used for secure remote login and tunneling other network services over an insecure network. SSH consists of three main components:

- Transport Layer Protocol - Provides server authentication, confidentiality, and integrity with perfect forward secrecy. The transport layer will typicall be run over a TCP/IP connection.
- User Authentication Protocol - Authenticates the client to the server. It runs over the transport layer protocol.
- Connection Protocol - Multiplexes the encrypted tunnel into several logical channels. It runs over the user authentication protocol.

Each server should have a host key. The host key is used during key exchange to verify that the client is talking to the correct server. The client must therefore have a priori knowledge of the servers host key. In order to accomplish this, two different methods are available, decentralised and centralised.

- Decentralised - The client manages a local database, in the form of an authorized_keys file. While this allows a peer to peer architecture, it also requires manually updating and validating new/revoked host keys. Each client becomes responsible for validating the servers that it connects to. This allows you to scale arbitrarily, at the expense of manageability.
- Centralised - The host keys are certified by a trusted third party, such as a certificate authority (CA) or via DNS(SEC). The client has knowledge of the CA root key or access to a validating DNS server. The validity of the host keys can be certified by accepted CAs or DNS servers. Consequently, each host key must be certified by the central authority before authorization is possible.

There is an option to defer checking the host key when connecting to host for the first time, however, this is not recommended and can be avoided by pre-seeding a public host key in the server build to allow connecting to the configuration management infrastructure and then changed at a later time.

**Transport Layer Protocol**

Authentication at this layer is host based, it does not perform user authentication. The key exchange method, public key algorithm, symmetric encryption algorithm, message authentication algorithm, and hash algorithm are all negotiated.

The client initiates the connection, usually using TCP/IP. Port 22 is the officially recognized port number, however, servers that expose this port to the public internet should choose a different port since it is usually scanned for by automated bots.

!!

An encryption algorithm and a key will be negotiated during the key exchange. Since the ciphers on the client and server are independent, they may differ. The key exchange occurs in order for the client and server to find a common cipher available to both. Data integrity is provided by including a message authentication code or MAC with each packet that is created from a shared secret, packet sequence number and the contents of the packet.

The key exchange algorithm decides the method which is used to perform the key exchange which specifies how one time session keys are generated for encryption and for authentication, and how the server authentication is done. 

Public key format, encoding and algorithm (signature and/or encryption)

!!

Key exchange starts with each side sending their lists of supported algorithms. Each side has a preferred algorithm in each category. 

**User Authentication Protocol**

When user authentication starts, it receives the session identifier from the transport layer. The session identifier uniquely identifies this session and is suitable for signing in order to prove ownership of a private key. The server drives the authentication by telling the client which authentication methods can be used, such as public key or password authentication.

In order to perform public key authentication, the client must be in possession of a private key. This method works by sending a signature created with a private key of the user. The server cheks that the key is a valid authenticator for the user, and checks that the signature is valid.

**Connection Protocol**

This layer provides interactive login sessions, remote execution of commands and forwarded TCP/IP connections, multiplexed into a single encrypted tunnel.

All terminal sessions, forwarded connections etc. are channels. Either side may open a channel. Multiple channels are multiplexed into a single connection. 


**First connection**

ssh obtains configuration data from sources in the following order:

- command-line options
- users configuration file (~/.ssh/ssh_config)
- system-wide configuration file (/etc/ssh/ssh_config)

The chosen options must also comply with the configurations specified in sshd_config on the receiving end.

The client sends its chosen algorithm details and key exchange method to the host. The host replies with its chosen algorithms. The two perform key exchange of the host keys. Once verified, the client sends the user authentication details. The host verifies these details. If verified, the host accepts the connection.

[SSH]: https://tools.ietf.org/html/rfc4251

**ssh_config**

- **Host** - restrict the following options (up to the next Host or Match) to be only used for those hosts matching the pattern.
- **AddressFamily inet6** - Use IPv6 only when connecting
- **CanonicalizeHostname** et al. - When an unqualified domain name is given as the SSH target, use the systems resolver to find the FQDN. The domain suffix is specified in CanonicalizeDomains. Can be set to strictly check so that if lookup fails within the specified domain, the SSH connection fails. This may be useful if unqualified names are used consistently, however, it adds another configuration file that is required to be maintained. !! Needs testing !!
- **CheckHostIP yes** - SSH will also check the host IP address in the known_hosts file, which would detect if a host key changed due to DNS spoofing. This will add addresses of destination hosts to ~/.ssh/known_hosts regardless of the setting of StrictHostKeyChecking. !! Needs testing !! 
- **Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com** - Prefer use of DJB's ciphers, fallback to AES GCM if necessary.
- **FingerprintHash sha256** - Prefer SHA256 over MD5 when displaying key fingerprints
- **HashKnownHosts yes** - SSH will hash host names and addresses when they are added to ~/.ssh/known_hosts. Hashed names can be used normally by SSH, but are unreadable to humans.
- **HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com** - Prefer use of DJB's cipher. 
- **KexAlgorithms curve25519-sha256@libssh.org** - Prefer use of DJB's cipher. Key Exchange Algorithms
- **MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com** - Encrypt then MAC, and SHA2 are preferred. When chacha20-poly1305@openssh.com is used, no MAC is used since Poly1305 is used as the MAC. The MAC algorithms listed here are used by AES GCM if available.
- **Protocol 2** - Explicitly disable Protocol 1, which suffers from cryptographic weaknesses.
- **PubkeyAcceptedKeyTypes ssh-ed25519-cert-v01@openssh.com** - Prefer use of DJB's cipher. Key types for public key authentication.
- **PubkeyAuthentication yes** - Use public key authentication
- **RevokedHostKeys KRL** - Specifies revoked public keys. Keys listed in this file will be refused for host authentication. The KRL can be generated with ssh-keygen. !! Introduces complexity, as the KRL must be updated whenever the host keys are changed. This may make host key rotation more difficult. This may be mitigated by storing host keys in DNS using SSHFP records, since removing the SSHFP RR from DNS is equivalent to revoking the key (this is specified in the VerifyHostKeyDNS setting below. !!

For host key checking, there are two options:

1. 

- **StrictHostKeyChecking yes** - SSH will never automatically add host keys to the ~/.ssh/known_hosts file, and refuses to connect to hosts whose host key has changed. This option forces the user to manually add all new hosts. !! This introduces additional complexity, as the known_hosts file must be managed manually. This option prevents connection to hosts that have had their host key changed, which is desirable, but it needs to be determined if this option works with automation. If a service account SSH's to a server, does it need to "accept" the key if it does not exist in the known_hosts file? The behaviour of this setting when used in conjunction with VerifyHostKeyDNS needs to be verified as well. Needs testing !!
- **UpdateHostKeys yes** - SSH accepts notifications of additional host keys from the server sent after authentication has completed and add them to the known_hosts file. This allows the server to provide alternate host keys and key rotation by sending replacement host keys before the old ones are removed. The keys are specified in sshd_config as "HostKey ssh_host_ed25519_key", and the new keys would also be specified: "HostKey ssh_host_ed25519_key_new". The old keys would then be removed at a later time. However, this requires a user to connect during the grace period in order for the new keys to be added to the known_hosts file. After this period, the keys must be verified as if you were connecting for the first time. 

These options would be preferred in a peer to peer / decentralised network, since it implies that each server manages its connections to other servers. This also requires users to regularly SSH to servers in order to maintain the known_hosts files.

2.

- **VerifyHostKeyDNS yes** - Specifies to verify the host key using DNS and SSHFP resource records. The client will implicitly trust keys that match a secure fingerprint from DNS. The integrity of the SSHFP resource records in DNS is provided by DNSSEC, since the SSHFP RRset is signed and the signature can be validated by resolvers. This option requires the servers to communicate their fingerprints to the DNS.

Since this option is reliant on DNS and that DNSSEC is set up correctly, it would be preferred to be used in centralised networks. 


**sshd_config**

- **AddressFamily inet6** - Use IPv6 only when connecting
- **AuthorizedKeysCommand** - Specifies a program to be used to look up the users public keys. !! We could use this to lookup users public keys stored in LDAP. !!
- **AuthorizedKeysFile ".ssh/authorized_keys"** - Specifies the file that contains the users public keys.
- **Banner none** - No banner message is displayed to the user before authentication.
- **Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com** - Prefer use of DJB's ciphers, fallback to AES GCM if necessary.
- **FingerprintHash sha256** - Prefer SHA256 over MD5 when displaying key fingerprints
- **HostKey /etc/ssh/ssh_host_ed25519_key** - Specifies the ed25519 host private key file.
- **HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com** - Prefer use of DJB's cipher. 
- **KexAlgorithms curve25519-sha256@libssh.org** - Prefer use of DJB's cipher. Key Exchange Algorithm.
- **MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com** - Encrypt then MAC, and SHA2 are preferred. When chacha20-poly1305@openssh.com is used, no MAC is used since Poly1305 is used as the MAC. The MAC algorithms listed here are used by AES GCM if available.
- **PasswordAuthentication no** - Disable password authentication
- **PermitRootLogin no** - Do not allow root login over SSH
- **PrintLastLog no** - Disables printing the date and time of the last user login. 
- **PrintMotd no** - Disables printing the /etc/motd when a user logs in.
- **PubkeyAcceptedKeyTypes ssh-ed25519-cert-v01@openssh.com** - Prefer use of DJB's cipher. Key types for public key authentication.
- **PubkeyAuthentication yes** - Use public key authentication
- **RevokedKeys KRL** - Specifies revoked public keys. Keys listed in this file will be refused for public key authentication. The KRL can be generated with ssh-keygen. !! Introduces complexity, as the KRL must be updated whenever the keys are changed. This may make host key rotation more difficult. This may be mitigated by storing host keys in DNS using SSHFP records, since removing the SSHFP RR from DNS is equivalent to revoking the key (this is specified in the VerifyHostKeyDNS setting below. !!
- **UseDNS yes** - Tells sshd to look up the remote host name and check that the resolved host name for the remote IP address maps back to the same IP address.


SSHFP records are generated by running "ssh-keygen -r $(hostname)".  

SSHFP records consist of three properties:

- Algorithm
- Fingerprint type
- Fingerprint in hexadecimal

The algorithm property we require is 4, which equates to ed25519. The fingerprint type we require is 2, which is SHA256, since it is preferred over SHA1. We can filter the output of "ssh-keygen -r" so that we only see SSHFP records with these properties. 

ssh-keygen -r $(hostname) | awk '$4 == 4 && $5 == 2 {print $0}'

The output is a list of SSHFP records in the format:

	hostname.fqdn IN SSHFP 4 2 4893752075487258092758094


### HSM ###
### Passwords ###
### TCP Wrapper ###
### IDS ###
### Firewalls ###

Configuration Management
---

Traditional system administration follows the "waterfall" method, where each step: gather requirements, design, implement, test, verify, deploy; is performed by a different team, and often conducted by hand. Each step or team has an end goal after which the product is handed over to the new team. The methodology documented in the papers at infrastructures.org, now referred to as DevOps, is the new way for managing infrastructures.

Features of this method include:

- Same Development and Operations toolchain
- Consistent software development life cycle
- Managed configuration and automation
- Infrastructure as code
- Automated provisioning and deployment
- Automated build and release
- Release packaging
- Abstracted administration

Continuous Delivery:

- The process for releasing/deploying must be repeatable and reliable
- Automate everything
- If something is difficult or painful, do it more often to improve and automate it
- Keep everything in source control
- "Done" means "released, working properly, in the hands of the end user"
- Build quality in
- Everybody has responsibility for the release process
- Improve continuously

The commands and philosphy throughout this document focus on using the native tools as part of the OS, rather than the commands for a specific configuration management tool. This is done so that the system administrators know what is being configured at the most basic level, and so they can use the tools manually or through shell scripts. It also means that the configurations will work independent of the configuration management tool that is chosen.


Authorisation / Access Control Lists
---
You can control access to objects using the ACL authorisation mechanism. 

Role-Based Access Control / Shared Administration (sudo)
---

Domain Naming Service
---

Directory Service (LDAP)
---

Time Service
---

Logging / Auditing
---

RPC / Admin service
---


!!

Designing for Operations
===

Specific Operational Requirements
---

- Configuration
- Startup and shutdown
- Queue draining
- Software upgrades 
- Backups and restores
- Redundancy
- Replicated databases
- Hot swaps
- Access controls and rate limits
- Monitoring
- Auditing

!!

### Configuration ### 
The configuration should be able to be backed up and restored. You should be able to view the difference between one version and the other. Archive the running configuration while the system is running. This is best done with text files, as they can be stored in existing version control systems

	- NanoBSD, conf file
	- Jails, conf file
	- Kerberos
	- OpenDNSSEC
	- SoftHSM
	- NSD
	- Unbound
	- OpenLDAP
	- OpenNTP
	- OpenSSH
	- Configuration Management
	- NFS

### Startup and shutdown ### 
Enter drain mode; Stop the applications (optional); Stop the jails (which should have scripts to stop the apps); Shutdown. Startup, start the jails on boot, mount and filesystems in jails; run apps check before saying ready; Exit drain mode.

### Queue draining ###
All requests are going through the load balancer, individual nodes can be put into drain mode.

### Software upgrades ###
For app upgrades, snapshot current, update app, restart jail with new updated app jail. For OS upgrades, build new offline image, update slice 2, reboot. 

### Backups and restores ###
Config files / OS files / data files

How to backup and restore:

	- Kerberos principals, groups etc.
	- LDAP data
	- DNS records/zones
	- HSM data

Calculate the latency/data limits required to perform above backups/restores

### Redundancy ###
OS, hard drive, zfs, multiple core servers with master/slave, database replication, multiple load balancers. Services are behind a load balancer

### Replicated databases ###

### Hot swaps ###
Physical components should be hot swappable. Service components should also be hot swappable.

### Access controls and rate limits ###
If a service provides an API, that API should include an Access Control List

### Monitoring ###
Configuration management tools typically monitor the OS / Application code is correct. Use normal network monitoring tools to monitor up/down, latency etc...

### Auditing ###
Logging to central servers

Unspecific Operational Requirements
---

### Assigning IPv6 Addresses to Clients ### 

### Static or Dynamic IPv6 Addresses (DHCPv6 or SLAAC) ###

### IPv6 Security ###
While SEND has been recommended to prevent spoofing attacks, it is non-trivial to deploy since it requires a trust anchor and CGA uses asymmetric key cryptography which is computationally expensive and may not be suitable on low-end devices. One alternative as proposed in [RFC6105]/[RFC7113], is Router Advertisement Guard (RA-Guard). This relies on an environment where all messages between IPv6 devices go through the controlled L2 networking devices. It then filters RAs based on a set of criteria, from simply "RA disallow on a given interface" to "RA allowed from SEND authorised sources only".

[RFC6105]: https://tools.ietf.org/html/rfc6105
[RFC7113]: https://tools.ietf.org/html/rfc7113


### Hostname Conventions ###

### Choosing an Operating System ###

### Choosing a Configuration Management Tool ###

### Scheduling with cron ###

The cron utility searches the user crontabs (/etc/cron.d on Linux or /var/cron/tabs on FreeBSD) for crontab files which are named after accounts in /etc/passwd. crontabs found are loaded into memory. A crontab file contains instructions to the cron daemon in the form "run this command at this time on this date". Each user has their own crontab, and commands in a crontab will be executed as the user who owns the crontab. The system crontab, /etc/crontab, should not be modified.

cron then wakes up every minute and checks all crontabs to see if a command should be run in the current minute. Before running a command from an account crontab, cron checks the status of the account with pam and skips the command if the account is locked out or expired. Commands from /etc/crontab bypass this check. 


Scaling
===
AKF Scaling Cube

- Replicate the entire system (horizontal duplication)
- Split the system into individual functions, services or resources (functional or service splits)
- Split the system into individual chunks (lookup or formulaic splits)

Horizontal - Many replicas behind a load balancer. If each transaction can be completed independently on all replicas, the performance improvement is proportional to the number of replicas, for example, adding more replicas, disk spindles or network connections.


!!

User Access
===
- Documents
- Applications
- Email
- Instant Messaging
- Working remotely

<!---

- Documents - Access documents through a website? Should be bound by authentication/authorisation. Version controlled documents. Like Sharepoint, but not terrible.
- Applications - web-access only preferred, TLS available, bound by authentication/authorisation. 
- Email - How does ProtonMail do it? Usually a lot of protections and anti-spam required, but if orgs are able to authoritativly validate each other, you are only able to receive emails from those orgs that have been validated, everything else is binned. Or if an org does spam, its quick to pinpoint and can be made untrusted.
- Instant Messaging - IRC with OTR, e.g. irc with PGP support.
- Working remotely - won't happen in a super-secure infra, but less secure may allow it. Could be done like MIT, with public SSH servers that require Kerberos name+pass and the user certificate. Then you could get X forwarded over SSH or instead of SSH, an SSL/TLS VPN that gives access to the internal network.

--->