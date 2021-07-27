assumes agent already installed
make sure the agent is installed from the puppet apt repo and the package is called puppet-agent

set the correct hostname

install r10k:
apt install -y ruby
gem install r10k hiera-eyaml --no-doc

mkdir -p /var/cache/r10k /etc/r10k /etc/r10k/ssh

/etc/r10k/r10k.yaml

---
cachedir: "/var/cache/r10k"

sources
  control:
    remote: "git@github.com:omussell/puppet-control.git"
    basedir: "/etc/puppetlabs/code/environments"

git:
  repositories:
    - remote: "git@github.com:omussell/puppet-control.git"
      private_key: "/etc/r10k/ssh/r10k-deploy-key"



Add the puppet user, package doesnt include it

Put the hiera-eyaml and SSH keys in place

mkdir -p /etc/puppetlabs/keys

chown puppet:puppet

SSH key goes in /root/.ssh/id_rsa and /etc/r10k/ssh/r10k-deploy-key

chmod 600 on privkeys


Install the ENC

cd /etc/puppetlabs/puppet
git clone https://github.com/omussell/bun.nim.got
apt install -y nim
cd bun.nim
nim c -r src/bun.nim

Set:

node_terminus = exec
external_nodes = /etc/puppetlabs/bun.nim/src/bun

in /etc/puppetlabs/puppet/puppet.conf

Make some bootstrap facts

mkdir -p /etc/facter/facts.d

/etc/facter/facts.d/bootstrap.sh

#! /bin/sh
echo "tier=prod"
echo "group=puppetserver"


Run r10k

r10k deploy environment -pv --config /etc/r10k/r10k.yaml

Create the /etc/puppetlabs/puppet.conf file:

[main]
codedir = /etc/puppetlabs/code
environmentpath = $codedir/environments
hiera_config = $codedir/hiera.yaml
node_terminus = exec
external_nodes = /etc/puppetlabs/bun.nim/src/bun

Run:

cd /etc/puppetlabs/code/environments/main
puppet apply --modulepath=./modules:site --hiera_config=./hiera.yaml ./manifests/puppet.pp
