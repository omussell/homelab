## Taiga (Project Management application)

pkg install -y gcc py36-libxml2 py36-lxml py36-pillow gettext
setenv CC gcc
pip install -r requirements
cp -v settings/local.py.example settings/local.py


./manage.py migrate --noinput
./manage.py loaddata initial_user
./manage.py loaddata initial_project_templates
./manage.py compilemessages
./manage.py collectstatic --noinput
# sample_data takes forever...
./manage.py sample_data




frontend:
deactivate venv
pkg install -y python2

edit conf.json, use correct IP address
serve static files using NGINX as per production instructions



## Massively scalable Web Applications

HTTPS Request -> Hitch <-> Varnish <-> Varnish ESI <-> NGINX <-> NGINX Unit

Scaling cube:
X - Horizontal - More servers
Y - Vertical - Bigger servers
Z - Depth - Sharding

X - Scale by adding more servers of same size. Requests can be evenly distributed amongst them.
Y - Give more CPU+RAM to servers
Z - Distribute requests to specific groups of servers. Maybe geo location so servers are specific to a region. Maybe for caching its splitting the cache up into partitions.

## Architecture

### TLS Termination
HTTPS to the edge. This is the main interface for users to the web application. Usually paired with load balancers to manage traffic ingress.

### Caching
Cache some content to improve resource load times

### Dynamic Content
Resources that can't be cached, and should be passed to the application server to be generated

### Proxying and authentication
Routing requests to the correct application server. Using API keys for authentication.

### Application server
The application running as a web server to receive uncacheable requests

## Example Architecture

### TLS Termination - Hitch

