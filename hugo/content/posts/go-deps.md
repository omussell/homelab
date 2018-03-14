---
title: "Handling Go Dependencies"
date: 2018-03-14T21:47:09Z
draft: false
---

During development, you will often use `go get` to download libraries for import into the program which is useful for development but not so useful when building the finished product. Managing these dependencies over time is a hassle as they change frequently and can sometimes disappear entirely.

The `dep` tool provides a way of automatically scanning your import statements and evaluating all of the dependencies. It create some files `Gopkg.toml` and `Gopkg.lock` which contain the location and latest Git SHA of your dependencies.

`dep` is installed via `curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh`

Run `dep init` to create the initial files, then as your develop run `dep ensure` to update dependencies to the latest version.

The `dep` tool also downloads a copy of all dependencies into a `vendor` folder at the root of your project. This provides a backup in case a dependency disappears and provides the facility for reproducible builds.


Bazel / Gazelle
---

With our dependencies being updated, we would also need to update the WORKSPACE file so that Bazel/Gazelle knows about them as well. Gazelle requires the location and git commit hash in order to pull down the correct dependencies, but this is laborious to perform manually.

Thankfully, we can run a command to have gazelle pull in all of the dependencies from the `Gopkg.lock` file and update the WORKSPACE file automatically. Bazel will then pull in all of the dependencies correctly without any manual intervention.

`gazelle update-repos -from_file Gopkg.lock`

As part of ongoing development, you would periodically run

`dep ensure` 

followed by

`gazelle update-repos -from_file Gopkg.lock`

to keep all of the dependencies up to date and generate the new WORKSPACE file.
