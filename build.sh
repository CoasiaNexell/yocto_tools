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
KERNEL_BUILD=false

function check_usage()
{
    if [ $argc -gt 3 -o $argc -lt 2 ]
    then
	echo "Invalid argument check usage please"
	usage
	exit
    fi
}
function parse_args()
{
    ARGS=$(getopt -o c:k:h -- "$@");
    eval set -- "$ARGS";
    
    while true; do
            case "$1" in
		-c )
		    shift;
		    MACHINE_NAME=$1;
		    shift;
		    IMAGE_TYPE=$2;
		    CLEAN_BUILD=true;
		    break;
		    ;;
		-k )
		    shift;
		    MACHINE_NAME=$1;
		    shift;
		    IMAGE_TYPE=$2;
		    KERNEL_BUILD=true;
		    break;
		    ;;
		-h )
		    usage;
		    exit 1;
		    ;;
                -- )
		    shift;
		    break;
		    ;;
            esac
    done
}

function usage()
{
    echo -e "\nUsage: $0 [-i interactive -c opteeClean] <machine-name> <image-type>\n"
    echo -e " <machine-name> : "
    echo -e "        s5p6818-artik710-raptor or s5p6818-artik710-raptor or s5p6818-artik710-raptor or s5p4418-avn-ref ...\n"
    echo -e " <image-type> : "
    echo -e "        qt, tiny, sato, tinyui \n"
    echo " ex) $0 s5p6818-artik710-raptor tiny"
    echo " ex) $0 s5p6818-artik710-raptor sato"
    echo " ex) $0 s5p6818-artik710-raptor qt"
    echo " ex) $0 s5p6818-avn-ref tiny"
    echo " ex) $0 s5p6818-avn-ref qt"
    echo " ex) $0 s5p4418-avn-ref qt"    
    echo " ex) $0 s5p4418-avn-ref tiny"
    echo " ex) $0 s5p4418-navi-ref qt"
    echo " ex) $0 s5p4418-navi-ref tiny"
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
    
    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m                       Bitbake Auto Running                         \033[0m"
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"    
    
    cd $ROOT_PATH/yocto
    source poky/oe-init-build-env build-${MACHINE_NAME}-${IMAGE_TYPE}
    ../meta-nexell/tools/envsetup.sh ${MACHINE_NAME} ${IMAGE_TYPE}

    if [ ${CLEAN_BUILD} == "true" ];then
	echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
        echo -e "\033[47;34m                          Clean Build                               \033[0m"
        echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"
	if [ ${BOARD_SOCNAME} == "s5p6818" ];then
            ../meta-nexell/tools/optee_clean_${BOARD_NAME}.sh
            bitbake -c cleanall testsuite-s5p6818

        else
            bitbake -c cleanall testsuite-s5p4418
	fi

        bitbake -c cleanall virtual/kernel gst-plugins-camera gst-plugins-renderer gst-plugins-scaler gst-plugins-video-dec gst-plugins-video-enc \
		            gst-plugins-video-sink libdrm-nx libomxil-nx nx-drm-allocator nx-gst-meta nx-renderer nx-scaler nx-v4l2 nx-video-api
    fi
    bitbake ${MACHINE_NAME}-${IMAGE_TYPE}
}

function move_images()
{
    local ROOT_PATH=${TOP}
    RESULT_DIR="result-${MACHINE_NAME}-${IMAGE_TYPE}"
    
    cd $ROOT_PATH/yocto/build-${MACHINE_NAME}-${IMAGE_TYPE}
    ../meta-nexell/tools/result-file-move.sh ${MACHINE_NAME} ${IMAGE_TYPE}    
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

function build_kernel()
{
    local ROOT_PATH=${TOP}
    local KERNEL_PATH=$ROOT_PATH/kernel/kernel-4.1.15
    local KERNEL_DEFCONFIG=
    local dts_file=
    local KERNEL_BUILD_OUT=${TOP}/kernel_build_out
    local CROSS_COMPILE32="${ROOT_PATH}/yocto/build-${MACHINE_NAME}-${IMAGE_TYPE}/tmp/sysroots/x86_64-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-"
    local CROSS_COMPILE64="${ROOT_PATH}/yotco/build-${MACHINE_NAME}-${IMAGE_TYPE}/tmp/sysroots/x86_64-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-"
    local KERNEL_IMAGE_TYPE=
    local KERNEL_COMMON_FLAGS=
    local file_name_dtb=
    
    echo ${ROOT_PATH}
    cd ${ROOT_PATH}
    if [ ! -d kernel_build_out ]; then
	mkdir kernel_build_out
    fi

    
    if [ ${BOARD_SOCNAME} == "s5p6818" ];then
	KERNEL_IMAGE_TYPE="Image"
	KERNEL_COMMON_FLAGS="ARCH=${ARM_ARCH} CROSS_COMPILE=${CROSS_COMPILE64}"
    else
	KERNEL_IMAGE_TYPE="zImage"
	KERNEL_COMMON_FLAGS="ARCH=${ARM_ARCH} CROSS_COMPILE=${CROSS_COMPILE32}"
    fi
    
    if [ ${MACHINE_NAME} == "s5p6818-artik710-raptor" ];then
	dts_file=$KERNEL_PATH/arch/${ARM_ARCH}/boot/dts/nexell/s5p6818-artik710.dtsi
	KERNEL_DEFCONFIG="artik710_raptor_defconfig"
	file_name_dtb="s5p6818-artik710-raptor*.dtb"
    elif [ ${MACHINE_NAME} == "s5p6818-avn-ref" ];then
        dts_file=$KERNEL_PATH/arch/${ARM_ARCH}/boot/dts/nexell/s5p6818-avn-ref-common.dtsi
	KERNEL_DEFCONFIG="s5p6818_avn_ref_defconfig"
	file_name_dtb="s5p6818-avn-ref*.dtb"
    else
	dts_file=$KERNEL_PATH/arch/${ARM_ARCH}/boot/dts/${BOARD_SOCNAME}-${BOARD_PREFIX}_${BOARD_POSTFIX}-rev00.dts
	KERNEL_DEFCONFIG="${BOARD_SOCNAME}_${BOARD_PREFIX}_${BOARD_POSTFIX}_defconfig"
	if [ ${BOARD_PREFIX} == "avn" ]; then
	    file_name_dtb="s5p4418-avn_ref*.dtb"
	elif [ ${BOARD_PREFIX} == "navi" ]; then
	    file_name_dtb="s5p4418-navi_ref*.dtb"
	fi
    fi

    echo ${MACHINE_NAME}
    echo ${KERNEL_DEFCONFIG}
    
    cd ${KERNEL_PATH}
    make ARCH=${ARM_ARCH} distclean
    make ARCH=${ARM_ARCH} ${KERNEL_DEFCONFIG}

    make ${KERNEL_COMMON_FLAGS} ${KERNEL_IMAGE_TYPE} -j8
    make ${KERNEL_COMMON_FLAGS} dtbs
    make ${KERNEL_COMMON_FLAGS} modules -j8

    make ${KERNEL_COMMON_FLAGS} modules_install INSTALL_MOD_PATH=${KERNEL_BUILD_OUT} INSTALL_MOD_STRIP=1

    cp arch/${ARM_ARCH}/boot/${KERNEL_IMAGE_TYPE} ${KERNEL_BUILD_OUT}
    cp arch/${ARM_ARCH}/boot/dts/${file_name_dtb} ${KERNEL_BUILD_OUT} 

    #move result files
    cp ${KERNEL_BUILD_OUT}/${KERNEL_IMAGE_TYPE} $ROOT_PATH/yocto/${RESULT_DIR}
    cp ${KERNEL_BUILD_OUT}/*.dtb $ROOT_PATH/yocto/${RESULT_DIR}
}


parse_args $@
check_usage
split_machine_name

gen_and_copy_bbappend
bitbake_run
move_images

if [ ${KERNEL_BUILD} == "true" ];then
    build_kernel
fi

convert_images
