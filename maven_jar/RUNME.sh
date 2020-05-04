#!/bin/bash

rule=maven_jar
alias bazel='/usr/bin/bazel'

echo "================================="
echo " ${rule}"
echo "---------------------------------"
echo " Running bazel query:"
rm /tmp/t
TARGET=//:ProjectRunner; /usr/bin/bazel cquery "deps($TARGET)" --nohost_deps --noimplicit_deps --output=build > /tmp/t 2> /dev/null
echo "---------------------------------"
echo " dependency: guava"
echo " Need this or similar: name = com_google_guava_guava, artifact = com.google.guava:guava:18.0"
echo "---------------------------------"
grep guava /tmp/t && grep 'com\.google\.guava' /tmp/t && grep '18\.0' /tmp/t
grepStatus=$?
if [ $grepStatus -eq 0 ]; then
	echo Seems to be SUCCESS
else
	echo Seems to be FAILURE
fi
