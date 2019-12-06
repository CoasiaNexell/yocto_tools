#!/bin/bash

CURRENT_PATH=`dirname $0`
TOOLS_PATH=`readlink -ev $CURRENT_PATH`
ROOT_PATH=`readlink -ev ${TOOLS_PATH}/..`

argc=$#
MACHINE_NAME=$1
IMAGE_TYPE=$2
RESULT_DIR="result-${MACHINE_NAME}-${IMAGE_TYPE}"
RESULT_PATH=

BUILD_PATH=

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
KERNEL_PARTITAL_BUILD=false
NEED_KERNEL_MAKE_CLEAN=false

META_NEXELL_PATH=
META_NEXELL_DISTRO_PATH=

POKY_STYLE_MACHINE_NAME=

#default qt version 5.4.x
#QT_VERSION="5.4.x"
#QT_VERSION="5.6.x"
#QT_VERSION="5.8.x"
#QT_VERSION="5.10.x"
QT_VERSION="5.11.x"

#POKY_VERSION="pyro"
#POKY_VERSION="sumo"
POKY_VERSION="thud"

declare -A META_QT5_SELECT
META_QT5_SELECT["5.4.x"]="fido"
META_QT5_SELECT["5.6.x"]="krogoth"
META_QT5_SELECT["5.8.x"]="pyro"
META_QT5_SELECT["5.10.x"]="sumo"

declare -A KERNEL_IMAGE
KERNEL_IMAGE["s5p4418"]="zImage"
KERNEL_IMAGE["s5p6818"]="Image"

declare -a clean_recipes_s5p4418=("nexell-${IMAGE_TYPE}" "virtual/kernel" "u-boot-nexell" "bl1-s5p4418")
declare -a clean_recipes_s5p6818=("optee-build" "optee-linuxdriver" "nexell-${IMAGE_TYPE}" "virtual/kernel" "u-boot-nexell" "bl1-s5p4418")
declare -a clean_recipes_nxlibs=("libdrm-nx" "nx-drm-allocator" "nx-gst-meta" "nx-renderer" "nx-scaler" "nx-v4l2" "nx-video-api" "nx-vidtex" "nx-gl-tools" "nx-uds" "nx-config")
declare -a clean_recipes_gstlibs=("gst-plugins-camera" "gst-plugins-renderer" "gst-plugins-scaler" "gst-plugins-video-dec" "gst-plugins-video-sink")
declare -a clean_recipes_sdk=("nexell-daudio-sdk" "allgo-connectivity-sdk")

# If you need to add some target board or image type, you have to use below file.
# SUPPORT board target list : meta-nexell/tools/configs/board
# SUPPORT image type   list : meta-nexell/tools/configs/imagetype
targets=()
imagetypes=()

set -e

function update_support_target_list()
{
    configs=$(ls -trh ${META_NEXELL_DISTRO_PATH}/tools/configs/board/)
    for entry in ${configs}
    do
        filename="${entry%.*}"
        targets+=($filename)
    done
}

