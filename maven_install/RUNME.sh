#!/bin/bash

rule=maven_install
alias bazel='/usr/bin/bazel'

echo "================================="
echo " ${rule}"
echo "---------------------------------"
echo " Running bazel query:"
rm /tmp/t
TARGET=//tests/integration:ArtifactExclusionsTest; bazel cquery "deps($TARGET)" --nohost_deps --noimplicit_deps --output=build > /tmp/t 2> /dev/null
echo "---------------------------------"
echo " dependency: error_prone_annotations"
echo " Need this or similar: maven_coordinates=com.google.errorprone:error_prone_annotations:2.2.0"
echo "---------------------------------"
grep error_prone_annotations /tmp/t && grep '2\.2\.0' /tmp/t
grepStatus=$?
if [ $grepStatus -eq 0 ]; then
	echo Seems to be SUCCESS
else
	echo Seems to be FAILURE
fi
