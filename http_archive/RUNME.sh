#!/bin/bash

rule=http_archive
alias bazel='/usr/bin/bazel'

echo "================================="
echo " ${rule}"
echo "---------------------------------"
echo " Running bazel query:"
rm /tmp/t
TARGET=//service/src/main/java/com/oasisdigital/grocery:grocery; bazel cquery "deps($TARGET)" --nohost_deps --noimplicit_deps --output=build > /tmp/t 2> /dev/null
echo "---------------------------------"
echo " dependency: grpc-java"
echo " Need this or similar: url = https://github.com/grpc/grpc-java/archive/v1.25.0.tar.gz"
echo "---------------------------------"
grep grpc-java /tmp/t && grep 'v1\.25\.0' /tmp/t
grepStatus=$?
if [ $grepStatus -eq 0 ]; then
	echo Seems to be SUCCESS
else
	echo Seems to be FAILURE
fi
