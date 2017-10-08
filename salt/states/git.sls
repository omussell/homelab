---

git:
  pkg.installed:
    - version: 2.13.5

/usr/local/git:
  file.directory:
    - makedirs: True

git_remote:
  user.present:
    - home: "/nonexistent"
    - shell: "/usr/local/bin/git-shell"
