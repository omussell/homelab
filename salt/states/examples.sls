install_packages:
  pkg.installed:
    - pkgs:
      - {{ pillar['editor'] }}

Clone homelab repo for testing:
  pkg.installed:
    - name: git
  git.latest:
    - name: https://github.com/omussell/homelab
    - rev: master
    - target: /tmp/homelab

