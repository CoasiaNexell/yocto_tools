#!/bin/bash

set -e

TOP=`pwd`

#./yocto/meta-nexell/recipes-xxx/.../.bbappend files cleanup
function remove_bbappends()
{
    python ${TOP}/tools/bbappend-files/remove_bbappend.py ${TOP}
}

remove_bbappends
