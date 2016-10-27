#!/bin/bash

set -e

TOP=`pwd`
argc=$#
MACHINE_NAME=$1
IMAGE_TYPE=$2
RESULT_DIR=

BOARD_SOCNAME=
BOARD_NAME=
BOARD_PREFIX=
BOARD_POSTFIX=

ARM_ARCH=

INTERACTIVE_MODE=false
CLEAN_BUILD=false

BUILD_ALL=true
BUILD_BL1=false
BUILD_UBOOT=false
BUILD_OPTEE=false
BUILD_KERNEL=false

KERNEL_PATH=${TOP}/kernel/kernel-4.4.19
NEED_KERNEL_MAKE_CLEAN=false

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
    ARGS=$(getopt -o cht: -- "$@");
    eval set -- "$ARGS";

    while true; do
            case "$1" in
		-c ) CLEAN_BUILD=true; shift 1 ;;
		-t ) case "$2" in
			 bl1    ) BUILD_ALL=false; BUILD_BL1=true ;;
			 uboot  ) BUILD_ALL=false; BUILD_UBOOT=true ;;
			 kernel ) BUILD_ALL=false; BUILD_KERNEL=true ;;
			 optee  ) BUILD_ALL=false; BUILD_OPTEE=true ;;
			 *      ) usage; exit 1 ;;
		     esac
		     shift 2 ;;
		-h ) usage; exit 1 ;;
                -- ) break ;;
            esac
    done
}

function usage()
{
    echo -e "\nUsage: $0 <machine-name> <image-type> [-c -t bl1 -t uboot -t kernel -t optee] \n"
    echo -e " <machine-name> : "
    echo -e "        s5p6818-artik710-raptor or s5p6818-artik710-raptor or s5p6818-artik710-raptor or s5p4418-avn-ref ...\n"
    echo -e " <image-type> : "
    echo -e "        qt, tiny, sato, tinyui \n"
    echo -e " -c : cleanbuild"
    echo -e " -t bl1    : if you want to build only bl1, specify this, default no"
    echo -e " -t uboot : if you want to build only uboot, specify this, default no"
    echo -e " -t kernel : if you want to build only kernel, specify this, default no"
    echo -e " -t optee  : if you want to build only optee, specify this, default no\n"
    echo " ex) $0 s5p6818-artik710-raptor tiny -c -t kernel"
    echo " ex) $0 s5p6818-artik710-raptor sato -c -t uboot"
    echo " ex) $0 s5p6818-artik710-raptor qt"
    echo " ex) $0 s5p6818-avn-ref tiny"
    echo " ex) $0 s5p6818-avn-ref qt"
    echo " ex) $0 s5p4418-avn-ref qt"    
    echo " ex) $0 s5p4418-avn-ref tiny"
    echo " ex) $0 s5p4418-navi-ref qt -t kernel -t uboot -t bl1"
    echo " ex) $0 s5p4418-navi-ref tiny -c"
    echo " ex) $0 s5p4418-navi-ref tinyui"
    echo ""
}

