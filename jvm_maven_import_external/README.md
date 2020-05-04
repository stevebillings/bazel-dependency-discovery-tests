This is an example Bazel project which uses a few non-obvious features of
Bazel.

1. `jvm_maven_import_external` is a rule for importing Maven artifacts.  
   It replaces the deprecated `maven_jar` rule.  You can learn more about it
   here: https://github.com/bazelbuild/bazel/blob/master/tools/build_defs/repo/jvm.bzl
2. Bazel build configuration (aka selects).  This allows users to customize the
   build graph based on platform, optimization configuration, and custom cmdline
   arguments.  Read more about it here:
   https://docs.bazel.build/versions/master/configurable-attributes.html

This project demonstrates a combination of the two.

## jvm_maven_import_external

Pop open the `WORKSPACE` file and observe two `jvm_maven_import_external`
rules to pull in two different versions of the Apache Commons Collection
package.  Users can include either package as a dependency like so:

```python
java_library(
    name = "my_library",
    srcs = [],
    deps = ["@commons_collections"],
)
```

## Build configuration 

In `BUILD.bazel`, we define two new settings, "old_n_busted" and "new_hotness".
Either setting is chosen by passing `--define=old_n_busted=true` or
`--define=new_hotness=true` on the Bazel command line:

```console
$ bazel build :build_configuration --define=old_n_busted=true
```

## Putting it together

The `java_library` rule in `BUILD.bazel` combines both of these features.  The
`old_n_busted` flag enables use of `@commons_collections`, while `new_hotness`
enables use of `@commons_collections4`.  (The default is to use neither
artifact.)

## Why `query` causes a problem

Running `bazel query deps(:build_configuration)` lists _both_ versions of Commons
Collections as a dependency:

```console
$ bazel query 'deps(:build_configuration)' | grep commons
@commons_collections4//:commons_collections4
@commons_collections4//:commons-collections4-4.3.jar
@commons_collections//:commons_collections
@commons_collections//:commons-collections-3.2.2.jar
```

To run a configuration-aware query, one must instead use the `cquery` command:

```
$ bazel cquery 'deps(:build_configuration)' 2>/dev/null | grep commons
$ bazel cquery 'deps(:build_configuration)' --define=old_n_busted=true 2>/dev/null | grep commons
@commons_collections//:commons_collections (62d4e82207c74acaacab38d1a93ee27f)
@commons_collections//:commons-collections-3.2.2.jar (null)
$ bazel cquery 'deps(:build_configuration)' --define=new_hotness=true 2>/dev/null | grep commons
@commons_collections4//:commons_collections4 (2523e68c71a7ad3c2d8dd4e9796e93f9)
@commons_collections4//:commons-collections4-4.3.jar (null)
```