function update_support_image_list()
{
    configs=$(ls -trh ${META_NEXELL_DISTRO_PATH}/tools/configs/imagetype)
    for entry in ${configs}
    do
        filename="${entry%.*}"
        imagetypes+=($filename)
    done
}


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
        if [ $j == "qt5.4.x" -o $j == "qt5.6.x" ]; then
            existImageTypes=true
            echo -e "\033[47;34m Select imageTypes : ${QT_VERSION} \033[0m"
            break
        elif [ $j == ${IMAGE_TYPE} ]; then
            existImageTypes=true
            echo -e "\033[47;34m Select imageTypes : $j \033[0m"
            break
        fi
    done

    if [ $existTarget == false ]; then
        echo -e "\033[47;34m Please check machine name ==> \"${MACHINE_NAME}\" does not supported board! \033[0m"
        usage
        exit
    fi
    if [ $existImageTypes == false ]; then
        echo -e "\033[47;34m Please check image types ==> \"${IMAGE_TYPE}\" does not supported imagetype! \033[0m"
        usage
        exit
    fi
}
function parse_args()
{
    ARGS=$(getopt -o csht:n:q: -- "$@");
    eval set -- "$ARGS";

    while true; do
            case "$1" in
		-c ) CLEAN_BUILD=true; shift 1 ;;
		-s ) SDK_RELEASE=true; shift 1 ;;
                -q ) QT_VERSION="$2"; shift 2;;
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
    echo -e "        qt, tiny, sato, tinyui, qtX11 \n"
    echo -e " -s : sdk create"
    echo -e " -c : cleanbuild"
    echo -e " -q : QT version, default value is 5.6.x"
    echo -e "      support version : 5.4.x  5.6.x"
    echo -e " -t bl1    : if you want to build only bl1, specify this, default no"
    echo -e " -t uboot : if you want to build only uboot, specify this, default no"
    echo -e " -t kernel : if you want to build only kernel, specify this, default no"
    echo -e " -t optee  : if you want to build only optee, specify this, default no\n"
    echo " ex) $0 s5p6818-avn-ref tiny"
    echo " ex) $0 s5p6818-avn-ref qt -q 5.8.x"
    echo " ex) $0 s5p4418-navi-ref qt -t kernel -t uboot -t bl1"
    echo " ex) $0 s5p4418-navi-ref tiny -c"
    echo " ex) $0 s5p4418-navi-ref tinyui"
    echo " ex) $0 s5p4418-navi-ref sdl"
    echo " ex) $0 s5p4418-navi-ref qt -s"
    echo " ex) $0 s5p4418-daudio-ref qt"
    echo " ex) $0 s5p4418-smart-voice smartvoice -c"
    echo " ex) $0 s5p4418-convergence-svmc qt"
    echo " ex) $0 s5p4418-convergence-daudio qt"
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

    POKY_STYLE_MACHINE_NAME=${BOARD_SOCNAME}_${BOARD_PREFIX}_${BOARD_POSTFIX}
}

function setup_path()
{
    if [ ${SDK_RELEASE} == "false" ]; then
        META_NEXELL_PATH=`readlink -ev ${ROOT_PATH}/yocto/meta-nexell/meta-nexell-distro`
    else
        META_NEXELL_PATH=`readlink -ev ${ROOT_PATH}/yocto/meta-nexell/meta-nexell-sdk`
        RESULT_DIR="SDK-result-${BOARD_SOCNAME}-${IMAGE_TYPE}"
    fi
    META_NEXELL_DISTRO_PATH=`readlink -ev ${ROOT_PATH}/yocto/meta-nexell/meta-nexell-distro`
}

function branch_setup()
{
    cd ${ROOT_PATH}/yocto/meta-qt5
    git clean -f -d;git checkout -f
    git checkout nexell/${META_QT5_SELECT[${QT_VERSION}]}

    if [ "${QT_VERSION}" == "5.7.x" ];then
        git checkout 81fb771c3f31110e50eebcb004809361fdb28194
        patch -p1 < ${TOOLS_PATH}/patches/0001-Qt5Webkit-install-issue-workaround.patch        
    fi

    echo "meta-qt5 branch changed!! to ${QT_VERSION}"

    # poky is sumo and meta-qt5 is fido ==> base_contains does not working.
    if [ "${POKY_VERSION}" == "sumo" ];then
        find . -exec perl -pi -e 's/base_contains/bb\.utils\.contains/g' {} \;
    fi
}

