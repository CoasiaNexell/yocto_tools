#!/bin/bash

set -e

TOP=`pwd`
CURRENT_PATH=`dirname $0`
ROOT_PATH=$1
TYPE=$2

function generate_bbappends()
{
    python ./run_bbappend.py ${ROOT_PATH} "generate"
}

function remove_bbappends()
{
    python ${CURRENT_PATH}/run_bbappend.py ${TOP} "remove"
}

if [ "${TYPE}" == "generate" ];then
    generate_bbappends
else
    remove_bbappends
fi
