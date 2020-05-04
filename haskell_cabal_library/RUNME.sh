#!/bin/bash

rule=haskell_cabal_library
alias bazel='/usr/bin/bazel'

echo "================================="
echo " ${rule}"
echo "---------------------------------"
echo " Running bazel query:"
pushd examples
TARGET=//cat_hs/lib/args:args; bazel cquery "deps($TARGET)" --nohost_deps --noimplicit_deps --output=build > /tmp/t 2> /dev/null
popd
echo "---------------------------------"
echo " dependency: colour"
echo " Need: name = colour, version = 2.3.5"
grep 'name = "colour"' /tmp/t && grep 'version = "2\.3\.5"' /tmp/t
grepStatus=$?
if [ $grepStatus -eq 0 ]; then
	echo Seems to be SUCCESS
else
	echo Seems to be FAILURE
fi
