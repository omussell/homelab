---
title: "Buildbot"
date: 2018-01-25T22:19:58Z
draft: false
---

Install the buildbot master
---

```
pkg install -y py36-buildbot py36-buildbot-www
```

You need to create the config files directory

```
buildbot create-master master
cd ./master
cp master.cfg.sample master.cfg
buildbot start master
(look at twistd.log if there are errors during startup)
```

Enable the services and start

```
sysrc buildbot_enable="YES"
sysrc buildbot_basedir="/var/www/buildbot"
service buildbot start
```

Access via a browser at http://$IP:8010/

If using the localworker for testing: `pkg install -y py36-buildbot-worker`

With postgres backend:

```
master.cfg
c['db'] = {
	'db_url' : "postgresql://buildbot:password@192.168.1.10/buildbotdb",
}

pip install psycopg2
```
Install a buildbot worker
---

Install the package and enable 

```
pkg install -y py27-buildbot-worker
sysrc buildbot_worker_enable=YES
sysrc buildbot_basedir="/usr/local/etc/buildbot_worker"
```

Before you start the worker, you need to create its config
```
buildbot-worker create-worker <basedir> 		     <master_name> <worker_name> <worker_password>
buildbot-worker create-worker /usr/local/etc/buildbot_worker 192.168.1.19  foo 		 pass
```

Start the service

```
service buildbot_worker start
```

The config file on the master will then need updating with the worker name and password, and optionally add it to be used for specific builds.
