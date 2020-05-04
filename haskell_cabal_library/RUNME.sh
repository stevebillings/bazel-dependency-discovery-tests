#!/bin/bash

rule=haskell_cabal_library
alias bazel='/usr/bin/bazel'

echo "================================="
echo " ${rule}"
echo "---------------------------------"
echo " Actual output:"
pushd examples
TARGET=//cat_hs/lib/args:args; bazel cquery "deps($TARGET)" --nohost_deps --noimplicit_deps --output=build | tee /tmp/t
popd
echo "---------------------------------"
echo " dependency: colour"
echo " Need: name = colour, version = 2.3.5"
grep colour /tmp/t && grep '2\.3\.5' /tmp/t
grepStatus=$?
if [ $grepStatus -eq 0 ]; then
	echo Seems to be SUCCESS
else
	echo Seems to be FAIURE
fi
