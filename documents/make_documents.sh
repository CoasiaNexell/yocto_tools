#!/bin/bash

set -e

CURRENT_PATH=`dirname $0`
TOOLS_PATH=`readlink -ev $CURRENT_PATH`
ROOT_PATH=`readlink -ev ${TOOLS_PATH}/../..`

MACHINE_NAME=$1
RESULT_PATH=$2
SDK_RELEASE=$3

HOWTO_RELEASE="HOWTO_releasenotes.txt"
HOWTO_INSTALL="HOWTO_install"  #HOWTO_install-{BOARD_SOCNAME}.txt
HOWTO_BUILD="HOWTO_getsourceandbuild.txt"
BOARD_SOCNAME=

function split_machine_name()
{
    BOARD_SOCNAME=${MACHINE_NAME%-*-*}
}

function make_releasenote()
{
    cp -a ${TOOLS_PATH}/${HOWTO_RELEASE} ${RESULT_PATH}

    echo "** TARGET BOARD : ${MACHINE_NAME}" >> ${RESULT_PATH}/${HOWTO_RELEASE}
    echo "" >> ${RESULT_PATH}/${HOWTO_RELEASE}

    echo "** YOCTO COMPONENTs INFO :" >> ${RESULT_PATH}/${HOWTO_RELEASE}
    python ${TOOLS_PATH}/yocto_branch_check.py \
           ${ROOT_PATH} \
           ${RESULT_PATH}/${HOWTO_RELEASE}

    echo "" >> ${RESULT_PATH}/${HOWTO_RELEASE}
    echo "bc. " >> ${RESULT_PATH}/${HOWTO_RELEASE}
    echo "" >> ${RESULT_PATH}/${HOWTO_RELEASE}

#    cat ${RESULT_PATH}/YOCTO-BUILD-INFO.txt >> ${RESULT_PATH}/HOWTO_releasenotes.txt
}

function make_install_guide()
{
    cp -a ${TOOLS_PATH}/${HOWTO_INSTALL}-${BOARD_SOCNAME}.txt ${RESULT_PATH}/${HOWTO_INSTALL}.txt
}

function make_build_guide()
{
    cp -a ${TOOLS_PATH}/${HOWTO_BUILD} ${RESULT_PATH}
}

function make_sdk_guide()
{
    cp -a ${TOOLS_PATH}/${HOWTO_INSTALL}-SDK.txt ${RESULT_PATH}/${HOWTO_INSTALL}.txt
}

split_machine_name
if [ "${SDK_RELEASE}" == "true" ]; then
    make_sdk_guide
else
    make_releasenote
    make_install_guide
#make_build_guide
fi
