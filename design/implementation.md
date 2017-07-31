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


Implementation
===

The architecture described in the design is only aimed at the infrastructure setup, not application servers. Each of the services provided can be accessed by other architectures based on different operating systems. So for example, Windows and Linux infrastructures would still be able to query the DNS service without any extra configuration.

StrictHostKeyChecking vs VerifyHostKeyDNS Problem:
---

### Problem Statement ###

Do the StrictHostKeyChecking and VerifyHostKeyDNS options in ssh_config work together?

- StrictHostKeyChecking - If set to yes, ssh will never automatically add host keys to the known_hosts file and refuses to connect to hosts whose host key has changed(This is the preferred option). The host keys of known hosts will be verified automatically in all cases.
- VerifyHostKeyDNS - Specifies whether to verify the remote key using DNS and SSHFP resource records. If set to yes, the client implicitly trusts keys that match a secure fingerprint from DNS. Insecure fingerprints will be handled as if this option was set to ask. If this option is set to ask, information on fingerprint match will be displayed, but the user will still need to confirm new host keys according to the StrictHostKeyChecking option.

So if the fingerprint is presented from insecure DNS (not DNSSEC validated), or if the SSHFP record does not exist, does it prompt the user? We don't want this to happen since these SSH connections are happening autonomously.

Also need to check what happens if both options are set to yes.

So the host key is verified via DNS. If the fingerprint is correct it will connect. If it is incorrect, it will follow the StrictHostKeyChecking option, which when set to yes will refuse to connect to a host if its host key has changed.

If a host key is verified through DNS, is it still added to known_hosts? 
No, the host keys are only stored in the SSHFP records. This also means that when the host key is rotated, the SSHFP record needs to be updated once rather than having to amend the known_hosts file on every server that has ever connected.

SSH Host Key Rotation
---

How do you rotate SSH host keys and update the SSHFP records in DNS(SEC)?

requirement for renewal is initiated every x days/weeks
host generates new host keys
host connects to control machine, provides the new SSHFP values and asks for hosts SSHFP records to be updated
control machine updates DNS zone info with new SSHFP values
if update is successful, remove old values and resign zone. Inform host to remove old host keys
if update is unsuccessful, remove new values and report error.


SSHFP records are available as puppet facts. So if the puppet master is using puppetdb to store fact data, the SSHFP record for every node is stored and is available to query. This could be queried and then used to build up zone record data and published in DNS. Host key rotation could then be achieved by the nodes generating a new key, syncing facts with the puppet master which then in turn updates the DNS records.



Setting up IPsec Problem:
---

### Problem Statement ###

How do we set up IPsec between the control machine and machines it creates?

How do we set up IPsec between the router and machines communicating with it?

How do we set up IPsec between the router and other sites?

Assigning IP addresses to jails
---

It is not possible to assign IP addresses to jails using DHCP, they can only be assigned via jail.conf. This introduces the issue that a human would be required to find out a free address and manually enter it into the jail.conf, which becomes additionally complex with long and hard to remember IPv6 addresses. Some of this problem can be mitigated using variables for example by having the subnet prefix as a $PREFIX variable which can then be referenced as e.g. $PREFIX::d3d8. 

Another method available is the ip_hostname parameter in jail.conf which resolves the host.hostname parameters in DNS and all addresses returned by the resolver are added for the jail. So instead of entering the IP into jail.conf, a AAAA record would be manually entered into DNS and the jail would pick it up from there. 

Since only applications that require an external IP address are hosted inside jails, those applications should have a known IP address. This would be services like DNS, which needs a static and human-known IP address. These IP addresses could be hard coded into the DNS record available at the temporary DNS server (unbound) hosted on the control machine which is available during initial bootstrapping. The jails would then use the ip_hostname parameter to lookup their hostname in DNS, from which they would assign the jails IP address. Subsequent hosts would generate their IP address via SLAAC and DNS would be updated via puppet as normal.

Giving DNS server information to clients
---

Rather than manually configuring /etc/resolv.conf for the location of the local DNS servers, this information can be provided either by the router or DHCP server. If you do not want to run a DHCP server and rely solely on SLAAC for address allocation, then you can have the router provide the DNS information. Otherwise, the DHCP server can provide the DNS information. [RFC8106]

[RFC8106]: https://tools.ietf.org/html/rfc8106

The major benefit of this approach is that you do not have to make any manual configurations for the location of the DNS servers on any of your clients. However, one of the drawbacks is experienced during the initial bootstrap when the DNS servers do not yet exist. So the DNS servers will need to have their stub resolvers configured manually.

