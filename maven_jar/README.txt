Old Detect method:
bazel query 'filter("@.*:jar", deps(//:ProjectRunner))'
bazel query 'kind(maven_jar, //external:org_apache_commons_commons_io)' --output xml

Proposed method:
TARGET=//:ProjectRunner; bazel cquery "deps($TARGET)" --nohost_deps --noimplicit_deps --output=build


maven_jar(
    name = "com_google_guava_guava",
    artifact = "com.google.guava:guava:18.0"
)

Method reveals identifying details: NO
