# rules_jvm_external

Transitive Maven artifact resolver as a repository rule.

[![Build
Status](https://badge.buildkite.com/26d895f5525652e57915a607d0ecd3fc945c8280a0bdff83d9.svg?branch=master)](https://buildkite.com/bazel/rules-jvm-external)

## Features

* WORKSPACE configuration
* JAR, AAR, source JARs
* Custom Maven repositories
* Private Maven repositories with HTTP Basic Authentication
* Artifact version resolution with Coursier
* Integration with Bazel's downloader and caching mechanisms for sharing artifacts across Bazel workspaces
* Pin resolved artifacts with their SHA-256 checksums into a version-controllable JSON file
* Versionless target labels for simpler dependency management
* Ability to declare multiple sets of versioned artifacts
* Supported on Windows, macOS, Linux

Get the [latest release
here](https://github.com/bazelbuild/rules_jvm_external/releases/latest).

## Usage

List the top-level Maven artifacts and servers in the WORKSPACE:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

RULES_JVM_EXTERNAL_TAG = "2.8"
RULES_JVM_EXTERNAL_SHA = "79c9850690d7614ecdb72d68394f994fef7534b292c4867ce5e7dec0aa7bdfad"

http_archive(
    name = "rules_jvm_external",
    strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
    sha256 = RULES_JVM_EXTERNAL_SHA,
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % RULES_JVM_EXTERNAL_TAG,
)

load("@rules_jvm_external//:defs.bzl", "maven_install")

maven_install(
    artifacts = [
        "junit:junit:4.12",
        "androidx.test.espresso:espresso-core:3.1.1",
        "org.hamcrest:hamcrest-library:1.3",
    ],
    repositories = [
        # Private repositories are supported through HTTP Basic auth
        "http://username:password@localhost:8081/artifactory/my-repository",
        "https://jcenter.bintray.com/",
        "https://maven.google.com",
        "https://repo1.maven.org/maven2",
    ],
)
```

Credentials for private repositories can also be specified using a property file
or environment variables. See the [Coursier
documentation](https://get-coursier.io/docs/other-credentials.html#property-file)
for more information.

Next, reference the artifacts in the BUILD file with their versionless label:

```python
java_library(
    name = "java_test_deps",
    exports = [
        "@maven//:junit_junit"
        "@maven//:org_hamcrest_hamcrest_library",
    ],
)

android_library(
    name = "android_test_deps",
    exports = [
        "@maven//:junit_junit"
        "@maven//:androidx_test_espresso_espresso_core",
    ],
)
```

The default label syntax for an artifact `foo.bar:baz-qux:1.2.3` is `@maven//:foo_bar_baz_qux`. That is, 

* All non-alphanumeric characters are substituted with underscores.
* Only the group and artifact IDs are required.
* The target is located in the `@maven` top level package (`@maven//`).

## API Reference

You can find the complete API reference at [docs/api.md](docs/api.md).

## Pinning artifacts and integration with Bazel's downloader

`rules_jvm_external` supports pinning artifacts and their SHA-256 checksums into
a `maven_install.json` file that can be checked into your repository. 

Without artifact pinning, in a clean checkout of your project, `rules_jvm_external` 
executes the full artifact resolution and fetching steps (which can take a bit of time) 
and does not verify the integrity of the artifacts against their checksums. The 
downloaded artifacts also cannot be shared across Bazel workspaces.

By pinning artifact versions, you can get improved artifact resolution and build times,
since using `maven_install.json` enables `rules_jvm_external` to integrate with Bazel's 
downloader that caches files on their sha256 checksums. It also improves resiliency and
integrity by tracking the sha256 checksums and original artifact urls in the
JSON file.

Since all artifacts are persisted locally in Bazel's cache, it means that
**fully offline builds are possible** after the initial `bazel fetch @maven//...`.

To get started with pinning artifacts, run the following command to generate the
initial `maven_install.json` at the root of your Bazel workspace:

```
$ bazel run @maven//:pin
```

Then, specify `maven_install_json` in `maven_install` and load
`pinned_maven_install` from `@maven//:defs.bzl`:

```python
maven_install(
    # artifacts, repositories, ...
    maven_install_json = "//:maven_install.json",
)

load("@maven//:defs.bzl", "pinned_maven_install")
pinned_maven_install()
```

**Note:** Bazel assumes you have a BUILD file in your project's root directory.
If you do not have one, create an empty BUILD file to fix issues you may see.
See [#242](https://github.com/bazelbuild/rules_jvm_external/issues/242)

Whenever you make a change to the list of `artifacts` or `repositories` and want
to update `maven_install.json`, run this command to re-pin the unpinned `@maven`
repository:

```
$ bazel run @unpinned_maven//:pin
```

Note that the repository is `@unpinned_maven` instead of `@maven`.

When using artifact pinning, each `maven_install` repository (e.g. `@maven`)
will be accompanied by an unpinned repository. This repository name has the
`@unpinned_` prefix (e.g.`@unpinned_maven` or
`@unpinned_<your_maven_install_name>`). For example, if your `maven_install` is
named `@foo`, `@unpinned_foo` will be created.

If you have multiple `maven_install` declarations, you have to alias 
`pinned_maven_install` to another name to prevent redefinitions:

```python
maven_install(
    name = "foo",
    maven_install_json = "//:foo_maven_install.json",
    # ...
)

load("@foo//:defs.bzl", foo_pinned_maven_install = "pinned_maven_install")
foo_pinned_maven_install()

maven_install(
    name = "bar",
    maven_install_json = "//:bar_maven_install.json",
    # ...
)

load("@bar//:defs.bzl", bar_pinned_maven_install = "pinned_maven_install")
bar_pinned_maven_install()
```

## Generated targets

For the `junit:junit` example, using `bazel query @maven//:all --output=build`, we can see that the rule generated these targets:

```python
alias(
  name = "junit_junit_4_12",
  actual = "@maven//:junit_junit",
)

jvm_import(
  name = "junit_junit",
  jars = ["@maven//:https/repo1.maven.org/maven2/junit/junit/4.12/junit-4.12.jar"],
  srcjar = "@maven//:https/repo1.maven.org/maven2/junit/junit/4.12/junit-4.12-sources.jar",
  deps = ["@maven//:org_hamcrest_hamcrest_core"],
  tags = ["maven_coordinates=junit:junit:4.12"],
)

jvm_import(
  name = "org_hamcrest_hamcrest_core",
  jars = ["@maven//:https/repo1.maven.org/maven2/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar"],
  srcjar = "@maven//:https/repo1.maven.org/maven2/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3-sources.jar",
  deps = [],
  tags = ["maven_coordinates=org.hamcrest:hamcrest.library:1.3"],
)
```

These targets can be referenced by:

*   `@maven//:junit_junit`
*   `@maven//:org_hamcrest_hamcrest_core`

**Transitive classes**: To use a class from `hamcrest-core` in your test, it's not sufficient to just 
depend on `@maven//:junit_junit` even though JUnit depends on Hamcrest. The compile classes are not exported 
transitively, so your test should also depend on `@maven//:org_hamcrest_hamcrest_core`.

**Original coordinates**: The generated `tags` attribute value also contains the original coordinates of
the artifact, which integrates with rules like [bazel-common's
`pom_file`](https://github.com/google/bazel-common/blob/f1115e0f777f08c3cdb115526c4e663005bec69b/tools/maven/pom_file.bzl#L177)
for generating POM files. See the [`pom_file_generation`
example](examples/pom_file_generation/) for more information.

## Advanced usage

### Fetch source JARs

To download the source JAR alongside the main artifact JAR, set `fetch_sources =
True` in `maven_install`:

```python
maven_install(
    artifacts = [
        # ...
    ],
    repositories = [
        # ...
    ],
    fetch_sources = True,
)
```

### Checksum verification

Artifact resolution will fail if a `SHA-1` or `MD5` checksum file for the
artifact is missing in the repository. To disable this behavior, set
`fail_on_missing_checksum = False` in `maven_install`:

```python
maven_install(
    artifacts = [
        # ...
    ],
    repositories = [
        # ...
    ],
    fail_on_missing_checksum = False,
)
```

### Using a persistent artifact cache

To download artifacts into a shared and persistent directory in your home
directory, set `use_unsafe_shared_cache = True` in `maven_install`.

```python
maven_install(
    artifacts = [
        # ...
    ],
    repositories = [
        # ...
    ],
    use_unsafe_shared_cache = True,
)
```

This is **not safe** as Bazel is currently not able to detect changes in the
shared cache. For example, if an artifact is deleted from the shared cache,
Bazel will not re-run the repository rule automatically.

The default value of `use_unsafe_shared_cache` is `False`. This means that Bazel
will create independent caches for each `maven_install` repository, located at
`$(bazel info output_base)/external/@repository_name/v1`.

### `artifact` helper macro

The `artifact` macro translates the artifact's `group:artifact` coordinates to
the label of the versionless target. This target is an
[alias](https://docs.bazel.build/versions/master/be/general.html#alias) that
points to the `java_import`/`aar_import` target in the `@maven` repository,
which includes the transitive dependencies specified in the top level artifact's
POM file.

For example, `@maven//:junit_junit` is equivalent to `artifact("junit:junit")`.

To use it, add the load statement to the top of your BUILD file:

```python
load("@rules_jvm_external//:defs.bzl", "artifact")
```

Note that usage of this macro makes BUILD file refactoring with tools like
`buildozer` more difficult, because the macro hides the actual target label at
the syntax level.

### Multiple `maven_install` declarations for isolated artifact version trees

If your WORKSPACE contains several projects that use different versions of the
same artifact, you can specify multiple `maven_install` declarations in the
WORKSPACE, with a unique repository name for each of them.

For example, if you want to use the JRE version of Guava for a server app, and
the Android version for an Android app, you can specify two `maven_install`
declarations:

```python
maven_install(
    name = "server_app",
    artifacts = [
        "com.google.guava:guava:27.0-jre",
    ],
    repositories = [
        "https://repo1.maven.org/maven2",
    ],
)

maven_install(
    name = "android_app",
    artifacts = [
        "com.google.guava:guava:27.0-android",
    ],
    repositories = [
        "https://repo1.maven.org/maven2",
    ],
)
```

This way, `rules_jvm_external` will invoke coursier to resolve artifact versions for
both repositories independent of each other. Coursier will fail if it encounters
version conflicts that it cannot resolve. The two Guava targets can then be used
in BUILD files like so:

```python
java_binary(
    name = "my_server_app",
    srcs = ...
    deps = [
        # a versionless alias to @server_app//:com_google_guava_guava_27_0_jre
        "@server_app//:com_google_guava_guava",
    ]
)

android_binary(
    name = "my_android_app",
    srcs = ...
    deps = [
        # a versionless alias to @android_app//:com_google_guava_guava_27_0_android
        "@android_app//:com_google_guava_guava",
    ]
)
```

### Detailed dependency information specifications

Although you can always give a dependency as a Maven coordinate string,
occasionally special handling is required in the form of additional directives
to properly situate the artifact in the dependency tree. For example, a given
artifact may need to have one of its dependencies excluded to prevent a
conflict.

This situation is provided for by allowing the artifact to be specified as a map
containing all of the required information. This map can express more
information than the coordinate strings can, so internally the coordinate
strings are parsed into the artifact map with default values for the additional
items. To assist in generating the maps, you can pull in the file `specs.bzl`
alongside `defs.bzl` and import the `maven` struct, which provides several
helper functions to assist in creating these maps. An example:

```python
load("@rules_jvm_external//:defs.bzl", "artifact")
load("@rules_jvm_external//:specs.bzl", "maven")

maven_install(
    artifacts = [
        maven.artifact(
            group = "com.google.guava",
            artifact = "guava",
            version = "27.0-android",
            exclusions = [
                ...
            ]
        ),
        "junit:junit:4.12",
        ...
    ],
    repositories = [
        maven.repository(
            "https://some.private.maven.re/po",
            user = "johndoe",
            password = "example-password"
        ),
        "https://repo1.maven.org/maven2",
        ...
    ],
)
```

### Artifact exclusion

If you want to exclude an artifact from the transitive closure of a top level
artifact, specify its `group-id:artifact-id` in the `exclusions` attribute of
the `maven.artifact` helper:

```python
load("@rules_jvm_external//:specs.bzl", "maven")

maven_install(
    artifacts = [
        maven.artifact(
            group = "com.google.guava",
            artifact = "guava",
            version = "27.0-jre",
            exclusions = [
                maven.exclusion(
                    group = "org.codehaus.mojo",
                    artifact = "animal-sniffer-annotations"
                ),
                "com.google.j2objc:j2objc-annotations",
            ]
        ),
        # ...
    ],
    repositories = [
        # ...
    ],
)
```

You can specify the exclusion using either the `maven.exclusion` helper or the
`group-id:artifact-id` string directly.

You can also exclude artifacts globally using the `excluded_artifacts`
attribute in `maven_install`:


```python
maven_install(
    artifacts = [
        # ...
    ],
    repositories = [
        # ...
    ],
    excluded_artifacts = [
        "com.google.guava:guava",
    ],
)
```

### Compile-only dependencies

If you want to mark certain artifacts as compile-only dependencies, use the
`neverlink` attribute in the `maven.artifact` helper:

```python
load("@rules_jvm_external//:specs.bzl", "maven")

maven_install(
    artifacts = [
        maven.artifact("com.squareup", "javapoet", "1.11.0", neverlink = True),
    ],
    # ...
)
```

This instructs `rules_jvm_external` to mark the generated target for
`com.squareup:javapoet` with the `neverlink = True` attribute, making the
artifact available only for compilation and not at runtime.

### Resolving user-specified and transitive dependency version conflicts

Use the `version_conflict_policy` attribute to decide how to resolve conflicts
between artifact versions specified in your `maven_install` rule and those
implicitly picked up as transitive dependencies.

The attribute value can be either `default` or `pinned`. 

`default`: use [Coursier's default algorithm](https://get-coursier.io/docs/other-version-handling) 
for version handling.

`pinned`: pin the versions of the artifacts that are explicitly specified in `maven_install`.

For example, pulling in guava transitively via google-cloud-storage resolves to 
guava-26.0-android.

```python
maven_install(
    name = "pinning",
    artifacts = [
        "com.google.cloud:google-cloud-storage:1.66.0",
    ],
    repositories = [
        "https://repo1.maven.org/maven2",
    ]
)
```

```
$ bazel query @pinning//:all | grep guava_guava
@pinning//:com_google_guava_guava
@pinning//:com_google_guava_guava_26_0_android
```

Pulling in guava-27.0-android directly works as expected.

```python
maven_install(
    name = "pinning",
    artifacts = [
        "com.google.cloud:google-cloud-storage:1.66.0",
        "com.google.guava:guava:27.0-android",
    ],
    repositories = [
        "https://repo1.maven.org/maven2",
    ]
)
```

```
$ bazel query @pinning//:all | grep guava_guava
@pinning//:com_google_guava_guava
@pinning//:com_google_guava_guava_27_0_android
```

Pulling in guava-25.0-android (a lower version), resolves to guava-26.0-android. This is the default version conflict policy in action, where artifacts are resolved to the highest version.

```python
maven_install(
    name = "pinning",
    artifacts = [
        "com.google.cloud:google-cloud-storage:1.66.0",
        "com.google.guava:guava:25.0-android",
    ],
    repositories = [
        "https://repo1.maven.org/maven2",
    ]
)
```

```
$ bazel query @pinning//:all | grep guava_guava
@pinning//:com_google_guava_guava
@pinning//:com_google_guava_guava_26_0_android
```

Now, if we add `version_conflict_policy = "pinned"`, we should see guava-25.0-android getting pulled instead. The rest of non-specified artifacts still resolve to the highest version in the case of version conflicts.

```python
maven_install(
    name = "pinning",
    artifacts = [
        "com.google.cloud:google-cloud-storage:1.66.0",
        "com.google.guava:guava:25.0-android",
    ],
    repositories = [
        "https://repo1.maven.org/maven2",
    ]
    version_conflict_policy = "pinned",
)
```

```
$ bazel query @pinning//:all | grep guava_guava
@pinning//:com_google_guava_guava
@pinning//:com_google_guava_guava_25_0_android
```

### Overriding generated targets

You can override the generated targets for artifacts with a target label of your
choice. For instance, if you want to provide your own definition of
`@maven//:com_google_guava_guava` at `//third_party/guava:guava`, specify the
mapping in the `override_targets` attribute:

```python
maven_install(
    name = "pinning",
    artifacts = [
        "com.google.guava:guava:27.0-jre",
    ],
    repositories = [
        "https://repo1.maven.org/maven2",
    ],
    override_targets = {
        "com.google.guava:guava": "@//third_party/guava:guava",
    },
)
```

Note that the target label contains `@//`, which tells Bazel to reference the
target relative to your main workspace, instead of the `@maven` workspace.

### Proxies

As with other Bazel repository rules, the standard `http_proxy`, `https_proxy`
and `no_proxy` environment variables (and their uppercase counterparts) are
supported.

### Repository aliases

Maven artifact rules like `maven_jar` and `jvm_import_external` generate targets
labels in the form of `@group_artifact//jar`, like `@com_google_guava_guava//jar`. This
is different from the `@maven//:group_artifact` naming style used in this project.

As some Bazel projects depend on the `@group_artifact//jar` style labels, we
provide a `generate_compat_repositories` attribute in `maven_install`. If
enabled, JAR artifacts can also be referenced using the `@group_artifact//jar`
target label. For example, `@maven//:com_google_guava_guava` can also be
referenced using `@com_google_guava_guava//jar`.

The artifacts can also be referenced using the style used by
`java_import_external` as `@group_artifact//:group_artifact` or
`@group_artifact` for short.

```python
maven_install(
    artifacts = [
        # ...
    ],
    repositories = [
        # ...
    ],
    generate_compat_repositories = True
)

load("@maven//:compat.bzl", "compat_repositories")
compat_repositories()
```

### Hiding transitive dependencies

As a convenience, transitive dependencies are visible to your build rules.
However, this can lead to surprises when updating `maven_install`'s `artifacts`
list, since doing so may eliminate transitive dependencies from the build
graph.  To force rule authors to explicitly declare all directly referenced
artifacts, use the `strict_visibility` attribute in `maven_install`:

```python
maven_install(
    artifacts = [
        # ...
    ],
    repositories = [
        # ...
    ],
    strict_visibility = True
)
```

### Fetch and resolve timeout

The default timeout to fetch and resolve artifacts is 600 seconds.  If you need
to change this to resolve a large number of artifacts you can set the
`resolve_timeout` attribute in `maven_install`:

```python
maven_install(
    artifacts = [
        # ...
    ],
    repositories = [
        # ...
    ],
    resolve_timeout = 900
)
```

## Exporting and consuming artifacts from external repositories

If you're writing a library that has dependencies, you should define a constant that
lists all of the artifacts that your library requires. For example:

```python
# my_library/BUILD
# Public interface of the library
java_library(
  name = "my_interface",
  deps = [
    "@maven//:junit_junit",
    "@maven//:com_google_inject_guice",
  ],
)
```

```python
# my_library/library_deps.bzl
# All artifacts required by the library
MY_LIBRARY_ARTIFACTS = [
  "junit:junit:4.12",
  "com.google.inject:guice:4.0",
]
```

Users of your library can then load the constant in their `WORKSPACE` and add the
artifacts to their `maven_install`. For example:

```python
# user_project/WORKSPACE
load("@my_library//:library_deps.bzl", "MY_LIBRARY_ARTIFACTS")

maven_install(
  artifacts = [
        "junit:junit:4.11",
        "com.google.guava:guava:26.0-jre",
  ] + MY_LIBRARY_ARTIFACTS,
)
```

```python
# user_project/BUILD
java_library(
  name = "user_lib",
  deps = [
    "@my_library//:my_interface",
    "@maven//:junit_junit",
  ],
)
```

Any version conflicts or duplicate artifacts will resolved automatically.

## Demo

You can find demos in the [`examples/`](./examples/) directory.

## Generating documentation

Use [Stardoc](https://skydoc.bazel.build/docs/getting_started_stardoc.html) to
generate API documentation in the [docs](docs/) directory using
[generate_docs.sh](scripts/generate_docs.sh). 

Note that this script has a dependency on the `doctoc` NPM package to automate
generating the table of contents. Install it with `npm -g i doctoc`.