Since we have a robust DNSSEC implementation available, it makes sense to store as much crypto/public keys in there as possible rather than having them spread over multiple mechanisms. So rather than TLS certs in 3rd party PKI, SMIME certs in LDAP, SSH host keys in known_hosts files and IPsec public keys distributed manually, you can have TLSA, SMIMEA, SSHFP and IPSECKEY Resource Records stored securely in DNS.

It is also important for us to have this information in DNS so that it can potentially be referenced by other organisations. If another org needs to access a website, it needs to be secured with TLS which is validated by the TLSA record via DANE. Likewise, if a person in another organisation wants to send an email, they need to know the TLS cert to secure the TLS communication and also the SMIME certificate to encrypt the email itself. By publishing the TLSA record and SMIMEA records in DNS, the other organisation can access this information and be confident that the records are accurate.

IP addresses that need to be known by a human
---

- Router(s)
- Control Machine(s)
- DNS servers



Resource records to be stored in DNS(SEC):
---

Static:

- DNS servers
- Hostname to static IP for infrastructure servers
- CNAMES for standard services (auth.example.com, dns.example.com)
- MX records

Dynamic:

- Hostname to dynamic IP for app/other servers
- SSHFP records
- IPSECKEY records
- TLSA records (for all web/app servers)
- SMIMEA (for each user)



Bootstrap
===


Version Control
---

Version control is used to track OS configuration files, OS and application binaries/source code and configuration management tool files. The version control tools and repositories should be shared by both infrastructure and applications files. 

While third party hosted services are available, these options are unavailable to an infrastructure with limited internet access. There should also be no need for a dependency on third party infrastructure. In addition, it is often the case that company-confidential data is stored in version control, and the organisation should be encouraged to use version control as much as possible and this is a barrier. 

The other option is to self host. There are a number of options including git and subversion. choose the tool that is best suited to your organisation. git has been chosen as it is open source, familiar to most people and easy to pick up.



Since Git is a collaborative tool, it is common to install a web version of git such as GitLab to give people a GUI. This is organisation specific, for our use case we will just have git repos stored on a specific server/storage area. All of the tools available to git are usable in the git package.

Git is also a requirement for R10K, which is used by puppet for managing environments and automatically pushing changes when git commits are detected.

The configuration for your infrastructure will be stored in git repos, in the form of a puppet control repository for managing puppet environments and also the repo for hosting your infrastructure hardware config. This might be in many different formats, due to the many different platforms available (bare-metal, virtual, cloud). Throughout this design, it assumed that the infrastructure is built on bare metal by default or virtual if deployed in existing environments. Cloud is not considered because they are inherently hosted externally which is not possible in a secure environment. While private cloud options are avaiable, this configuration is way overkill for this design. The design has been purposely built to be lightweight.

The Hashicorp ecosystem is a well defined and supported method for managing the infrastructure code. The configuration is defined in Terraform, and can be tested using Vagrant provisioning local VMs or cloud instances. Immutable images can be built with the help of Packer.

While NanoBSD was considered in the past, zfs boot environments are now used.


Implementation
===



Provisioning
===

IPv6
---

### Address Autoconfiguration (SLAAC) ###

### SEND ###

### SEND SAVI ###

### DHCPv6 ###

### IPsec ###

OS
---

### FreeBSD ###

### Jails ###

### ZFS ###

### Host Install Tools ###

### Ad-Hoc Change Tools ###

Configuration Management
===

DNS
---

### DNSSEC ###

### DANE ###

### DANE/SMIMEA for Email Security ###

### S/MIME or PGP ###

Kerberos
---


NTP
---

### NTPsec ###


App Deployment
===

Application Servers
---

### NGINX ###


Security and Compliance
===

Security and Crypto
---

### TLS ###

### SSH ###

### HSM ###
### Passwords ###
### TCP Wrapper ###
### IDS ###
### Firewalls ###

Configuration Management Tools
---

Authorisation / Access Control Lists
---

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

Orchestration
===

Specific Operational Requirements
---

### Configuration ### 

### Startup and shutdown ### 

### Queue draining ###

### Software upgrades ###

### Backups and restores ###

### Redundancy ###

### Replicated databases ###

### Hot swaps ###

### Access controls and rate limits ###

### Monitoring ###

### Auditing ###

Unspecific Operational Requirements
---

### Assigning IPv6 Addresses to Clients ### 

### Static or Dynamic IPv6 Addresses (DHCPv6 or SLAAC) ###

### IPv6 Security ###

### Hostname Conventions ###

### Choosing an Operating System ###

### Choosing a Configuration Management Tool ###

### Scheduling with cron ###

Scaling
===

User Access
===
