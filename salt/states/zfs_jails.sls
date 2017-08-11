tank/template:
  zfs.filesystem_present

tank/template@1:
  zfs.snapshot_present

tank/testjail1:
  zfs.filesystem_present:
    - cloned_from: tank/template@1

/tank/testjail1:
  archive.extracted:
    - source: ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/11.0-RELEASE/base.txz
  - skip_verify: True

start_jails:
  module.run:
    - name: jail.start
    - jail: testjail1
