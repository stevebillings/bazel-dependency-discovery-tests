#!/bin/bash

rule=jvm_maven_import_external
alias bazel='/usr/bin/bazel'

echo "================================="
echo " ${rule}"
echo "---------------------------------"
echo " Running bazel query:"
TARGET=//:build_configuration; bazel cquery "deps($TARGET)" --define=new_hotness=true --define=old_n_busted=false --nohost_deps --noimplicit_deps --output=build > /tmp/t 2> /dev/null
echo "---------------------------------"
echo " dependency: commons-collections4"
echo " Need: artifact = org.apache.commons:commons-collections4:4.3"
echo "---------------------------------"
grep commons-collections4 /tmp/t && grep 'org\.apache\.commons' /tmp/t && grep '4\.3' /tmp/t
grepStatus=$?
if [ $grepStatus -eq 0 ]; then
	echo Seems to be SUCCESS
else
	echo Seems to be FAILURE
fi
