---
title: "Application Packaging with fpm"
date: 2018-01-30T21:52:35Z
draft: false
---

Create a new tagged release on the git repository

```
git tag 1.4.0
```

Create a tarball of the git repository at the particular tag revision. Extracts a folder called app-1.4.0 which contains the contents of the repository at tag 1.4.0.

```
git archive --format=tar.gz --prefix=app-1.4.0/ -o ~/app-1.4.0.tar.gz 1.4.0
```

fpm
---

The `fpm` ruby gem can be used to convert common package formats into other common package formats, like virtualenv's into freebsd packages. It has support for many different types of packages.

Create a freebsd package of the homelab directory. Its important to use full paths, so that it extracts to the full path rather than relatively.

```
fpm -s dir -t freebsd -n homelab-1.4.0 /home/oliver/homelab
```

To distribute packages, we can use fpm to create tarballs of virtualenvs, node packages and any other required files, then create a freebsd package from all of these tarballs. This gives us a way of tying together all of the dependencies into one package which is easier to deploy. To deploy, we can create our own freebsd package repository and make our own packages available. Servers can then point to this repository, and be instructed to install a particular version of this package.
