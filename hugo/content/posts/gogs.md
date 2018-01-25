---
title: "Self-hosted git with Gogs"
date: 2018-01-25T22:15:59Z
draft: false
---

There is now a package for gogs so just

```
pkg install -y gogs
sysrc gogs_enable=YES
service gogs start
```

To compile

```
pkg install -y go git gcc
pw useradd git -m
su - git
GOPATH=$HOME/go; export GOPATH
echo 'GOPATH=$HOME/go; export GOPATH' >> ~/.profile
cc=gcc go get -u --tags sqlite github.com/gogits/gogs
ln -s go/src/github.com/gogits/gogs gogs
cd gogs
CC=gcc go build --tags sqlite

```

Set up the config file

```
mkdir -p custom/conf

vim custom/conf/app.ini

RUN_USER = git
RUN_MODE = prod

[database]
DB_TYPE = sqlite3
PATH = data/gogs.db

[repository]
ROOT = /home/git/gogs-repositories
SCRIPT_TYPE = sh

[server]
DOMAIN = localhost
ROOT_URL = http://localhost/
HTTP_PORT = 3000
LANDING_PAGE = explore

[session]
PROVIDER = file

[log]
MODE = file

[security]
INSTALL_LOCK = true
SECRET_KEY = supersecret

```

To run, as the git user run `/home/git/go/src/github.com/gogs/gogs web`

```
cp -v /home/git/go/src/github.com/gogits/gogs/scripts/init/freebsd/gogs /etc/rc.d
I needed to amend the gogs_directory path to be /home/git/go/src/github.com/gogits/gogs
chmod 555 /etc/rc.d/gogs
sysrc gogs_enable="YES"
service gogs start

```
