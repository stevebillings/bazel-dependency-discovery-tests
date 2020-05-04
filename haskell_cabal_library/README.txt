Proposed method:
cd examples; TARGET=//cat_hs/lib/args:args; bazel cquery "deps($TARGET)" --nohost_deps --noimplicit_deps --output=build

dependency: 

haskell_cabal_library(
  name = "colour",
  version = "2.3.5",

Method reveals identifying details: YES
