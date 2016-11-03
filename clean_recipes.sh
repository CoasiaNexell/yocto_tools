#!/bin/bash

set -e

CURRENT_PATH=`dirname $0`
TOOLS_PATH=`readlink -e $CURRENT_PATH`
ROOT_PATH=`readlink -e ${TOOLS_PATH}/..`

argc=$#
MACHINE_NAME=$1
IMAGE_TYPE=$2

BOARD_SOCNAME=
BOARD_NAME=
BOARD_PREFIX=
BOARD_POSTFIX=

CLEAN_ARGS=

function check_usage()
{
    if [ $argc -lt 2 ]
    then
	echo "Invalid argument check usage please"
	usage
	exit
    fi
}
function parse_args()
{
    shift 2
    for var in "$@"
    do
	CLEAN_ARGS+=" $var"
    done

    echo $CLEAN_ARGS
}

function usage()
{
    echo -e "\nUsage: $0 <machine-name> <image-type> [virtual/kernel openssl systemd qtquick1 ...] \n"
    echo -e " <machine-name> : "
    echo -e "        s5p6818-artik710-raptor or s5p6818-artik710-raptor or s5p6818-artik710-raptor or s5p4418-avn-ref ...\n"
    echo -e " <image-type> : "
    echo -e "        qt, tiny, sato, tinyui \n"
    echo " ex) $0 s5p4418-navi-ref qt virtual/kernel openssl qtquick1"
    echo ""
}

function split_machine_name()
{
    BOARD_SOCNAME=${MACHINE_NAME%-*-*}
    BOARD_NAME=${MACHINE_NAME#*-}
    BOARD_PREFIX=${BOARD_NAME%-*}
    BOARD_POSTFIX=${BOARD_NAME#*-}
}

function bitbake_run()
{
    if [ ${IMAGE_TYPE} == "genivi" ]; then
        #------------------------ Genivi platform setup ------------------------
        cd ${GENIVI_PATH}
        source init.sh nexell
        #-----------------------------------------------------------------------
    else
        #------------------------ Nexell platform setup ------------------------
        cd ${ROOT_PATH}/yocto
        source poky/oe-init-build-env build-${MACHINE_NAME}-${IMAGE_TYPE}
        #-----------------------------------------------------------------------
    fi

    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m                          Clean Recipes                             \033[0m"
    echo -e " ==> Clean List : $CLEAN_ARGS "
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"
    bitbake -c cleanall $CLEAN_ARGS
}

check_usage
parse_args $@
split_machine_name
bitbake_run
