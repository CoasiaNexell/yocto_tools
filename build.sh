#!/bin/bash

set -e

CURRENT_PATH=`dirname $0`
TOOLS_PATH=`readlink -ev $CURRENT_PATH`
ROOT_PATH=`readlink -ev ${TOOLS_PATH}/..`

argc=$#
MACHINE_NAME=$1
IMAGE_TYPE=$2
RESULT_DIR="result-${MACHINE_NAME}-${IMAGE_TYPE}"
RESULT_PATH=

BOARD_SOCNAME=
BOARD_NAME=
BOARD_PREFIX=
BOARD_POSTFIX=

ARM_ARCH=

INTERACTIVE_MODE=false
CLEAN_BUILD=false
SDK_RELEASE=false
NUMBER_THREADS="-1"

BUILD_ALL=true
BUILD_BL1=false
BUILD_UBOOT=false
BUILD_OPTEE=false
BUILD_KERNEL=false

KERNEL_PATH=`readlink -ev ${ROOT_PATH}/kernel/`
KERNEL_DIRNAME=
KERNEL_FULLPATH=
NEED_KERNEL_MAKE_CLEAN=false

META_NEXELL_PATH=`readlink -ev ${ROOT_PATH}/yocto/meta-nexell`
GENIVI_PATH=`readlink -e ${ROOT_PATH}/yocto/GENIVI`

declare -a targets=("s5p4418-avn-ref" "s5p4418-navi-ref" "s5p6818-artik710-raptor" "s5p6818-avn-ref" "s5p4418-smart-voice" "s5p6818-kick-st")
declare -a imagetypes=("qt" "tiny" "sato" "tinyui" "genivi" "smartvoice")

function check_usage()
{
    if [ $argc -lt 2 ]
    then
	echo "Invalid argument check usage please"
	usage
	exit
    fi

    local existTarget=false
    local existImageTypes=false

    for i in ${targets[@]}
    do
        if [ $i == ${MACHINE_NAME} ]; then
            existTarget=true
            echo -e "\033[47;34m Select targets : $i \033[0m"
            break
        fi
    done

    for j in ${imagetypes[@]}
    do
        if [ $j == ${IMAGE_TYPE} ]; then
            existImageTypes=true
            echo -e "\033[47;34m Select imageTypes : $j \033[0m"
            break
        fi
    done

    if [ $existTarget == false ]; then
        echo -e "\033[47;34m Please check you selected machine name ==> ${MACHINE_NAME} \033[0m"
        echo -e "\033[47;34m Check again \033[0m"
        usage
        exit
    fi
    if [ $existImageTypes == false ]; then
        echo -e "\033[47;34m Please check you selected image types ==> ${IMAGE_TYPE} \033[0m"
        echo -e "\033[47;34m Maybe this imagetype does not support \033[0m"
        usage
        exit
    fi
}
function parse_args()
{
    ARGS=$(getopt -o csht:n: -- "$@");
    eval set -- "$ARGS";

    while true; do
            case "$1" in
		-c ) CLEAN_BUILD=true; shift 1 ;;
		-s ) SDK_RELEASE=true; shift 1 ;;
                -n ) NUMBER_THREADS="$2"; shift 2 ;;
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
    echo -e "\nUsage: $0 <machine-name> <image-type> [-c -t bl1 -t uboot -t kernel -t optee] [-s] \n"
    echo -e " <machine-name> : "
    echo -e "        s5p6818-artik710-raptor or s5p6818-artik710-raptor or s5p6818-artik710-raptor or s5p4418-avn-ref ...\n"
    echo -e " <image-type> : "
    echo -e "        qt, tiny, sato, tinyui \n"
    echo -e " -s : sdk create"
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
    echo " ex) $0 s5p4418-navi-ref genivi"
    echo " ex) $0 s5p4418-navi-ref qt -s"
    echo " ex) $0 s5p4418-smart-voice smartvoice -c"
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

    cd ${TOOLS_PATH}/bbappend-files
    ./gen_bbappend.sh ${ROOT_PATH}
    cp -a ${TOOLS_PATH}/bbappend-files/recipes-* ${META_NEXELL_PATH}

    echo -e "\033[47;34m ------------------------ Generate Done ! ------------------------- \033[0m"
}

