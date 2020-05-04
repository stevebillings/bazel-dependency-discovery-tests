Old Detect method:
bazel cquery --noimplicit_deps 'kind(j.*import, deps(//tests/integration:ArtifactExclusionsTest))' --output build

Proposed method:
TARGET=//tests/integration:ArtifactExclusionsTest; bazel cquery "deps($TARGET)" --nohost_deps --noimplicit_deps --output=build

Method reveals identifying details: YES
