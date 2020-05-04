Proposed method:
#TARGET=//:build_configuration; bazel cquery "deps($TARGET)" --nohost_deps --noimplicit_deps --output=build
TARGET=//:build_configuration; bazel cquery "deps($TARGET)" --define=new_hotness=true --define=old_n_busted=false --nohost_deps --noimplicit_deps --output=build

dependency: 

jvm_maven_import_external(
    name = "commons_collections4",
    artifact = "org.apache.commons:commons-collections4:4.3",
    licenses = ["notice"],  # apache license, version 2.0
    server_urls = ["https://repo1.maven.org/maven2"],
)

Method reveals identifying details: NO