function kernel_version_sync()
{
    local tempTOP=${PWD}

    cd ${KERNEL_PATH}
    for entry_d in ./*
    do
        if [ -d "$entry_d" ];then
            cd $entry_d
            for entry_f in ./Makefile
            do
                if [ -f "$entry_f" ];then
                    echo "file name : $entry_f"
                    KERNEL_DIRNAME=$entry_d
                    break
                fi
            done
            echo "dir name : $entry_d"
            cd ..
        fi
    done

    cd $tempTOP
    echo "Finally kernel dirname : $KERNEL_DIRNAME"
    KERNEL_FULLPATH=${KERNEL_PATH}/${KERNEL_DIRNAME}
    python ${TOOLS_PATH}/kernel_version_sync.py \
           ${META_NEXELL_PATH}/recipes-kernel/linux/linux-${MACHINE_NAME}_%.bbappend \
           ${ROOT_PATH} \
           ${KERNEL_DIRNAME}
}

function bitbake_run()
{
    local CLEAN_RECIPES=

    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m                       Bitbake Auto Running                         \033[0m"
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"

    if [ ${IMAGE_TYPE} == "genivi" ]; then
        #------------------------ Genivi platform setup ------------------------
        cd ${GENIVI_PATH}
        ${META_NEXELL_PATH}/tools/envsetup_genivi.sh ${MACHINE_NAME} ${NUMBER_THREADS}
        source init.sh nexell ${MACHINE_NAME}
        #-----------------------------------------------------------------------
    else
        #------------------------ Nexell platform setup ------------------------
        cd ${ROOT_PATH}/yocto
        source poky/oe-init-build-env build-${MACHINE_NAME}-${IMAGE_TYPE}
        ${META_NEXELL_PATH}/tools/envsetup.sh ${MACHINE_NAME} ${IMAGE_TYPE} ${NUMBER_THREADS} ${SDK_RELEASE}
        #-----------------------------------------------------------------------
    fi

    if [ ${CLEAN_BUILD} == "true" ];then
	if [ ${BOARD_SOCNAME} == "s5p6818" ];then
            CLEAN_RECIPES+=" optee-build optee-linuxdriver"
	fi

        if [ ${IMAGE_TYPE} == "tiny" -o ${IMAGE_TYPE} == "tinyui" -o ${IMAGE_TYPE} == "smartvoice" ]; then
           echo "tiny or tinyui or smartvoice build"
        else
           CLEAN_RECIPES+=" testsuite-${BOARD_SOCNAME}"
        fi

        if [ ${IMAGE_TYPE} == "genivi" ]; then
            CLEAN_RECIPES+=" ${MACHINE_NAME}-qt virtual/kernel"
        else
            CLEAN_RECIPES+=" ${MACHINE_NAME}-${IMAGE_TYPE} virtual/kernel"
        fi
	NEED_KERNEL_MAKE_CLEAN=true
    fi

    local BITBAKE_ARGS=
    if [ ${BUILD_ALL} == "false" ];then
        if [ ${SDK_RELEASE} == "true" ]; then
            echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
            echo -e "\033[47;34m Strange arguments !!  Please check Usage!!                         \033[0m"
            echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"
            usage
            exit
        fi

        if [ ${BUILD_KERNEL} == "true" ]; then
            BITBAKE_ARGS+=" virtual/kernel"
            #NEED_KERNEL_MAKE_CLEAN=true
        fi
        if [ ${BUILD_BL1} == "true" ]; then
            BITBAKE_ARGS+=" ${MACHINE_NAME}-bl1 ${MACHINE_NAME}-bl2 ${MACHINE_NAME}-dispatcher"
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

        if [ ${IMAGE_TYPE} == "genivi" ]; then
            #------------------------ Genivi platform build ------------------------
            if [ ${SDK_RELEASE} == "true" ]; then
                bitbake genivi-dev-platform-sdk -c populate_sdk
            else
                bitbake genivi-dev-platform
            fi
            #-----------------------------------------------------------------------
        else
            if [ ${SDK_RELEASE} == "true" ]; then
                echo -e "\033[47;34m bitbake -c populate_sdk ${BOARD_SOCNAME}-${IMAGE_TYPE}-sdk \033[0m"
                bitbake -c populate_sdk ${BOARD_SOCNAME}-${IMAGE_TYPE}-sdk
            else
                #------------------------ Nexell platform build ------------------------
                bitbake ${MACHINE_NAME}-${IMAGE_TYPE}
                #-----------------------------------------------------------------------
            fi
        fi
    fi
}

function kernel_make_clean()
{
    local oldpath=`pwd`
    if [ $NEED_KERNEL_MAKE_CLEAN == true ];then
        echo -e "\n ------------------------------------------------------------------ "
        echo -e "                        make distclean                              "
        echo -e " ------------------------------------------------------------------ "

        cd ${KERNEL_FULLPATH}

        file_count=$(ls -Rl ${KERNEL_FULLPATH} | grep ^- | wc -l)
        dir_size=$(du -sb ${KERNEL_FULLPATH} | cut -f1)
        if [ $file_count -lt 5 ] || [ $dir_size -lt 16 ]; then
            echo -e " Strange kernel source! "
            echo -e " Not exist files or kernel path broken "
            echo -e " file count = $file_count   ==> ${KERNEL_FULLPATH} "
            echo -e " dir size   = $dir_size  ==> ${KERNEL_FULLPATH} "
            echo -e " ------------------------------------------------------------------ "
            repo sync ${KERNEL_FULLPATH}
        fi
        make distclean
        cd $oldpath
    fi
}

function move_images()
{
    if [ ${SDK_RELEASE} == "true" ]; then
        local build_path=`readlink -ev ${META_NEXELL_PATH}/../build-${MACHINE_NAME}-${IMAGE_TYPE}/tmp/deploy/sdk`
        RESULT_PATH=$build_path
        echo -e "\n\033[0;34m ------------------------------------------------------------------ \033[0m"
        echo -e "\033[0;36m  Please check below path                                           \033[0m"
        echo -e "  $build_path    "
        echo -e "\033[0;34m ------------------------------------------------------------------ \033[0m"
    else
        ${META_NEXELL_PATH}/tools/result-file-move.sh ${MACHINE_NAME} ${IMAGE_TYPE} ${BUILD_ALL}
        RESULT_PATH=`readlink -ev ${ROOT_PATH}/yocto/${RESULT_DIR}`
    fi
}

function convert_images()
{
    if [ ${SDK_RELEASE} == "true" ]; then
        echo -e "\033[0;36m The SDK images does not require converting.                        \033[0m"
    else
	echo -e "\n\033[0;34m ------------------------------------------------------------------ \033[0m"
	echo -e "\033[0;36m                      Convert images Running                        \033[0m"
	echo -e "\033[0;34m ------------------------------------------------------------------ \033[0m"

	cd ${RESULT_PATH}
	${META_NEXELL_PATH}/tools/convert_images.sh ${MACHINE_NAME} ${IMAGE_TYPE}

	echo -e "\n\033[0;34m ------------------------------------------------------------------------------------------ \033[0m\n"
	echo -e "\033[0;36m  1. ${META_NEXELL_PATH}/tools/update.sh -p ${RESULT_PATH}/partmap_emmc.txt -r ${RESULT_PATH} \033[0m\n"
	echo -e "\033[0;36m     or                                                                                       \033[0m\n"
	echo -e "\033[0;36m  2. ${TOOLS_PATH}/update.sh ${MACHINE_NAME} ${IMAGE_TYPE}                                    \033[0m\n"
	echo -e "\033[0;34m -------------------------------------------------------------------------------------------- \033[0m\n"
    fi
}

function make_build_info()
{
    if [ ${SDK_RELEASE} == "false" ]; then
        ${TOOLS_PATH}/make_build_info.sh ${RESULT_PATH} ${KERNEL_FULLPATH}
    fi
}

function make_standalone_tools()
{
    if [ ${SDK_RELEASE} == "false" ]; then
        mkdir -p ${RESULT_PATH}/tools

        cp -a ${META_NEXELL_PATH}/tools/${MACHINE_NAME}/* ${RESULT_PATH}/tools/
        cp -a ${META_NEXELL_PATH}/tools/standalone-fastboot-download.sh ${RESULT_PATH}/tools/
        cp -a ${META_NEXELL_PATH}/tools/standalone-uboot-by-usb-download.sh ${RESULT_PATH}/tools/

        cp -a ${META_NEXELL_PATH}/tools/usb-downloader ${RESULT_PATH}/tools/

        cp -a ${RESULT_PATH}/partition.txt ${RESULT_PATH}/tools/
    fi
}

function make_nexell_server_documnets()
{
    ${TOOLS_PATH}/make_documents.sh ${MACHINE_NAME} ${RESULT_PATH} ${SDK_RELEASE}
}


function optee_clean()
{
    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m                       Optee Clean SSTATE                           \033[0m"
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"

    if [ ${IMAGE_TYPE} == "genivi" ]; then
        #------------------------ Genivi platform build ------------------------
        source ${GENIVI_PATH}/init.sh nexell ${MACHINE_NAME}
        #-----------------------------------------------------------------------
    else
        #------------------------ Nexell platform build ------------------------
        cd ${ROOT_PATH}/yocto
        source poky/oe-init-build-env build-${MACHINE_NAME}-${IMAGE_TYPE}
        #-----------------------------------------------------------------------
    fi

    ${META_NEXELL_PATH}/tools/optee_clean_${BOARD_NAME}.sh
}

parse_args $@
check_usage
split_machine_name

gen_and_copy_bbappend
kernel_version_sync
bitbake_run
move_images
convert_images
make_build_info
make_standalone_tools
make_nexell_server_documnets
