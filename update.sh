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

PARTIAL_UPDATE_ARGS=

function check_usage()
{
    if [ $argc -lt 2 ]
    then
	echo "Invalid argument check usage please"
	usage
	exit
    fi
}

function usage()
{
    echo "Usage: $0 <machine-name> <image-type> [-t bl1 -t uboot -t env -t kernel -t rootfs]"
    echo " -t bl1\t: if you want to update only bl1, specify this, default no"
    echo " -t uboot\t: if you want to update only bootloader, specify this, default no"
    echo " -t env\t: if you want to update only env, specify this, default no"
    echo " -t kernel\t: if you want to update only boot partition, specify this, default no"
    echo " -t rootfs\t: if you want to update only root partition, specify this, default no"
    echo "    ex) $0 s5p6818-artik710-raptor tiny -t bl1"
    echo "    ex) $0 s5p6818-artik710-raptor sato -t kernel"
    echo "    ex) $0 s5p6818-artik710-raptor qt"
    echo "    ex) $0 s5p6818-avn-ref qt -t kernel -t uboot"
    echo "    ex) $0 s5p6818-avn-ref tiny"
    echo "    ex) $0 s5p4418-avn-ref qt"
    echo "    ex) $0 s5p4418-avn-ref tiny"
    echo "    ex) $0 s5p4418-navi-ref qt"
    echo "    ex) $0 s5p4418-navi-ref tiny -t uboot -t bl1 -env -t kernel"
    echo "    ex) $0 s5p4418-navi-ref tinyui"
    echo "    ex) $0 s5p4418-hs-iot qt"
    echo "    ex) $0 s5p4418-hs-iot tiny -t uboot -t bl1 -env -t kernel"
    echo "    ex) $0 s5p4418-hs-iot tinyui"
}

function parse_args()
{
    ARGS=$(getopt -o t:h -- "$@");
    eval set -- "$ARGS";

    while true; do
        case "$1" in
            -t ) case "$2" in
                     bl1    ) PARTIAL_UPDATE_ARGS+=" -t bl1" ;;
                     uboot  ) PARTIAL_UPDATE_ARGS+=" -t uboot" ;;
                     env    ) PARTIAL_UPDATE_ARGS+=" -t env" ;;
                     kernel ) PARTIAL_UPDATE_ARGS+=" -t kernel" ;;
                     rootfs ) PARTIAL_UPDATE_ARGS+=" -t rootfs" ;;
                     *      ) usage; exit 1 ;;
                 esac
                 shift 2 ;;
            -h ) usage; exit 1 ;;
            -- ) break ;;
        esac
    done
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
    echo "./yocto/meta-nexell/tools/update_${BOARD_SOCNAME}.sh"
    echo " -p $ROOT_PATH/yocto/${RESULT_DIR}/partmap_emmc.txt"
    echo " -r $ROOT_PATH/yocto/${RESULT_DIR} ${PARTIAL_UPDATE_ARGS}"

    ./yocto/meta-nexell/tools/update_${BOARD_SOCNAME}.sh -p $ROOT_PATH/yocto/${RESULT_DIR}/partmap_emmc.txt -r $ROOT_PATH/yocto/${RESULT_DIR} ${PARTIAL_UPDATE_ARGS}

    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m   Download Complete                                                \033[0m"    
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"    

}

check_usage
parse_args $@
split_machine_name
binary_download
