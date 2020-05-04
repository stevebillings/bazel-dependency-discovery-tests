#!/bin/bash

rule=http_jar
alias bazel='/usr/bin/bazel'

echo "================================="
echo " ${rule}"
echo "---------------------------------"
echo " Actual output:"
TARGET=//:hello-lib; bazel cquery "deps($TARGET)" --nohost_deps --noimplicit_deps --output=build | tee /tmp/t
echo "---------------------------------"
echo " dependency: guava"
echo " Need: url = https://repo1.maven.org/maven2/com/google/guava/guava/28.1-jre/guava-28.1-jre.jar"
echo "---------------------------------"
grep guava /tmp/t && grep '28\.1' /tmp/t
grepStatus=$?
if [ $grepStatus -eq 0 ]; then
	echo Seems to be SUCCESS
else
	echo Seems to be FAIURE
fi
echo "Should be: FAILS"