[Hitch](https://hitch-tls.org) is an implementation of a TLS proxy by the makers of Varnish. It is simple and performs one job.

X - Multiple hitch servers behind load balancer
Y - Bigger servers
Z - Load balancers for specific geo regions. Load balancers for specific domains so hitch servers only get a subset of requests.


### Caching - Varnish
X - Multiple varnish caches. Maybe shared cache.
Y - Bigger servers. More RAM means more content can be cached.
Z - Sharded cache objects

### Dynamic Content - Varnish Edge Side Includes / VCL Pipe
X - 
Y - 
Z - 

### Proxying and authentication - NGINX
X - 
Y - 
Z - 
### Application server - NGINX Unit
X - 
Y - 
Z - 

## Alternative Example architecture
One issue with the architecture described above is that communication between layers is done via HTTP rather than HTTPS. Hitch and Varnish do not support HTTPS backends.

An alternative would be to use NGINX for all layers, since it can use HTTPS upstreams.

## NGINX TCP/UDP proxy

NGINX needs to be compiled with the --with-stream option. It can't be dynamic, which is the default. In the config file you need to add:

```
load_module /usr/local/libexec/nginx/ngx_stream_module.so;
```

Then in the config file:

```
stream {

  server {

    listen 80;
    proxy_pass 192.168.1.15:80;

  }

  server {

    # Override the default stream type of TCP with UDP
    listen 53;
    proxy_pass 192.168.1.15:53 udp;

  }

}
```

## NGINX Unit

NGINX Unit running a django app. 

```
pkg install -y python36 py36-sqlite3 unit py36-unit
sysrc unitd_enable="YES"
service unitd start
```

Unit is controlled by a sockfile, which by default is `/var/run/unit/control.unit.sock`

Get the current running config:

```
curl --unix-socket /var/run/unit/control.unit.sock http://localhost/config
```

Put a new config in place from a file:

```
curl -X PUT -d @/home/seagull/mysite/config.json --unix-socket /var/run/unit/control.unit.sock http://127.0.0.1/config
```

The config file:

```
{
        "listeners": {
                "127.0.0.1:8300": {
                        "application": "mysite"
                }
        },

        "applications": {
                "mysite": {
                        "type": "python3.6",
                        "processes": 5,
                        "path": "/home/seagull/mysite/",
                        "home": "/home/seagull/venv/",
                        "module": "mysite.wsgi",
                        "user": "seagull",
                        "group": "seagull"
                }
        },

        "access_log": "/var/log/unit/access.log"
}

```

## Odoo ERP/CRM

[Odoo](https://www.odoo.com) is an open source ERP/CRM solution. It uses Python and PostgreSQL for the backend and simply Less CSS for the frontend.

Download the source code

`git clone https://github.com/odoo/odoo.git --branch 11.0 --depth 1`

Install the dependencies

```
pkg install -y git python35 postgresql10-server postgresql10-client

#Pillow deps: 
pkg install -y jpeg-turbo tiff webp lcms2 freetype2 libxslt

#LDAP install doesnt work out of the box:
pkg install -y openldap-client
cp -v /usr/local/include/lber.h $venv/include
```

Install requirements

`pip install -r requirements.txt`

Create the default database and role

```
create role odoo with password 'odoo';
alter role odoo with login;
alter role odoo with createdb;
create database odoo with owner odoo;
```

Frontend setup

```
pkg install -y npm node-npm8

#For some reason npm kept crashing but installing a previous version of npm works?

npm install -g npm@5.6.0

npm install less
```

Run the service:

`./odoo-bin --config ./local.cfg`

A rc.d script does not exist, so that would need to be created manually, which shouldn't be too difficult.

Default admin login didnt work so not sure what admin_password in the config file is doing, it doesnt work...

Click on the manage databases button and create a database
This creates a new database in postgresql, hence the createdb perms required on the role

You also need to change the dbfilter setting to allow access to that database

Attachments appear to be stored in the database by default (wow...). 

Set data_dir = $filepath to store documents / attachments on the filesystem rather than in the database. It stores binary files with long random strings for the names. The file information is stored in the ir_attachment table. If you inspect the web page via Chrome devtools, look at the network tab and click on the file download, you can see in the form data the id and filename which can be queried in the database for the correct info.

Otherwise just `select * from ir_attachment where name like '%Williams%';`

```
test=# select * from ir_attachment where id = 441;
 id  |      name       |   datas_fname   | description |  res_name  |  res_model   | res_field | res_id |        create_date         | create_uid | company_id |  type  | url | public | access_token | db_datas |                 store_fname                 | file_size |                 checksum                 |      mimetype      | index_content | write_uid |         write_date
-----+-----------------+-----------------+-------------+------------+--------------+-----------+--------+----------------------------+------------+------------+--------+-----+--------+--------------+----------+---------------------------------------------+-----------+------------------------------------------+--------------------+---------------+-----------+----------------------------
 441 | Williams_CV.doc | Williams_CV.doc |             | Programmer | hr.applicant |           |      8 | 2018-08-27 14:44:24.955914 |          1 |          1 | binary |     | f      |              |          | f8/f82ead4ee74f14d9bdecdb38272c17cfd732fd7a |     10240 | f82ead4ee74f14d9bdecdb38272c17cfd732fd7a | application/msword | application   |         1 | 2018-08-27 14:44:24.955914
(1 row)

```


## ZFS BE + PkgBase

### ZFS Boot Environments

With a standard zfs on root set up, you have one zpool with all the mount points on a ZFS dataset within the pool. With ZFS boot environments, you have a zpool with one or more ZFS datasets, where each dataset contains the whole kernel+base. The bootfs value of the zpool can be changed between the different ZFS datasets to change which is booted into. 

An incredibly simple ZFS BE can be created by creating a new ZFS dataset, extracting the kernel/base tarballs to it and then setting the bootfs property to that dataset. 

ZFS BE's can be started as a jail, or even as a bhyve VM if the kernel also needs to be tested. Once the BE has been tested and confirmed to be working, you can use zfs send/recv to distribute the dataset to other machines.

### PkgBase

Packaging the FreeBSD base system (including kernel). At the moment the entirety of the kernel or base are compiled and distributed as single tarballs. Coming in the 12.0 release is the ability to have a packaged base system using the pkg tool. This means that both base and third party software are managed by pkg instead of having freebsd-update et al plus pkg. 

With PkgBase we can specify what base packages to include in our installation rather than having to compile it manually or use something like NanoBSD. This leads to smaller and specialised images with reduced attack surface.

### ZFS BE + PkgBase working together

So if a ZFS BE is just a dataset with kernel/base files and PkgBase lets us control the base system with packages, we can instead create a ZFS dataset and install the packages as needed into the dataset instead. In this way we can have a specialised ZFS BE that is easy to control with pkg.


## Handling Go Dependencies

During development, you will often use `go get` to download libraries for import into the program which is useful for development but not so useful when building the finished product. Managing these dependencies over time is a hassle as they change frequently and can sometimes disappear entirely.

The `dep` tool provides a way of automatically scanning your import statements and evaluating all of the dependencies. It create some files `Gopkg.toml` and `Gopkg.lock` which contain the location and latest Git SHA of your dependencies.

`dep` is installed via `curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh`

Run `dep init` to create the initial files, then as your develop run `dep ensure` to update dependencies to the latest version.

The `dep` tool also downloads a copy of all dependencies into a `vendor` folder at the root of your project. This provides a backup in case a dependency disappears and provides the facility for reproducible builds.


### Bazel / Gazelle

With our dependencies being updated, we would also need to update the WORKSPACE file so that Bazel/Gazelle knows about them as well. Gazelle requires the location and git commit hash in order to pull down the correct dependencies, but this is laborious to update manually.

Thankfully, we can run a command to have gazelle pull in all of the dependencies from the `Gopkg.lock` file and update the WORKSPACE file automatically. Bazel will then pull in all of the dependencies correctly without any manual intervention.

`gazelle update-repos -from_file Gopkg.lock`

As part of ongoing development, you would periodically run

`dep ensure` 

followed by

`gazelle update-repos -from_file Gopkg.lock`

to keep all of the dependencies up to date and generate the new WORKSPACE file.

## Packaging Go Applications

Now that we've built the go application and its dependencies we now need to package it up to distribute across the infrastructure.


### Packaging with fpm

The below command is an example of what we would want to run:


`fpm -s dir -t freebsd -n ~/go_test --version 1.0.0 --prefix /usr/local/bin go_tests`

But this has a few issues. Rather than putting the finished package into `~/go_test`, it would be better in a dedicated directory like `/var/packages` or similar. The version number is hard coded which obviously isn't always going to be correct. You would want to instead have your CI tool set to only run the packaging command when a new tag/release is created, and then have the version number derived from the tag/release number. It also includes the `--prefix` flag to specify the path to prepend to any files in the package. This is required as when the package is installed/extracted, the files will be extracted to the full path as specified in the package. So in this instance the `/usr/local/bin/go_tests` file is extracted.


For now, I'm getting by with the following command which will overwrite the finished package if it already exists.

`fpm -f -s dir -t freebsd -n ~/go_test --prefix /usr/local/bin go_tests`


## Building Go programs using Bazel

Bazel is a build tool created by Google which operates similarly to their internal build tool, Blaze. It is primarily concerned with generating artifacts from compiled languages like C, C++, Go etc. 

`pkg install -y bazel`

Bazel requires some files so that it knows what and where to build. As an example, we are going to compile a simple go program with no dependencies (literally print a single string to stdout).

```
// ~/go/src/github.com/omussell/go_tests/main.go

package main

import "fmt"

func main() {
	fmt.Println("test")
}
```

A file called WORKSPACE should be created at the root of the directory. This is used by bazel to determine source code locations relative to the WORKSPACE file and differentiate other packages in the same directory. Then a BUILD.bazel file should also be created at the root of the directory. 




### Gazelle

Instead of creating BUILD files by hand, we can use the Gazelle tool to iterate over a go source tree and dynamically generate BUILD files. We can also let bazel itself run gazelle.

Note that gazelle doesn't work without bash, and the gazelle.bash file has a hardcoded path to `/bin/bash` which of course is not available on FreeBSD by default.

```
pkg install -y bash
ln -s /usr/local/bin/bash /bin/bash
```

In the WORKSPACE file:

```
http_archive(
    name = "io_bazel_rules_go",
    url = "https://github.com/bazelbuild/rules_go/releases/download/0.9.0/rules_go-0.9.0.tar.gz",
    sha256 = "4d8d6244320dd751590f9100cf39fd7a4b75cd901e1f3ffdfd6f048328883695",
)
http_archive(
    name = "bazel_gazelle",
    url = "https://github.com/bazelbuild/bazel-gazelle/releases/download/0.9/bazel-gazelle-0.9.tar.gz",
    sha256 = "0103991d994db55b3b5d7b06336f8ae355739635e0c2379dea16b8213ea5a223",
)
load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains(go_version="host")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
gazelle_dependencies()
```

In the BUILD.bazel file:

```
load("@bazel_gazelle//:def.bzl", "gazelle")

gazelle(
    name = "gazelle",
    prefix = "github.com/omussell/go_tests",
)
```

Then to run:

```
bazel run //:gazelle
bazel build //:go_tests
```

A built binary should be output to the ~/.cache directory. Once a binary has been built once, Bazel will only build again if the source code changes. Otherwise, any subsequent runs just complete successfully extremely quickly.

When attempting to use bazel in any capacity like `bazel run ...` or `bazel build ...` it would give the following error:

```
ERROR: /root/.cache/bazel/_bazel_root/b3532a61fb0a1349ae431191285a1776/external/io_bazel_rules_go/
BUILD.bazel:7:1: every rule of type go_context_data implicitly depends upon the target '@go_sdk//
:packages.txt', but this target could not be found because of: no such package '@go_sdk//': 
Unsupported operating system: freebsd
ERROR: /root/.cache/bazel/_bazel_root/b3532a61fb0a1349ae431191285a1776/external/io_bazel_rules_go/
BUILD.bazel:7:1: every rule of type go_context_data implicitly depends upon the target '@go_sdk//
:files', but this target could not be found because of: no such package '@go_sdk//': 
Unsupported operating system: freebsd
ERROR: /root/.cache/bazel/_bazel_root/b3532a61fb0a1349ae431191285a1776/external/io_bazel_rules_go/
BUILD.bazel:7:1: every rule of type go_context_data implicitly depends upon the target '@go_sdk//
:tools', but this target could not be found because of: no such package '@go_sdk//': 
Unsupported operating system: freebsd
ERROR: Analysis of target '//:gazelle' failed; build aborted: no such package '@go_sdk//': 
Unsupported operating system: freebsd
```

I think this is caused by bazel attempting to download and build go which isn't necessary as we've already installed via the package anyway. In the WORKSPACE file, change the `go_register_toolchains()` line to `go_register_toolchains(go_version="host")` as documented at https://github.com/bazelbuild/rules_go/blob/master/go/toolchains.rst#using-the-installed-go-sdk. This will force bazel to use the already installed go tools.

## CI with Buildbot


Example buildbot config:

```
factory.addStep(steps.Git(repourl='git://github.com/omussell/go_tests.git', mode='incremental'))
factory.addStep(steps.ShellCommand(command=["go", "fix"],))
factory.addStep(steps.ShellCommand(command=["go", "vet"],))
factory.addStep(steps.ShellCommand(command=["go", "fmt"],))
factory.addStep(steps.ShellCommand(command=["bazel", "run", "//:gazelle"],))
factory.addStep(steps.ShellCommand(command=["bazel", "build", "//:go_tests"],))
```

I needed to rebuild the buildbot jail because it was borked, and after rebuilding it I was surprised that bazel worked without any more configuration. I just needed to install the git, go and bazel packages and run the buildbot config as described above and it ran through and rebuilt everything from scratch. This is one of the major advantages of keeping the build files (WORKSPACE and BUILD.bazel) alongside the source code. I am sure that if desired, anyone with a bazel setup would be able to build this code as well and the outputs would be identical.


### Adding dependencies

In order to have Bazel automatically build dependencies we need to make a some changes to the WORKSPACE file. I've extended the example program to pull in a library that generates fake data and prints a random name when invoked.


```
package main

import "github.com/brianvoe/gofakeit"
import "fmt"

func main() {
        gofakeit.Seed(0)
        fmt.Println(gofakeit.Name())
        //      fmt.Println("test")
}
```

The following needs to be appended to the WORKSPACE file:

```
load("@io_bazel_rules_go//go:def.bzl", "go_repository")

go_repository(
    name = "com_github_brianvoe_gofakeit",
    importpath = "github.com/brianvoe/gofakeit",
    commit = "b0b2ecfdf447299dd6bcdef91001692fc349ce4c",
)
```

The go_repository rule is used when a dependency is required that does not have a BUILD.bzl file in their repo.

## PostgreSQL 10.1 with replication

```
pkg install -y postgresql10-server postgresql10-client
sysrc postgresql_enable=YES
service postgresql initdb
service postgresql start
```

### PostgreSQL 10.1 SCRAM Authentication

```
su - postgres
psql
set password_encryption = 'scram-sha-256';
create role app_db with password 'foo';
select substring(rolpassword, 1, 14) from pg_authid where rolname = 'app_db';
```

### PostgreSQL 10.1 using repmgr for database replication, WAL-G for WAL archiving, and minio for S3 compatible storage

For this, I created two bhyve VMs to host postgresql and a jail on the host for minio

Make sure postgresql is running

Carry out the following steps on both primary and replicas

The current packaged version of repmgr is 3.3.1 which isn't the latest. The latest is 4.0.1, so we need to compile it ourself, and put files into the correct locations

```
fetch https://repmgr.org/download/repmgr-4.0.1.tar.gz
tar -zvxf repmgr-4.0.1.tar.gz
./configure
pkg install -y gmake
gmake
```

Copy the repmgr files to their correct locations

```
cp -v repmgr /var/db/postgres
cp -v repmgr--4.0.sql /usr/local/share/postgresql/extension/
cp -v repmgr.control /usr/local/share/postgresql/extension
```


vim /var/db/postgrs/data10/postgresql.conf 

Add lines: 

```
include_dir = 'postgresql.conf.d'
listen_addresses = '\*'
```

vim /var/db/postgres/data10/postgresql.conf.d/postgresql.replication.conf

Add lines:

```
max_wal_senders = 10
wal_level = 'replica'
wal_keep_segments = 5000
hot_standby = on
archive_mode = on
archive_command = 'wal-g stuff here'
```

vim /var/db/postgres/data10/pg_hba.conf

Add lines:
Please note, for testing purposes, these rules are wide open and allow everything. Dont do this in production, use a specific role with a password and restrict to a specific address

```
local	all		all			trust
host	all		all	0.0.0.0/0	trust
host	replication	all	0.0.0.0/0	trust
```

vim /usr/local/etc/repmgr.conf

Add lines:

```
node_id=1 # arbitrary number, each node needs to be unique
node_name=postgres-db1 # this nodes hostname
conninfo='host=192.168.1.10 user=repmgr dbname=repmgr' # the host value should be a hostname if DNS is working
```

On the primary

```
su - postgres
createuser -s repmgr
createdb repmgr -O repmgr

repmgr -f /usr/local/etc/repmgr.conf primary register
repmgr -f /usr/local/etc/repmgr.conf cluster show
```

On a standby

```
su - postgres
psql 'host=node1 user=repmgr dbname=repmgr'
```

To clone the primary, the data directory on the standby node must exist but be empty

```
rm -rf /var/db/postgres/data10/
mkdir -p /var/db/postgres/data10
chown postgres:postgres /var/db/postgres/data10
```

Dry run first to check for problems

`repmgr -h node1 -U repmgr -d repmgr -f /usr/local/etc/repmgr.conf standby clone --dry-run`

If its ok, run it

`repmgr -h node1 -U repmgr -d repmgr -f /usr/local/etc/repmgr.conf standby clone`

On the primary

```
su - postgres
psql -d repmgr
select * from pg_stat_replication;
```

On the standby

```
repmgr -f /usr/local/etc/repmgr.conf standby register
repmgr -f /usr/local/etc/repmgr.conf cluster show
```

Install minio

```
pkg install -y minio
sysrc minio_enable=YES
sysrc minio_disks=/home/user/test
mkdir -p /home/user/test
chown minio:minio /home/user/test
service minio start
# The access keys are in /usr/local/etc/minio/config.json
# You can change them in this file and restart the service to take effect
```

On the primary
WAL-G

```
pkg install -y go
mkdir -p /root/go
setenv GOPATH /root/go
cd go
go get github.com/wal-g/wal-g
cd src/github.com/wal-g/wal-g
make all
make install
cp /root/go/bin/wal-g /usr/local/bin
```

WAL-G requires certain environment variables to be set. This can be done using envdir, part of the daemontools package

pkg install -y daemontools

Setup is now complete. 

For operations, a base backup needs to be taken on a regular basis probably via a cron job, running the following command as postgres user

`wal-g backup-push /var/db/postgres/data10`

Then the archive_command in the postgresql.replication.conf should be set to the wal-push command

`wal-g wal-push /var/db/postgres/data10`

To restore, backup-fetch and wal-fetch can be used to pull the latest base backup and the necessary wal logs to recover to the latest transaction


## Static sites with Hugo

```
# note 'hugo' is not the right package. It is completely different and 
# will take a long time to download before you realise its the wrong thing.
pkg install -y gohugo git
```

Run `hugo` in the directory to build the assets, which will be placed into the public directory. 

Run `hugo server --baseUrl=/ --port=1313 --appendPort=false`

Note that the baseURL is /. This is because it wasn't rendering the css at all when I used a server name or IP address. In production, this should be the domain name of the website followed by a forward slash.

You can then visit your server at port 1313. 

For the baseUrl when using github pages, you should use the repo name surrounded by slashes, like /grim/.

Themes can be viewed at themes.gohugo.io. They usually have instructions on how to use it.

## Self-hosted Git

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

## Saltstack install and config

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
#*

### Salt Formulas

Install the GitFS backend, this allows you to serve files from git repos.

```
pkg install -y git py36-gitpython
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

### Salt equivalent to R10K and using git as a pillar source

If the git server is also a minion, you can use Reactor to signal to the master to update the fileserver on each git push:

`https://docs.saltstack.com/en/latest/topics/tutorials/gitfs.html#refreshing-gitfs-upon-push`

You can also use git as a pillar source (host your specific config data in version control)

`https://docs.saltstack.com/en/latest/topics/tutorials/gitfs.html#using-git-as-an-external-pillar-source`


### Installing RAET

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


### Salt equivalent of hiera-eyaml

Salt.runners.nacl

Similar to hiera-eyaml, it is used for encrypting data stored in pillar:

`https://docs.saltstack.com/en/latest/ref/runners/all/salt.runners.nacl.html`

## NSD and Unbound config

Set up the unbound/nsd-control

```
local-unbound-setup
nsd-control-setup
```

Enable NSD and Unbound to start in `/etc/rc.conf`

```
sysrc nsd_enable="YES"
sysrc local_unbound_enable="YES"
```

Set a different listening port for NSD in `/usr/local/etc/nsd.conf`

```
server:
  port: 5353
```

Create an inital zone file `/usr/local/etc/nsd/home.lan.zone`

```
$ORIGIN home.lan. ;
$TTL 86400 ;

@ IN SOA ns1.home.lan. admin.home.lan. (
        2017080619 ;
        28800 ;
        7200 ;
        864000 ;
        86400 ;
        )

        NS ns1.home.lan.

ns1 IN A 192.168.1.15
jail IN A 192.168.1.15
```

Create the reverse lookup zone file `/usr/local/etc/nsd/home.lan.reverse`

```
$ORIGIN home.lan.
$TTL 86400

0.1.168.192.in-addr.arpa. IN SOA ns1.home.lan. admin.home.lan. (
        2017080619
        28800
        7200
        864000
        86400
        )

        NS ns1.home.lan.

15.1.168.192.in-addr.arpa. IN PTR jail
15.1.168.192.in-addr.arpa. IN PTR ns1
```

### OpenDNSSEC

Install the required packages

```
pkg install -y opendnssec softhsm
```

Set the softhsm database location in `/usr/local/etc/softhsm.conf`

```
0:/var/lib/softhsm/slot0.db
```

Initialise the token database:

```
softhsm --init-token --slot 0 --label "OpenDNSSEC"
Enter the PIN for the SO and then the USER.
```

Make sure opendnssec has permission to access the token database

```
chown opendnssec /var/lib/softhsm/slot0.db
chgrp opendnssec /var/lib/softhsm/slot0.db
```

Set some options for OpenDNSSEC in `/usr/local/etc/opendnssec/conf.xml`

```
<Repository name="SoftHSM">
        <Module>/usr/local/lib/softhsm/libsofthsm.so</Module>
        <TokenLabel>OpenDNSSEC</TokenLabel>
        <PIN>1234</PIN>
        <SkipPublicKey/>
</Repository>
```

Edit `/usr/local/etc/opendnssec/kasp.xml`. Change unixtime to datecounter in the Serial parameter. This allows us to use YYYYMMDDXX format for the SOA SERIAL values.

```
<Zone>
        <PropagationDelay>PT300S</PropagationDelay>
        <SOA>
                <TTL>PT300S</TTL>
                <Minimum>PT300S</Minimum>
                <Serial>datecounter</Serial>
        </SOA>
</Zone>
```
## Compiling NGINX with ChaCha20 support

Make a working directory

```
mkdir ~/nginx
cd ~/nginx
```

Install some dependencies

```
pkg install -y ca_root_nss pcre perl5
```

Pull the source files

```
fetch https://nginx.org/download/nginx-1.13.0.tar.gz
fetch https://www.openssl.org/source/openssl-1.1.0e.tar.gz
```

Extract the tarballs

```
tar -xzvf nginx-1.13.0.tar.gz
tar -xzvf openssl-1.1.0e.tar.gz
rm *.tar.gz
```
#*

Compile openssl

```
cd ~/nginx/openssl-1.1.0e.tar.gz
./config
make
make install
```

The compiled OpenSSL binary should be located in /usr/local/bin by default, unless the prefixdir variable has been set

```
/usr/local/bin/openssl version
# Should output OpenSSL 1.1.0e
```

Compile NGINX

```
#!/bin/sh
cd ~/nginx/nginx-1.13.0/
#make clean

./configure \
	--with-http_ssl_module \
	--with-http_gzip_static_module \
	--with-file-aio \
	--with-ld-opt="-L /usr/local/lib" \

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
```

After running the compile script, NGINX should be installed in /usr/local/nginx

Start the service

```
/usr/local/nginx/sbin/nginx
```

If there are no issues, update the config file as appropriate in `/usr/local/nginx/conf/nginx.conf`

Reload NGINX to apply the new config

```
/usr/local/nginx/sbin/nginx -s reload
```

Generate a self-signed certificate

Current NGINX config

```
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
```

## Bhyve VM creation

### Bhyve Initial Setup

Enable the tap interface in `/etc/sysctl.conf` and load it on the currently running system

```
net.link.tap.up_on_open=1
sysctl -f /etc/sysctl.conf
```

Enable bhyve, serial console and bridge/tap interface kernel modules in `/boot/loader.conf`. Reboot to apply changes or use kldload.

```
vmm_load="YES"
nmdm_load="YES"
if_bridge_load="YES"
if_tap_load="YES"
```

Set up the network interfaces in `/etc/rc.conf`

```
cloned_interfaces="bridge0 tap0"
ifconfig_bridge0="addm re0 addm tap0"
```

Create a ZFS volume

```
zfs create -V16G -o volmode=dev zroot/testvm
```

Download the installation image

```
fetch ftp://ftp.freebsd.org/pub/FreeBSD/releases/ISO-IMAGES/11.1/FreeBSD-11.1-RELEASE-amd64-disc1.iso 
```

Start the VM

```
sh /usr/share/examples/bhyve/vmrun.sh -c 1 -m 512M -t tap0 -d /dev/zvol/zroot/testvm -i -I FreeBSD-11.1-RELEASE-amd64-disc1.iso testvm
```

Install as normal, following the menu options

### New VM Creation Script

```
#! /bin/sh
read -p "Enter hostname: " hostname
zfs create -V16G -o volmode=dev zroot/$hostname
sh /usr/share/examples/bhyve/vmrun.sh -c 1 -m 512M -t tap0 -d /dev/zvol/zroot/$hostname -i -I ~/FreeBSD-11.1-RELEASE-amd64-disc1.iso $hostname
```

### Creating a Linux guest

Create a file for the hard disk

```
truncate -s 16G linux.img
```

Create the file to map the virtual devices for kernel load

```
~/device.map

(hd0) /root/linux.img
(cd0) /root/linux.iso
```

Load the kernel

```
grub-bhyve -m ~/device.map -r cd0 -M 1024M linuxguest
```

Grub should start, choose install as normal

Start the VM

```
bhyve -A -H -P -s 0:0,hostbridge -s 1:0,lpc -s 2:0,virtio-net,tap0 -s 3:0,virtio-blk,/root/linux.img -l com1,/dev/nmdm0A -c 1 -m 512M linuxguest
```

Access through the serial console

```
cu -l /dev/nmdm0B
```


### pfSense in a VM

Download the pfSense disk image from the website using fetch

```
fetch https://frafiles.pfsense.org/mirror/downloads/pfSense-CE-2.3.1-RELEASE-2g-amd64-nanobsd.img.gz -o ~/pfSense.img.gz
```

Create the storage

```
zfs create -V2G -o volmode=dev zroot/pfsense
```

Unzip the file, and redirect output to the storage via dd

```
gzip -dc pfSense.img.gz | dd of=/dev/zvol/zroot/pfsense obs=64k
```

Load the kernel and start the boot process

```
bhyveload -c /dev/nmdm0A -d /dev/zvol/zroot/pfsense -m 256MB pfsense
```

Start the VM

```
/usr/sbin/bhyve -c 1 -m 256 -A -H -P -s 0:0,hostbridge -s 1:0,virtio-net,tap0 -s 3:0,ahci-hd,/dev/zvol/zroot/pfsense -s 4:1,lpc -l com1,/dev/nmdm0A pfsense
```

Connect to the VM via the serial connection with nmdm

```
cu -l /dev/nmdm0B
```

Perform initial configuration through the shell to assign the network interfaces

Once done, use the IP address to access through the web console 

When finished, you can shutdown/reboot

To de-allocate the resources, you need to destroy the VM

```
bhyvectl --destroy --vm=pfsense
```


### Multiple VMs using bhyve

To allow networking on multiple vms, there should be a tap assigned to each vm, connected to the same bridge. 

```
cloned_interfaces="bridge0 tap0 tap1 tap2"
ifconfig_bridge0="addm re0 addm tap0 addm tap1 addm tap2"
```

Then when you provision vms, assign one of the tap interfaces to them.

### vm-bhyve

A better way for managing a bhyve hypervisor.

Follow the instructions on the repo.

When adding the switch to a network interface, it doesn't work with re0. tap1 works, but then internet doesnt work in the VMs. Needs sorting.

zfs 

bsd-cloud-init should be tested, it sets hostname based on openstack image name.

otherwise, if we figure out how to make a template VM, you could set the hostname as part of transferring over the rc.conf file

create template VM, start it, zfs send/recv?

## Jail Creation

Create a template dataset

```
zfs create -o mountpoint=/usr/local/jails zroot/jails
zfs create -p zroot/jails/template
```

Download the base files into a new directory

```
mkdir ~/jails
fetch ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/11.1-RELEASE/base.txz -o ~/jails
```

Extract the base files into the template directory (mountpoint)

```
tar -xf ~/jails/base.txz -C /usr/local/jails/template
```

Copy the resolv.conf file from host to template so that we have working DNS resolution

```
cp /etc/resolv.conf /usr/local/jails/template/etc/resolv.conf
```

When finished, take a snapshot. Anything after the '@' symbol is the snapshot name. You can make changes to the template at any time, just make sure that you take another snapshot when you are finished and that any subsequently created jails use the new snapshot.

```
zfs snapshot zroot/jails/template@1
```

New jails can then be created by cloning the snapshot of the template dataset

```
zfs clone zroot/jails/template@1 zroot/jails/testjail
```

Add the jails configuration to /etc/jail.conf

```
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
```

Run the jail

```
jail -c testjail
```

View running jails

```
jls
```

Login to the jail

```
jexec testjail sh
```
## Hardware

### Virtualisation Host

Gigabyte Brix Pro GB-BXI7-4770R

- Intel Core i7-4770R (quad core 3.2GHz)
- 16GB RAM
- 250GB mSATA SSD
- 250GB 2.5 inch SSD

### NAS

HP ProLiant G8 Microserver G1610T

- Intel Celeron G1610T (dual core 2.3 GHz)
- 16GB RAM
- 2 x 250GB SSD
- 2 x 3TB HDD

### Management

Raspberry Pi 2 Model B
- Quad core 1GB RAM
- 8GB MicroSD (w/ NOOBS)
