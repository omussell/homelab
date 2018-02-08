---
title: "Building Go programs using Bazel"
date: 2018-02-08T17:50:00Z
draft: false
---

Bazel is a build tool created by Google which operates similarly to their internal build tool, Blaze. It is primarily concerned with generating artifacts from compiled languages like C, C++, Go etc. 

`pkg install -y bazel`

Bazel requires some files so that it knows what and where to build. As an example, we are going to compile a simple go program with no dependencies (literally print a single string to stdout).

```
// ~/go/src/github.com/omussell/go_tests/main.go

package main

import "fmt"

func main() {
	fmt.Println("test")
}
```

A file called WORKSPACE should be created at the root of the directory. This is used by bazel to determine source code locations relative to the WORKSPACE file and differentiate other packages in the same directory. Then a BUILD.bazel file should also be created at the root of the directory. 




Gazelle
---

Instead of creating BUILD files by hand, we can use the Gazelle tool to iterate over a go source tree and dynamically generate BUILD files. We can also let bazel itself run gazelle.

Note that gazelle doesn't work without bash, and the gazelle.bash file has a hardcoded path to `/bin/bash` which of course is not available on FreeBSD by default.

```
pkg install -y bash
ln -s /usr/local/bin/bash /bin/bash
```

In the WORKSPACE file:

```
http_archive(
    name = "io_bazel_rules_go",
    url = "https://github.com/bazelbuild/rules_go/releases/download/0.9.0/rules_go-0.9.0.tar.gz",
    sha256 = "4d8d6244320dd751590f9100cf39fd7a4b75cd901e1f3ffdfd6f048328883695",
)
http_archive(
    name = "bazel_gazelle",
    url = "https://github.com/bazelbuild/bazel-gazelle/releases/download/0.9/bazel-gazelle-0.9.tar.gz",
    sha256 = "0103991d994db55b3b5d7b06336f8ae355739635e0c2379dea16b8213ea5a223",
)
load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains(go_version="host")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
gazelle_dependencies()
```

In the BUILD.bazel file:

```
load("@bazel_gazelle//:def.bzl", "gazelle")

gazelle(
    name = "gazelle",
    prefix = "github.com/omussell/go_tests",
)
```

Then to run:

```
bazel run //:gazelle
bazel build //:go_tests
```

A built binary should be output to the ~/.cache directory. Once a binary has been built once, Bazel will only build again if the source code changes. Otherwise, any subsequent runs just complete successfully extremely quickly.

When attempting to use bazel in any capacity like `bazel run ...` or `bazel build ...` it would give the following error:

```
ERROR: /root/.cache/bazel/_bazel_root/b3532a61fb0a1349ae431191285a1776/external/io_bazel_rules_go/BUILD.bazel:7:1: every rule of type go_context_data implicitly depends upon the target '@go_sdk//:packages.txt', but this target could not be found because of: no such package '@go_sdk//': Unsupported operating system: freebsd
ERROR: /root/.cache/bazel/_bazel_root/b3532a61fb0a1349ae431191285a1776/external/io_bazel_rules_go/BUILD.bazel:7:1: every rule of type go_context_data implicitly depends upon the target '@go_sdk//:files', but this target could not be found because of: no such package '@go_sdk//': Unsupported operating system: freebsd
ERROR: /root/.cache/bazel/_bazel_root/b3532a61fb0a1349ae431191285a1776/external/io_bazel_rules_go/BUILD.bazel:7:1: every rule of type go_context_data implicitly depends upon the target '@go_sdk//:tools', but this target could not be found because of: no such package '@go_sdk//': Unsupported operating system: freebsd
ERROR: Analysis of target '//:gazelle' failed; build aborted: no such package '@go_sdk//': Unsupported operating system: freebsd
```

I think this is caused by bazel attempting to download and build go which isn't necessary as we've already installed via the package anyway. In the WORKSPACE file, change the `go_register_toolchains()` line to `go_register_toolchains(go_version="host")` as documented at https://github.com/bazelbuild/rules_go/blob/master/go/toolchains.rst#using-the-installed-go-sdk. This will force bazel to use the already installed go tools.

CI with Buildbot
---


Example buildbot config:

```
factory.addStep(steps.Git(repourl='git://github.com/omussell/go_tests.git', mode='incremental'))
factory.addStep(steps.ShellCommand(command=["go", "fix"],))
factory.addStep(steps.ShellCommand(command=["go", "vet"],))
factory.addStep(steps.ShellCommand(command=["go", "fmt"],))
factory.addStep(steps.ShellCommand(command=["bazel", "run", "//:gazelle"],))
factory.addStep(steps.ShellCommand(command=["bazel", "build", "//:go_tests"],))
```
