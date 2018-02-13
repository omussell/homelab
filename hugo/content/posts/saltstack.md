---
title: "Saltstack Install and Configuration"
date: 2018-01-25T21:59:48Z
draft: false
---

Install the salt package

```
pkg install -y py36-salt
```

Copy the sample files to create the master and/or minion configuration files

```
cp -v /usr/local/etc/salt/master{.sample,""}
cp -v /usr/local/etc/salt/minion{.sample,""}
```

Set the master/minion services to start on boot

```
sysrc salt_master_enable="YES"
sysrc salt_minion_enable="YES"
```

Salt expects state files to exist in the /srv/salt or /etc/salt directories which don't exist by default on FreeBSD so make symlinks instead:

```
ln -s /usr/local/etc/salt /etc/salt
ln -s /usr/local/etc/salt /srv/salt
```

Start the services

```
service salt_master onestart
service salt_minion onestart
```

Accept minion keys sent to the master

```
salt-key -A
# Press y to accept
```

Create a test state file

```
vi /usr/local/etc/salt/states/examples.sls
```

```
---

install_packages:
  pkg.installed:
    - pkgs:
      - vim-lite
```

Then apply the examples state

```
salt '*' state.apply examples
```

Salt Formulas
---

Install the GitFS backend, this allows you to serve files from git repos.

```
pkg install -y py36-gitpython
```

Edit the `/usr/local/etc/salt/master` configuration file:

```
fileserver_backend:
  - git
  - roots
gitfs_remotes:
  - https://github.com/saltstack-formulas/lynis-formula
```

Restart the master. If master and minion are the same node, restart the minion service as well.

```
service salt_master onerestart
```

The formulas can then be used in the state file

```
include:
  - lynis
```

Salt equivalent to R10K and using git as a pillar source
--- 

If the git server is also a minion, you can use Reactor to signal to the master to update the fileserver on each git push:

`https://docs.saltstack.com/en/latest/topics/tutorials/gitfs.html#refreshing-gitfs-upon-push`

You can also use git as a pillar source (host your specific config data in version control)

`https://docs.saltstack.com/en/latest/topics/tutorials/gitfs.html#using-git-as-an-external-pillar-source`


Installing RAET
---

RAET support isn't enabled in the default package. If you install py27-salt and run `pkg info py27-salt` you can see in the options `RAET: off`. In order to use RAET, you need to build the py27-salt port.

Compile the port

```
pkg remove -y py27-salt
portsnap fetch extract
cd /usr/ports/sysutil/py-salt
make config
# Press space to select RAET
make install
```

Edit `/srv/salt/master` and `/srv/salt/minion` and add

```
transport: raet
```

Then restart the services

```
service salt_master restart
service salt_minion restart
```

You will need to accept keys again

```
salt-key 
salt-key -A
```


Salt equivalent of hiera-eyaml
---

Salt.runners.nacl

Similar to hiera-eyaml, it is used for encrypting data stored in pillar:

`https://docs.saltstack.com/en/latest/ref/runners/all/salt.runners.nacl.html`

