---
/etc/ssh/ssh_config:
  file.exists

/etc/ssh/sshd_config:
  file.exists

sshd:
  service.running:
    - enable: True
    - require:
      - file: /etc/ssh/sshd_config
      - file: /etc/ssh/ssh_config

sshd_enable:
  sysrc.managed:
    - value: "YES"

sshd_rsa_enable:
  sysrc.managed:
    - value: "NO"

sshd_ecdsa_enable:
  sysrc.managed:
    - value: "NO"

sshd_ed25519_enable:
  sysrc.managed:
    - value: "YES"
