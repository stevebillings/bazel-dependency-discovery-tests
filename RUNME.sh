#!/bin/bash

for d in */ ; do
	echo $d
	pushd $d
	./RUNME.sh
	popd
done
