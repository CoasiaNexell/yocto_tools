#!/bin/bash

set -e

CURRENT_PATH=`dirname $0`
TOOLS_PATH=`readlink -ev $CURRENT_PATH`
ROOT_PATH=`readlink -ev ${TOOLS_PATH}/../..`

RESULT_PATH=$1
KERNEL_PATH=$2

NEXELL_SOURCE_PATH_BL1_S5P6818=${ROOT_PATH}/bl1/bl1-s5p6818
NEXELL_SOURCE_PATH_ATF=${ROOT_PATH}/secure/arm-trusted-firmware
NEXELL_SOURCE_PATH_LLOADER=${ROOT_PATH}/secure/l-loader
NEXELL_SOURCE_PATH_OPTEE_BUILD=${ROOT_PATH}/secure/optee/optee_build
NEXELL_SOURCE_PATH_OPTEE_CLIENT=${ROOT_PATH}/secure/optee/optee_client
NEXELL_SOURCE_PATH_OPTEE_LINUXDRIVER=${ROOT_PATH}/secure/optee/optee_linuxdriver
NEXELL_SOURCE_PATH_OPTEE_OS=${ROOT_PATH}/secure/optee/optee_os
NEXELL_SOURCE_PATH_OPTEE_TEST=${ROOT_PATH}/secure/optee/optee_test
NEXELL_SOURCE_PATH_UBOOT=${ROOT_PATH}/u-boot/u-boot-2016.01

NEXELL_SOURCE_PATH_KERNEL=${KERNEL_PATH}
NEXELL_SOURCE_PATH_CGMINER=${ROOT_PATH}/apps/cgminer

NEXELL_SOURCE_PATH_META_NEXELL=${ROOT_PATH}/yocto/meta-nexell
NEXELL_SOURCE_PATH_TOOLS=${ROOT_PATH}/tools

declare -a nexell_source_paths=($NEXELL_SOURCE_PATH_BL1_S5P6818
                                $NEXELL_SOURCE_PATH_UBOOT       $NEXELL_SOURCE_PATH_KERNEL

                                $NEXELL_SOURCE_PATH_ATF         $NEXELL_SOURCE_PATH_LLOADER
                                $NEXELL_SOURCE_PATH_OPTEE_BUILD $NEXELL_SOURCE_PATH_OPTEE_CLIENT
                                $NEXELL_SOURCE_PATH_OPTEE_LINUXDRIVER
                                $NEXELL_SOURCE_PATH_OPTEE_OS    $NEXELL_SOURCE_PATH_OPTEE_TEST

                                $NEXELL_SOURCE_PATH_CGMINER

                                $NEXELL_SOURCE_PATH_META_NEXELL
                                $NEXELL_SOURCE_PATH_TOOLS
)

function make_build_info()
{
    local curpath=`pwd`
    cp -a ${TOOLS_PATH}/YOCTO-BUILD-INFO.txt ${RESULT_PATH}

    # build user write
    echo "BUILD user : $USER" >> ${RESULT_PATH}/YOCTO-BUILD-INFO.txt

    for i in ${nexell_source_paths[@]}
    do
        cd $i
        echo '--------------------------------------------------------------------------------' >> ${RESULT_PATH}/YOCTO-BUILD-INFO.txt
        echo $i >> ${RESULT_PATH}/YOCTO-BUILD-INFO.txt
        echo `git log -1 --pretty=oneline` >> ${RESULT_PATH}/YOCTO-BUILD-INFO.txt
        echo `git log -1 --pretty=format:"%cd"` >> ${RESULT_PATH}/YOCTO-BUILD-INFO.txt
    done

    cd $curpath
}

make_build_info
