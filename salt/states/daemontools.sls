---
daemontools:
  pkg.installed

/var/service:
  file.directory:
    - makedirs: True

svscan:
  service.running:
    - enable: True
    - require:
      - pkg: daemontools
      - file: /var/service
