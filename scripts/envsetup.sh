#!/bin/bash
# set -e

################################################################################
# Get arguments from terminal
# If you doesn't input any argumensts, this script will provide options menu
# to set MACHINE_NAME & IMAGE_TYPE
################################################################################
# <MACHINE-NAME> : nxp3220-daudio2, s5p4418-navi-ref, s5p6818-avn-ref, s5p4418-daudio-covi, s5p4418-smart-voice ...
MACHINE_NAME=$1

# <IMAGE-TYPE> : nexell-image-qt, qt ...
IMAGE_TYPE=$2

#-------------------------------------------------------------------------------
# Set default ptah
#-------------------------------------------------------------------------------
BSP_ROOT_DIR=`readlink -e -n "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
BSP_YOCTO_DIR=$BSP_ROOT_DIR/layers
META_NEXELL_PATH=$BSP_YOCTO_DIR/meta-nexell/meta-nexell-distro
BSP_VENDOR_DIR=$BSP_ROOT_DIR/vendor/nexell
BSP_CONFIGS_PATH=$META_NEXELL_PATH/settings

source ${BSP_ROOT_DIR}/tools/scripts/common_functions.sh

################################################################################
# Parsing arguments
################################################################################
parse_args $BSP_CONFIGS_PATH $META_NEXELL_PATH $@

if [ $? -eq 1 ]; then
cd "$BSP_ROOT_DIR"
return
fi

################################################################################
# Set MACHINE_NAME & IMAGE_TYPE
################################################################################
#-------------------------------------------------------------------------------
# Set target machine name
#-------------------------------------------------------------------------------
# If you doesn't input any machine name, this function will provide options menu
# to set MACHINE_NAME
#-------------------------------------------------------------------------------
set_target_machine $BSP_CONFIGS_PATH TARGET_MACHINE_NAME $MACHINE_NAME

MACHINE_NAME=$TARGET_MACHINE_NAME

#-------------------------------------------------------------------------------
# Extract target information from MACHINE_NAME
#-------------------------------------------------------------------------------
# <SOC-NAME> : nxp3220, s5p4418, s5p6818
BOARD_SOCNAME=${MACHINE_NAME%%-*}
# <BOARD-NAME> : daudio2, navi-ref, avn-ref, ...
BOARD_NAME=${MACHINE_NAME#*-}
# <BOARD-PREFIX-NAME> : navi, avn, convergence ...
BOARD_PREFIX=${BOARD_NAME%-*}
# <BOARD-POSTFIX-NAME> : covi, voice ...
BOARD_POSTFIX=${BOARD_NAME#*-}

#-------------------------------------------------------------------------------
# Set target image type
#-------------------------------------------------------------------------------
# If you doesn't input any image type, this function will provide options menu
# to set IMAGE_TYPE
#-------------------------------------------------------------------------------
if [ "${BOARD_SOCNAME}" == "nxp3220" ]; then
YOCTO_IMAGE_ROOTFS=$META_NEXELL_PATH/recipes-core/images/$BOARD_SOCNAME
else
YOCTO_IMAGE_ROOTFS=$META_NEXELL_PATH/recipes-core/images/
fi

set_target_image $YOCTO_IMAGE_ROOTFS TARGET_IMAGE_NAME $IMAGE_TYPE

if [ "nxp3220" != "$BOARD_SOCNAME" ]; then
IMAGE_TYPE=${TARGET_IMAGE_NAME#*-}
else
IMAGE_TYPE=$TARGET_IMAGE_NAME
fi

################################################################################
# oe-init-build-env
################################################################################
print_build_header "Environment setup : oe-init-build-env"
#-------------------------------------------------------------------------------
# Set PATH
#-------------------------------------------------------------------------------
cd $BSP_ROOT_DIR
IMAGE_TYPE_POSTFIX=${IMAGE_TYPE##*-}

YOCTO_BUILD_DIR=$BSP_ROOT_DIR/build/build-${MACHINE_NAME}-${IMAGE_TYPE_POSTFIX}
BSP_OUTPUT_DIR=$BSP_ROOT_DIR/out/result-${MACHINE_NAME}-${IMAGE_TYPE_POSTFIX}

BUILD_MACHINE_NAME="$(echo "$MACHINE_NAME" | cut -d'-' -f 1)"
BUILD_LOCAL_CONF="$YOCTO_BUILD_DIR/conf/local.conf"
BUILD_LAYER_CONF="$YOCTO_BUILD_DIR/conf/bblayers.conf"

if [ "${BOARD_SOCNAME}" == "s5p4418" ] || [ "${BOARD_SOCNAME}" == "s5p6818" ]; then
	BSP_TOOLS_DIR=$BSP_ROOT_DIR/tools/s5pxx18
else
	BSP_TOOLS_DIR=$BSP_ROOT_DIR/tools/$BOARD_SOCNAME
fi

BSP_FILES_DIR=$BSP_TOOLS_DIR/files

TARGET_IMGAE_CONFIG_PATH=$BSP_CONFIGS_PATH/$BOARD_SOCNAME/images
TARGET_MACHINE_CONFIG_PATH=$BSP_CONFIGS_PATH/$BOARD_SOCNAME/machines

#-------------------------------------------------------------------------------
# make output directory
#-------------------------------------------------------------------------------
mkdir -p $YOCTO_BUILD_DIR
mkdir -p $BSP_OUTPUT_DIR

#-------------------------------------------------------------------------------
# run oe-init-build-env
#-------------------------------------------------------------------------------
source layers/poky/oe-init-build-env $YOCTO_BUILD_DIR

#-------------------------------------------------------------------------------
# Make local.conf & bblayer.conf
#-------------------------------------------------------------------------------
declare -A BUILD_LOCAL_CONF_CONFIGURE=(
	["BSP_ROOT_DIR"]="$BSP_ROOT_DIR"
	["BSP_FILES_DIR"]="$BSP_FILES_DIR"
	["BSP_TOOLS_DIR"]="$BSP_TOOLS_DIR"
	["BSP_VENDOR_DIR"]="$BSP_VENDOR_DIR"
	["BSP_OUTPUT_DIR"]="$BSP_OUTPUT_DIR"
	["BSP_TARGET_MACHINE"]="$MACHINE_NAME"
	["BSP_TARGET_SOCNAME"]="$BOARD_SOCNAME"
	["BSP_TARGET_BOARD_NAME"]="$BOARD_NAME"
	["BSP_TARGET_BOARD_PREFIX"]="$BOARD_PREFIX"
	["BSP_TARGET_BOARD_POSTFIX"]="$BOARD_POSTFIX"
	["BSP_TARGET_IMAGE_TYPE"]="$IMAGE_TYPE"
	["INITRAMFS_IMAGE"]="$IMAGE_TYPE"
)

# Parse machine configuration
# The local.conf and $MACHINE_NAME.conf files will be parse and then merge into $BUILD_LOCAL_CONF.
parse_conf_machine $BUILD_MACHINE_NAME \
		$BUILD_LOCAL_CONF \
		"$TARGET_MACHINE_CONFIG_PATH/local.conf" \
		"$TARGET_MACHINE_CONFIG_PATH/$MACHINE_NAME.conf" \
		BUILD_LOCAL_CONF_CONFIGURE

# Parse image
# The conf files will be parse and then merge into $BUILD_LOCAL_CONF.
target_image_array=( $TARGET_IMGAE_CONFIG_PATH/${IMAGE_TYPE##*-}.conf )
parse_conf_image $BUILD_LOCAL_CONF \
		"${target_image_array[@]}"

# Parse bblayer
# The bblayers.conf files will be parse and then merge into $BUILD_LAYER_CONF.
parse_conf_bblayer $BSP_YOCTO_DIR \
		"$TARGET_MACHINE_CONFIG_PATH/bblayers.conf" \
		$BUILD_LAYER_CONF


#-------------------------------------------------------------------------------
# Make local.conf & bblayer.conf
#-------------------------------------------------------------------------------
declare -a clean_recipes_s5p4418=("nexell-${IMAGE_TYPE_POSTFIX}" "virtual/kernel" "u-boot-nexell" "bl1-s5p4418")
declare -a clean_recipes_s5p6818=("optee-build" "optee-linuxdriver" "nexell-${IMAGE_TYPE_POSTFIX}" "virtual/kernel" "u-boot-nexell" "bl1-s5p4418")
declare -a clean_recipes_nxlibs_1=("libdrm-nx" "nx-drm-allocator" "nx-gst-meta" "nx-renderer" "nx-scaler" "nx-v4l2" "nx-video-api" "nx-vidtex" "nx-gl-tools" "nx-uds" "nx-config")
declare -a clean_recipes_nxlibs_2=("libdrm-nx" "nx-drm-allocator" "nx-gst-meta" "nx-renderer" "nx-scaler" "nx-v4l2" "nx-video-api" "nx-vidtex" "nx-uds" "nx-config")
declare -a clean_recipes_gstlibs=("gst-plugins-camera" "gst-plugins-renderer" "gst-plugins-scaler" "gst-plugins-video-dec" "gst-plugins-video-sink")
declare -a clean_recipes_sdk=("nexell-daudio-sdk" "allgo-connectivity-sdk")


#-------------------------------------------------------------------------------
# Set core architecture
#-------------------------------------------------------------------------------
if [ "${BOARD_SOCNAME}" == "s5p4418" ];then
	ARM_ARCH="arm"
fi

if [ "${BOARD_SOCNAME}" == "s5p6818" ];then
	ARM_ARCH="arm64"
fi

copy_build_scripts "$YOCTO_BUILD_DIR"

#-------------------------------------------------------------------------------
# Print a simple usage for build target to termianl.
#-------------------------------------------------------------------------------
msg_with_color $YELLOW "You can now run 'bitbake <image_type>' to build full image \t"
msg_with_color $YELLOW "Your image_types are: \t"
msg_with_color $BRIGHT_YELLOW "$TARGET_IMAGE_NAME\n"
msg_verbose "If you need more information about bitbake,"
msg_verbose "Please refer to the official documentation of bitbake as below :"
msg_verbose "URL : https://docs.yoctoproject.org/bitbake \n"

#-------------------------------------------------------------------------------
# Export some configuration to use in the copy-results-images.sh
#-------------------------------------------------------------------------------
export BSP_ROOT_DIR BSP_TOOLS_DIR BSP_FILES_DIR BSP_OUTPUT_DIR MACHINE_NAME IMAGE_TYPE

