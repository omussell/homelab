---
title: "Buildbot"
date: 2018-01-25T22:19:58Z
draft: false
---

Install the buildbot master

```
pkg install -y buildbot buildbot-www
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

If using the localworker for testing: `pkg install -y buildbot-worker`

With postgres backend:

```
master.cfg
c['db'] = {
    'db_url' : "postgresql://buildbotuser:testpass@localhost/buildbotdb",
}

pip install psycopg2
```
