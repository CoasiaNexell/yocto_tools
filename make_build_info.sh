#!/bin/bash

set -e

CURRENT_PATH=`dirname $0`
TOOLS_PATH=`readlink -ev $CURRENT_PATH`
ROOT_PATH=`readlink -ev ${TOOLS_PATH}/..`

RESULT_PATH=$1
KERNEL_PATH=$2

NEXELL_SOURCE_PATH_BL1_S5P4418=${ROOT_PATH}/bl1/bl1-s5p4418
NEXELL_SOURCE_PATH_BL1_S5P6818=${ROOT_PATH}/bl1/bl1-s5p6818
NEXELL_SOURCE_PATH_ATF=${ROOT_PATH}/secure/arm-trusted-firmware
NEXELL_SOURCE_PATH_LLOADER=${ROOT_PATH}/secure/l-loader
NEXELL_SOURCE_PATH_OPTEE_BUILD=${ROOT_PATH}/secure/optee/optee_build
NEXELL_SOURCE_PATH_OPTEE_CLIENT=${ROOT_PATH}/secure/optee/optee_client
NEXELL_SOURCE_PATH_OPTEE_LINUXDRIVER=${ROOT_PATH}/secure/optee/optee_linuxdriver
NEXELL_SOURCE_PATH_OPTEE_OS=${ROOT_PATH}/secure/optee/optee_os
NEXELL_SOURCE_PATH_OPTEE_TEST=${ROOT_PATH}/secure/optee/optee_test
NEXELL_SOURCE_PATH_UBOOT=${ROOT_PATH}/u-boot/u-boot-2016.01

NEXELL_SOURCE_PATH_GST_PLUGIN_CAMERA=${ROOT_PATH}/library/gst-plugins-camera
NEXELL_SOURCE_PATH_GST_PLUGIN_RENDERER=${ROOT_PATH}/library/gst-plugins-renderer
NEXELL_SOURCE_PATH_GST_PLUGIN_SCALER=${ROOT_PATH}/library/gst-plugins-scaler

NEXELL_SOURCE_PATH_LIB_LIBDRM=${ROOT_PATH}/library/libdrm
NEXELL_SOURCE_PATH_LIB_NX_DRM_ALLOCATOR=${ROOT_PATH}/library/nx-drm-allocator
NEXELL_SOURCE_PATH_LIB_NX_GST_META=${ROOT_PATH}/library/nx-gst-meta
NEXELL_SOURCE_PATH_LIB_NX_RENDERER=${ROOT_PATH}/library/nx-renderer
NEXELL_SOURCE_PATH_LIB_NX_SCALER=${ROOT_PATH}/library/nx-scaler
NEXELL_SOURCE_PATH_LIB_NX_V4L2=${ROOT_PATH}/library/nx-v4l2
NEXELL_SOURCE_PATH_LIB_NV_VIDEO_API=${ROOT_PATH}/library/nx-video-api

NEXELL_SOURCE_PATH_KERNEL=${KERNEL_PATH}
NEXELL_SOURCE_PATH_TESTSUITE=${ROOT_PATH}/apps/testsuite

NEXELL_SOURCE_PATH_NX_AUDIO_PLAYER=${ROOT_PATH}/apps/QT/NxAudioPlayer
NEXELL_SOURCE_PATH_NX_QUICK_REARCAM=${ROOT_PATH}/apps/QT/NxQuickRearCam
NEXELL_SOURCE_PATH_NX_VIDEO_PLAYER=${ROOT_PATH}/apps/QT/NxVideoPlayer

declare -a nexell_source_paths=($NEXELL_SOURCE_PATH_BL1_S5P4418 $NEXELL_SOURCE_PATH_BL1_S5P6818
                                $NEXELL_SOURCE_PATH_UBOOT       $NEXELL_SOURCE_PATH_KERNEL

                                $NEXELL_SOURCE_PATH_ATF         $NEXELL_SOURCE_PATH_LLOADER
                                $NEXELL_SOURCE_PATH_OPTEE_BUILD $NEXELL_SOURCE_PATH_OPTEE_CLIENT
                                $NEXELL_SOURCE_PATH_OPTEE_LINUXDRIVER
                                $NEXELL_SOURCE_PATH_OPTEE_OS    $NEXELL_SOURCE_PATH_OPTEE_TEST

                                $NEXELL_SOURCE_PATH_GST_PLUGIN_CAMERA $NEXELL_SOURCE_PATH_GST_PLUGIN_RENDERER
                                $NEXELL_SOURCE_PATH_GST_PLUGIN_SCALER

                                $NEXELL_SOURCE_PATH_LIB_LIBDRM        $NEXELL_SOURCE_PATH_LIB_NX_DRM_ALLOCATOR
                                $NEXELL_SOURCE_PATH_LIB_NX_GST_META   $NEXELL_SOURCE_PATH_LIB_NX_RENDERER
                                $NEXELL_SOURCE_PATH_LIB_NX_SCALER     $NEXELL_SOURCE_PATH_LIB_NX_V4L2
                                $NEXELL_SOURCE_PATH_LIB_NV_VIDEO_API

                                $NEXELL_SOURCE_PATH_TESTSUITE

                                $NEXELL_SOURCE_PATH_NX_AUDIO_PLAYER $NEXELL_SOURCE_PATH_NX_QUICK_REARCAM
                                $NEXELL_SOURCE_PATH_NX_VIDEO_PLAYER)

function make_build_info()
{
    local curpath=`pwd`
    cp -a ${TOOLS_PATH}/YOCTO-BUILD-INFO.txt ${RESULT_PATH}

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
