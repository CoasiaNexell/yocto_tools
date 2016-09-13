#!/bin/bash

set -e

TOP=`pwd`
argc=$#
MACHINE_NAME=$1
IMAGE_TYPE=$2
RESULT_DIR="result-$1-$2"

BOARD_SOCNAME=
BOARD_NAME=
BOARD_PREFIX=
BOARD_POSTFIX=

function check_usage()
{
    if [ $argc != 2 ]
    then
	echo "Invalid argument check usage please"
	usage
	exit
    fi
}

function usage()
{
    echo "Usage: $0 <machine-name> <image-type>"
    echo "    ex) $0 s5p6818-artik710-raptor tiny"
    echo "    ex) $0 s5p6818-artik710-raptor sato"
    echo "    ex) $0 s5p6818-artik710-raptor qt"
    echo "    ex) $0 s5p6818-avn-ref qt"
    echo "    ex) $0 s5p6818-avn-ref tiny"
    echo "    ex) $0 s5p4418-avn-ref qt"
    echo "    ex) $0 s5p4418-avn-ref tiny"
    echo "    ex) $0 s5p4418-navi-ref qt"
    echo "    ex) $0 s5p4418-navi-ref tiny"
    echo "    ex) $0 s5p4418-navi-ref tinyui"
    echo "    ex) $0 s5p4418-cluster-ref qt"
    echo "    ex) $0 s5p4418-cluster-ref tiny"
    echo "    ex) $0 s5p4418-cluster-ref tinyui"
}

function split_machine_name()
{
    BOARD_SOCNAME=${MACHINE_NAME%-*-*}
    BOARD_NAME=${MACHINE_NAME#*-}
    BOARD_PREFIX=${BOARD_NAME%-*}
    BOARD_POSTFIX=${BOARD_NAME#*-}
}

function binary_download()
{
    local ROOT_PATH=${TOP}

    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m                      Target Downloading...                         \033[0m"
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"    
       
    ./yocto/meta-nexell/tools/update_${BOARD_SOCNAME}.sh -p $ROOT_PATH/yocto/${RESULT_DIR}/partmap_emmc.txt -r $ROOT_PATH/yocto/${RESULT_DIR}

    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m   Download Complete                                                \033[0m"    
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"    

}

check_usage
split_machine_name
binary_download