function split_machine_name()
{
    BOARD_SOCNAME=${MACHINE_NAME%-*-*}
    BOARD_NAME=${MACHINE_NAME#*-}
    BOARD_PREFIX=${BOARD_NAME%-*}
    BOARD_POSTFIX=${BOARD_NAME#*-}

    if [ ${BOARD_SOCNAME} == 's5p6818' ]; then
	ARM_ARCH="arm64"
    else
	ARM_ARCH="arm"
    fi
    
}

function gen_and_copy_bbappend()
{
    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m                       .bbappend files generate                     \033[0m"
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"
    
    local ROOT_PATH=${TOP}
    cd $ROOT_PATH/tools/bbappend-files
    ./gen_bbappend.sh $ROOT_PATH
    cp -a $ROOT_PATH/tools/bbappend-files/recipes-* $ROOT_PATH/yocto/meta-nexell

    echo -e "\033[47;34m ------------------------ Generate Done ! ------------------------- \033[0m"
}

function bitbake_run()
{
    local ROOT_PATH=${TOP}
    local CLEAN_RECIPES=

    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m                       Bitbake Auto Running                         \033[0m"
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"    
    
    cd $ROOT_PATH/yocto
    source poky/oe-init-build-env build-${MACHINE_NAME}-${IMAGE_TYPE}
    ../meta-nexell/tools/envsetup.sh ${MACHINE_NAME} ${IMAGE_TYPE}

    if [ ${CLEAN_BUILD} == "true" ];then
	if [ ${BOARD_SOCNAME} == "s5p6818" ];then
            CLEAN_RECIPES+=" testsuite-s5p6818 optee-build optee-linuxdriver"
        else
            CLEAN_RECIPES+=" testsuite-s5p4418"
	fi

	CLEAN_RECIPES+=" ${MACHINE_NAME}-${IMAGE_TYPE} virtual/kernel"
	NEED_KERNEL_MAKE_CLEAN=true
    fi

    local BITBAKE_ARGS=
    if [ ${BUILD_ALL} == "false" ];then
        if [ ${BUILD_KERNEL} == "true" ]; then
            BITBAKE_ARGS+=" virtual/kernel"
            #NEED_KERNEL_MAKE_CLEAN=true
        fi
        if [ ${BUILD_BL1} == "true" ]; then
            BITBAKE_ARGS+=" ${MACHINE_NAME}-bl1"
        fi
        if [ ${BUILD_UBOOT} == "true" ]; then
            BITBAKE_ARGS+=" ${MACHINE_NAME}-uboot"
        fi
        if [ ${BUILD_OPTEE} == "true" ]; then
            BITBAKE_ARGS+=" optee-build optee-linuxdriver"
        else
            if [ ${BOARD_SOCNAME} == "s5p6818" -a ${BUILD_UBOOT} == "true" -a ${BUILD_OPTEE} == "false" ]; then
                BITBAKE_ARGS+=" optee-build optee-linuxdriver"
            fi
        fi

	CLEAN_RECIPES+=" $BITBAKE_ARGS"

        kernel_make_clean
	bitbake -c cleanall $CLEAN_RECIPES
	echo -e "\033[47;34m CLEAN TARGET : $CLEAN_RECIPES \033[0m"
	echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
        echo -e "\033[47;34m                          Partial Build                             \033[0m"
        echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"
	echo -e "\033[47;34m $BITBAKE_ARGS \033[0m"
	echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"
	bitbake $BITBAKE_ARGS
    else
        kernel_make_clean
	echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
        echo -e "\033[47;34m                          All Build                                 \033[0m"
        echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"
        if [ ${CLEAN_BUILD} == "true" ];then
            bitbake -c cleanall $CLEAN_RECIPES
        fi
	echo -e "\033[47;34m CLEAN TARGET : $CLEAN_RECIPES \033[0m"
        bitbake ${MACHINE_NAME}-${IMAGE_TYPE}
    fi
}

function kernel_make_clean()
{
    local oldpath=`pwd`
    if [ $NEED_KERNEL_MAKE_CLEAN == true ];then
        echo -e "\n ------------------------------------------------------------------ "
        echo -e "                        make distclean                              "
        echo -e " ------------------------------------------------------------------ "
        cd ${KERNEL_PATH}
        make distclean
        cd $oldpath
    fi
}

function move_images()
{
    local ROOT_PATH=${TOP}
    RESULT_DIR="result-${MACHINE_NAME}-${IMAGE_TYPE}"
    
    cd $ROOT_PATH/yocto/build-${MACHINE_NAME}-${IMAGE_TYPE}
    ../meta-nexell/tools/result-file-move.sh ${MACHINE_NAME} ${IMAGE_TYPE} ${BUILD_ALL}
}

function convert_images()
{
    local ROOT_PATH=${TOP}
    RESULT_DIR="result-${MACHINE_NAME}-${IMAGE_TYPE}"

    echo -e "\n\033[0;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[0;36m                      Convert images Running                        \033[0m"
    echo -e "\033[0;34m ------------------------------------------------------------------ \033[0m"
    
    cd $ROOT_PATH/yocto/${RESULT_DIR}
    ../meta-nexell/tools/convert_images.sh ${MACHINE_NAME} ${IMAGE_TYPE}
    
    echo -e "\n\033[0;34m --------------------------------------------------------------------------- \033[0m\n"
    echo -e "\033[0;36m  1. cd $ROOT_PATH/yocto/${RESULT_DIR}                                        \033[0m\n"
    echo -e "\033[0;36m     ../meta-nexell/tools/update_${BOARD_SOCNAME}.sh -p partmap_emmc.txt -r . \033[0m\n"
    echo -e "\033[0;36m     or                                                                       \033[0m\n"
    echo -e "\033[0;36m  2. ./tools/update.sh ${MACHINE_NAME} ${IMAGE_TYPE}                          \033[0m\n"
    echo -e "\033[0;34m ---------------------------------------------------------------------------- \033[0m\n"
}

function optee_clean()
{
    local ROOT_PATH=${TOP}
    
    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m                       Optee Clean SSTATE                           \033[0m"
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"    
    
    cd $ROOT_PATH/yocto
    source poky/oe-init-build-env build-${MACHINE_NAME}-${IMAGE_TYPE}
    ../meta-nexell/tools/optee_clean_${BOARD_NAME}.sh
}

parse_args $@
check_usage
split_machine_name

gen_and_copy_bbappend
bitbake_run
move_images
convert_images

