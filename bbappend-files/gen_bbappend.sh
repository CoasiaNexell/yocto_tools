#!/bin/bash

set -e

TOP=`pwd`
ROOT_PATH=$1

function generate_bbappends()
{
    python ./gen_bbappend.py ${ROOT_PATH}
}

generate_bbappends
