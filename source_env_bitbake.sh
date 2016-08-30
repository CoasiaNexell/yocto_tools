#!/bin/bash

cd $3
source poky/oe-init-build-env $1-$2
../meta-nexell/tools/envsetup.sh $1 $2
bitbake $1-$2

