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

# In rc.conf:
# sshd_enable="YES"
# sshd_rsa_enable="NO"
# sshd_ecdsa_enable="NO"
# sshd_ed25519_enable="YES"