function gen_and_copy_bbappend()
{
    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m                       .bbappend files generate                     \033[0m"
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"

    pushd ${TOOLS_PATH}/bbappend-files
    ./run_bbappend.sh ${ROOT_PATH} "generate"

    cp -a ${TOOLS_PATH}/bbappend-files/recipes-* ${META_NEXELL_DISTRO_PATH}

    echo -e "\033[47;34m ------------------------ Generate Done ! ------------------------- \033[0m"
    popd
}

function kernel_version_sync()
{
    local tempTOP=${PWD}

    pushd ${KERNEL_PATH}
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
    popd

    pushd $tempTOP
    echo "Finally kernel dirname : $KERNEL_DIRNAME"
    KERNEL_FULLPATH=${KERNEL_PATH}/${KERNEL_DIRNAME}
    python ${TOOLS_PATH}/kernel_version_sync.py \
           ${META_NEXELL_DISTRO_PATH}/recipes-kernel/linux/linux-${BOARD_SOCNAME}.bbappend \
           ${META_NEXELL_DISTRO_PATH}/recipes-bsp/optee/optee-build_%.bbappend \
           ${ROOT_PATH} \
           ${KERNEL_DIRNAME}
    popd
}

function bitbake_run()
{
    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m                       Bitbake Auto Running                         \033[0m"
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"

    if ! [ -d ${META_NEXELL_PATH}/../../build ]; then
        mkdir -p ${META_NEXELL_PATH}/../../build
    fi

    #------------------------ Nexell platform setup ------------------------
    pushd ${ROOT_PATH}/yocto

    if [ ${SDK_RELEASE} == "false" ]; then
        source poky/oe-init-build-env build/build-${MACHINE_NAME}-${IMAGE_TYPE}
        BUILD_PATH=`readlink -ev ${META_NEXELL_PATH}/../../build/build-${MACHINE_NAME}-${IMAGE_TYPE}`
        ${META_NEXELL_PATH}/tools/envsetup.sh ${MACHINE_NAME} ${IMAGE_TYPE} ${NUMBER_THREADS} "EXTERNALSRC_USING" ${QT_VERSION}
    else        
        source poky/oe-init-build-env build/SDK-build-${BOARD_SOCNAME}-${IMAGE_TYPE}
        BUILD_PATH=`readlink -ev ${META_NEXELL_PATH}/../../build/SDK-build-${BOARD_SOCNAME}-${IMAGE_TYPE}`
        ${META_NEXELL_PATH}/tools/envsetup-sdk.sh ${MACHINE_NAME} ${IMAGE_TYPE} ${NUMBER_THREADS} "EXTERNALSRC_USING" ${QT_VERSION}
    fi
    #-----------------------------------------------------------------------

    build_status_check

    if [ ${CLEAN_BUILD} == "true" ];then
	NEED_KERNEL_MAKE_CLEAN="true"
    fi

    local BITBAKE_ARGS=()
    local CLEAN_RECIPES=()
    if [ ${BUILD_ALL} == "false" ];then
        if [ ${SDK_RELEASE} == "true" ]; then
            echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
            echo -e "\033[47;34m Strange arguments !!  Please check Usage!!                         \033[0m"
            echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"
            usage
            exit
        fi

        if [ ${BUILD_KERNEL} == "true" ]; then
            if [ ${NEED_KERNEL_MAKE_CLEAN} == "true" ]; then
                echo -e "\033[40;34m Before kernel built different board type, so need to make clean kernel build \033[0m"
                kernel_make_clean
                CLEAN_RECIPES+=("virtual/kernel")
                BITBAKE_ARGS+=("virtual/kernel")
            else
                #check sysroot cross-compiler
                #If exist poky cross-compiler And once a time full build done.
                #Run kernel_partial_build                
                if ! [ -f ${BUILD_PATH}/tmp/work/KBUILD_DEFCONFIG.txt ]; then
                    echo -e "\n\033[40;34m Never build before virtual/kernel build, At least once Yocto Kernel Build has been performed. \033[0m"
                    echo -e "\n\033[40;34m Because you need to know the cross compiler and defconfig information. \033[0m"
                    CLEAN_RECIPES+=("virtual/kernel")
                    BITBAKE_ARGS+=("virtual/kernel")
                else
                    local temp_defconfig
                    local temp_dtb
                    read temp_defconfig < ${BUILD_PATH}/tmp/work/KBUILD_DEFCONFIG.txt
                    read temp_dtb < ${BUILD_PATH}/tmp/work/KBUILD_DEVICETREE.txt
                    kernel_partial_build $temp_defconfig $temp_dtb
                fi
            fi
        fi

        if [ ${BUILD_BL1} == "true" ]; then
            if [ ${BOARD_SOCNAME} == "s5p6818" ]; then
                BITBAKE_ARGS+=("bl1-${BOARD_SOCNAME}")
                CLEAN_RECIPES+=("bl1-${BOARD_SOCNAME}")
            else
                BITBAKE_ARGS+=("bl1-${BOARD_SOCNAME}" "bl2-${BOARD_SOCNAME}" "dispatcher-${BOARD_SOCNAME}")
                CLEAN_RECIPES+=("bl1-${BOARD_SOCNAME}" "bl2-${BOARD_SOCNAME}" "dispatcher-${BOARD_SOCNAME}")
            fi
        fi

        if [ ${BUILD_UBOOT} == "true" ]; then
            BITBAKE_ARGS+=("u-boot-nexell")
            CLEAN_RECIPES+=("u-boot-nexell")
        fi

        if [ ${BOARD_SOCNAME} == 's5p6818' ]; then
            if [ ${BUILD_OPTEE} == "true" ]; then
                BITBAKE_ARGS+=("optee-build")
                CLEAN_RECIPES+=("optee-build" "arm-trusted-firmware" "l-loader" \
                                "optee-os" "optee-client" "u-boot-nexell" "bl1-${BOARD_SOCNAME}")
            fi
        fi

        if [ ${#CLEAN_RECIPES[@]} -gt 0 ]; then
	    echo -e "\033[47;34m CLEAN TARGET : ${CLEAN_RECIPES[@]} \033[0m"
            bitbake -c cleanall ${CLEAN_RECIPES[@]}
        fi

        if [ ${#BITBAKE_ARGS[@]} -gt 0 ]; then
            echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
            echo -e "\033[47;34m                          Partial Build                             \033[0m"
            echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"
            echo -e "\033[47;34m ${BITBAKE_ARGS[@]}                                             \033[0m"
            bitbake ${BITBAKE_ARGS[@]}
        else
            echo -e "\033[47;34m Nothing to bitbake run  \033[0m"
        fi
    else
	echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
        echo -e "\033[47;34m                          All Build                                 \033[0m"
        echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"
        if [ ${CLEAN_BUILD} == "true" ];then
            echo -e "\033[47;34m                      Clean Build True                              \033[0m"
            echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"
            kernel_make_clean
            # make-mod-scripts clean + make mrproper virtual/kernel
            if [ ${BOARD_SOCNAME} == "s5p4418" ];then
                echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_s5p4418[@]} \033[0m"
                echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_nxlibs[@]} \033[0m"
                echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_gstlibs[@]} \033[0m"
                if [ ${IMAGE_TYPE} == "qt" ];then
                    echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_sdk[@]} \033[0m"
                    bitbake -c cleanall ${clean_recipes_s5p4418[@]} ${clean_recipes_nxlibs[@]} ${clean_recipes_gstlibs[@]} ${clean_recipes_sdk[@]}
                else
                    bitbake -c cleanall ${clean_recipes_s5p4418[@]} ${clean_recipes_nxlibs[@]} ${clean_recipes_gstlibs[@]}
                fi
            else
                echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_s5p6818[@]} \033[0m"
                echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_nxlibs[@]} \033[0m"
                echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_gstlibs[@]} \033[0m"
                if [ -d ${BUILD_PATH}/tmp/work-shared/${MACHINE_NAME}/kernel-source ];then
                    bitbake -c cleanall ${clean_recipes_s5p6818[@]} ${clean_recipes_nxlibs[@]} ${clean_recipes_gstlibs[@]}
                fi
            fi
        fi

        # # first kernel build, because optee-linuxdriver build conflict
        # # not working DEPENS feature in recipe file.
        # if [ ${BOARD_SOCNAME} == "s5p6818" ];then
        #     bitbake optee-build virtual/kernel
        # fi

        if [ ${SDK_RELEASE} == "true" ]; then
            echo -e "\033[47;34m bitbake -c populate_sdk nexell-${IMAGE_TYPE}-sdk \033[0m"
            bitbake -c populate_sdk nexell-${IMAGE_TYPE}-sdk
        else
            #------------------------ Nexell platform build ------------------------
            bitbake nexell-${IMAGE_TYPE}
            #-----------------------------------------------------------------------
        fi
    fi
    popd
    build_status_update
}

function kernel_make_clean()
{
    if [ $NEED_KERNEL_MAKE_CLEAN == true ];then
        echo -e "\n ------------------------------------------------------------------ "
        echo -e "                        kernel clean                                "
        echo -e " ------------------------------------------------------------------ "

        pushd ${KERNEL_FULLPATH}

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
        make ARCH=${ARM_ARCH} clean
        rm -rf .kernel-meta oe-logs oe-workdir .metadir .scmversion source

        if [ "${POKY_VERSION}" == "sumo" ];then
            make mrproper
            rm -rf ${BUILD_PATH}/tmp/work/clone_kernel_src
            mkdir -p ${BUILD_PATH}/tmp/work/clone_kernel_src
            cp -a * ${BUILD_PATH}/tmp/work/clone_kernel_src/
        fi
        if [ "${POKY_VERSION}" == "thud" ];then
            make mrproper
            rm -rf ${BUILD_PATH}/tmp/work/clone_kernel_src
            mkdir -p ${BUILD_PATH}/tmp/work/clone_kernel_src
            cp -a * ${BUILD_PATH}/tmp/work/clone_kernel_src/
        fi

        popd
    fi
}

function move_images()
{
    ${META_NEXELL_PATH}/tools/copyFilesToOutDir.sh ${MACHINE_NAME} ${IMAGE_TYPE} ${BUILD_ALL}
    RESULT_PATH=`readlink -ev ${ROOT_PATH}/yocto/out/${RESULT_DIR}`
    if [ ${KERNEL_PARTITAL_BUILD} == "true" ]; then
        pushd ${KERNEL_FULLPATH}
        cp -a arch/${ARM_ARCH}/boot/${KERNEL_IMAGE[${BOARD_SOCNAME}]} ${RESULT_PATH}/
        IFS=' ' read -ra dtbs <<< "$KERNEL_DTBS"
        for i in "${dtbs[@]}"; do
            cp -a arch/${ARM_ARCH}/boot/dts/$i ${RESULT_PATH}/
        done
        IFS=''
        popd
    fi
}

function convert_images()
{
    cd ${RESULT_PATH}
    ${META_NEXELL_PATH}/tools/convert_tools/convert_images.sh ${MACHINE_NAME} ${IMAGE_TYPE}
}

function make_build_info()
{
    ${TOOLS_PATH}/documents/make_build_info.sh ${RESULT_PATH} ${KERNEL_FULLPATH}
}

function make_standalone_tools()
{
    mkdir -p ${RESULT_PATH}/tools

    cp -a ${RESULT_PATH}/bl1-*.bin ${RESULT_PATH}/tools/
    cp -a ${RESULT_PATH}/partmap_emmc.txt ${RESULT_PATH}/tools/

    cp -a ${META_NEXELL_PATH}/tools/fusing_tools/standalone-fastboot-download.sh ${RESULT_PATH}/tools/
    cp -a ${META_NEXELL_PATH}/tools/fusing_tools/standalone-uboot-by-usb-download.sh ${RESULT_PATH}/tools/

    cp -a ${META_NEXELL_PATH}/tools/fusing_tools/usb-downloader ${RESULT_PATH}/tools/

    cp -a ${RESULT_PATH}/partition.txt ${RESULT_PATH}/tools/
}

function make_nexell_server_documnets()
{
    ${TOOLS_PATH}/documents/make_documents.sh ${MACHINE_NAME} ${RESULT_PATH} ${SDK_RELEASE}
}

function build_status_check()
{
    if [ ! -d ${BUILD_PATH}/../build-${BOARD_SOCNAME}-${BOARD_NAME}[${IMAGE_TYPE} ];then
           CLEAN_BUILD=true
    fi

    #matched! before build socname with current build socname
    if [ -e ${BUILD_PATH}/../NEXELL_STATUS-BUILD-${BOARD_SOCNAME} ];then
        #matched! before build boardname with current build boardname
        if [ -e ${BUILD_PATH}/../NEXELL_STATUS-BUILD-${BOARD_NAME} ];then
            echo -e "\033[0;34m ------------------------------------------------------------------ \033[0m"
            echo -e "\033[0;33m #########  Already same machine name built ########## \033[0m"
            echo -e "\033[0;34m ------------------------------------------------------------------ \033[0m"
        else
            echo -e "\033[0;34m ----------------------------------------------------------------------------------- \033[0m"
            echo -e "\033[0;33m #########  Already same soc built, but you tried other board type build ########## \033[0m"
            echo -e "\033[0;33m #########  Need Clean BUILD ########## \033[0m"
            echo -e "\033[0;34m ----------------------------------------------------------------------------------- \033[0m"
            CLEAN_BUILD=true
            rm -rf ${BUILD_PATH}/../NEXELL_STATUS-BUILD-*
        fi
    else
        echo -e "\033[0;34m ------------------------------------------------------------------ \033[0m"
        echo -e "\033[0;33m #########  You tried other machine build ########## \033[0m"
        echo -e "\033[0;33m #########  Need Clean BUILD ########## \033[0m"
        echo -e "\033[0;34m ------------------------------------------------------------------ \033[0m"
        CLEAN_BUILD=true
        rm -rf ${BUILD_PATH}/../NEXELL_STATUS-BUILD-*
    fi    
}

function build_status_update()
{
    #When External Src build, need kernel distclean check
    local kernelBuildStatusChipName="NEXELL_STATUS-BUILD-${BOARD_SOCNAME}"
    local kernelBuildStatusBoardName="NEXELL_STATUS-BUILD-${BOARD_NAME}"
    touch ${BUILD_PATH}/../$kernelBuildStatusChipName
    touch ${BUILD_PATH}/../$kernelBuildStatusBoardName
}

function kernel_partial_build()
{
    declare -A POKY_CROSS_COMPILE_PATH
    declare -A EXTRA_PATH
    declare -A COMPILER

    echo -e "\n\033[47;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[47;34m                      Kernel Partial Build                            \033[0m"
    echo -e "\033[47;34m ------------------------------------------------------------------ \033[0m"

    KERNEL_PARTITAL_BUILD=true

    POKY_CROSS_COMPILE_PATH["s5p4418"]="${BUILD_PATH}/tmp/work/${POKY_STYLE_MACHINE_NAME}-poky-linux-gnueabi/linux-${BOARD_SOCNAME}/*"
    POKY_CROSS_COMPILE_PATH["s5p6818"]="${BUILD_PATH}/tmp/work/${POKY_STYLE_MACHINE_NAME}-poky-linux/linux-${BOARD_SOCNAME}/*"
    EXTRA_PATH["s5p4418"]="recipe-sysroot-native/usr/bin/arm-poky-linux-gnueabi"
    EXTRA_PATH["s5p6818"]="recipe-sysroot-native/usr/bin/aarch64-poky-linux"
    COMPILER["s5p4418"]="arm-poky-linux-gnueabi-"
    COMPILER["s5p6818"]="aarch64-poky-linux-"

    local cross_compiler_path=$(ls -d ${POKY_CROSS_COMPILE_PATH[${BOARD_SOCNAME}]}/${EXTRA_PATH[${BOARD_SOCNAME}]}/)
    local KERNEL_DEFCONFIG=$1
    local KERNEL_DTBS=$2

    pushd ${KERNEL_FULLPATH}
    make clean
    make ARCH=${ARM_ARCH} CROSS_COMPILE=$cross_compiler_path/${COMPILER[${BOARD_SOCNAME}]} ${KERNEL_DEFCONFIG} -j8
    make ARCH=${ARM_ARCH} CROSS_COMPILE=$cross_compiler_path/${COMPILER[${BOARD_SOCNAME}]} ${KERNEL_IMAGE[${BOARD_SOCNAME}]} -j8
    make ARCH=${ARM_ARCH} CROSS_COMPILE=$cross_compiler_path/${COMPILER[${BOARD_SOCNAME}]} dtbs
    make ARCH=${ARM_ARCH} CROSS_COMPILE=$cross_compiler_path/${COMPILER[${BOARD_SOCNAME}]} modules -j8
    #make ARCH=${ARM_ARCH} CROSS_COMPILE=$cross_compiler_path/${COMPILER[${BOARD_SOCNAME}]} modules_install INSTALL_MOD_PATH=${D} INSTALL_MOD_STRIP=1
    popd
}

parse_args $@
split_machine_name
setup_path
#branch_setup
update_support_target_list
update_support_image_list
check_usage

gen_and_copy_bbappend
kernel_version_sync

bitbake_run
move_images

if [ ${SDK_RELEASE} == "false" ]; then
    convert_images
    make_build_info
    make_standalone_tools
fi

make_nexell_server_documnets
