---
title: "Packaging and Distributing Go Applications"
date: 2018-02-27T20:34:14Z
draft: false
---



Now that we've built the go application and its dependencies we now need to package it up to distribute across the infrastructure.


Packaging with fpm
===

The below command is an example of what we would want to run:


`fpm -s dir -t freebsd -n ~/go_test --version 1.0.0 --prefix /usr/local/bin go_tests`

But this has a few issues. Rather than putting the finished package into `~/go_test`, it would be better in a dedicated directory like `/var/packages` or similar. The version number is hard coded which obviously isn't always going to be correct. You would want to instead have your CI tool set to only run the packaging command when a new tag/release is created, and then have the version number derived from the tag/release number. It also includes the `--prefix` flag to specify the path to prepend to any files in the package. This is required as when the package is installed/extracted, the files will be extracted to the full path as specified in the package. So in this instance the `/usr/local/bin/go_tests` file is extracted.


For now, I'm getting by with the following command which will overwrite the finished package if it already exists.
`fpm -f -s dir -t freebsd -n ~/go_test --prefix /usr/local/bin go_tests`



Local FreeBSD Repository
===

