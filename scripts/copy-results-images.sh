#!/bin/bash

function msg () { echo -e "\033[0;33m$*\033[0m"; }
function err () { echo -e "\033[0;31m$*\033[0m"; }
function green () { echo -e "\033[47;32m$*\033[0m"; }
function blue () { echo -e "\033[47;34m$*\033[0m"; }
function magenta () { echo -e "\033[47;35m$*\033[0m"; }
function cyan () { echo -e "\033[47;36m$*\033[0m"; }
function white () { echo -e "\033[0;37m$*\033[0m"; }

if [ -z "${BSP_ROOT_DIR}" ] || [ -z "${BSP_TOOLS_DIR}" ] \
	|| [ -z "${BSP_FILES_DIR}" ] || [ -z "${BSP_OUTPUT_DIR}" ] \
	|| [ -z "${MACHINE_NAME}" ] || [ -z "${IMAGE_TYPE}" ] ; then

	err "The build environment setup has not been completed.\nPlease run 'source envsetup.sh' and then run this script again."
	return;
fi

BOARD_SOCNAME=${MACHINE_NAME%%-*}
IMAGE_TYPE_POSTFIX=${IMAGE_TYPE##*-}
YOCTO_BUILD_DIR=$BSP_ROOT_DIR/build/build-${MACHINE_NAME}-${IMAGE_TYPE_POSTFIX}

blue "BSP_ROOT_DIR = ${BSP_ROOT_DIR}"
blue "BSP_OUTPUT_DIR = ${BSP_OUTPUT_DIR}"

# Copy from deploy to result dir
BSP_RESULT_FILES=(
	"bl1-nxp3220.bin.raw"
	"bl1-nxp3220.bin.enc.raw"
	"bl1-nxp3220.bin.raw.ecc"
	"bl1-nxp3220.bin.enc.raw.ecc"
	"bl2.bin.raw"
	"bl2-evb.bin.raw"
	"bl2.bin.raw.ecc"
	"bl32.bin.raw"
	"bl32.bin.enc.raw"
	"bl32.bin.raw.ecc"
	"bl32.bin.enc.raw.ecc"
	"u-boot-BUILD_MACHINE_NAME-1.0-r0.bin"
	"u-boot.bin"
	"u-boot.bin.raw"
	"u-boot.bin.raw.ecc"
	"params_env.*"
	"boot.img"
	"rootfs.img"
	"userdata.img"
	"misc.img"
	"swu_image.sh"
	"swu_hash.py"
	"*sw-description*"
	"*.sh"
	"swu.private.key"
	"swu.public.key"
	"*.swu"
	"secure-bootkey.pem.pub.hash.txt"
)

# Copy from tools to result dir
BSP_RESULT_TOOLS=(
	"$BSP_TOOLS_DIR/scripts/partmap_fastboot.sh"
	"$BSP_TOOLS_DIR/scripts/partmap_diskimg.sh"
	"$BSP_TOOLS_DIR/scripts/usb-down.sh"
	"$BSP_TOOLS_DIR/scripts/configs/udown.bootloader.sh"
	"$BSP_TOOLS_DIR/scripts/configs/udown.bootloader-secure.sh"
	"$BSP_TOOLS_DIR/bin/linux-usbdownloader"
	"$BSP_TOOLS_DIR/bin/simg2dev"
	"$BSP_FILES_DIR/partmap/partmap_*.txt"
	"$BSP_FILES_DIR/secure/secure-bl1-enckey.txt"
	"$BSP_FILES_DIR/secure/secure-bl32-enckey.txt"
	"$BSP_FILES_DIR/secure/secure-bl32-ivector.txt"
	"$BSP_FILES_DIR/secure/secure-jtag-hash.txt"
	"$BSP_FILES_DIR/secure/secure-bootkey.pem.pub.hash.txt"
	"$BSP_FILES_DIR/secure/efuse_cfg-aes_enb.txt"
	"$BSP_FILES_DIR/secure/efuse_cfg-verify_enb-hash0.txt"
	"$BSP_FILES_DIR/secure/efuse_cfg-sjtag_enb.txt"
)

function copy_result_image () {
	local deploy
	BUILD_MACHINE_NAME=${MACHINE_NAME%%-*}
	deploy=$YOCTO_BUILD_DIR/tmp/deploy/images/$BUILD_MACHINE_NAME
	green "MACHINE_NAME = $MACHINE_NAME"
	green "BUILD_MACHINE_NAME = $BUILD_MACHINE_NAME"
	green "deploy = $deploy"
	if [[ ! -d $deploy ]]; then
		err " No such directory : $deploy"
		return 1
	fi

	if ! mkdir -p "$BSP_OUTPUT_DIR"; then return 1; fi
	if ! cd "$deploy"; then return 1; fi

	for file in "${BSP_RESULT_FILES[@]}"; do
		[[ $file == *BUILD_MACHINE_NAME* ]] && \
			file=$(echo "$file" | sed "s/BUILD_MACHINE_NAME/$BUILD_MACHINE_NAME/")

		local files
		files=$(find $file -print \
			2> >(grep -v 'No such file or directory' >&2) | sort)

		for n in $files; do
			[[ ! -e $n ]] && continue;

			to="$BSP_OUTPUT_DIR/$n"
			if [[ -d $n ]]; then
				mkdir -p "$to"
				continue
			fi

			if [[ -f $to ]]; then
				ts="$(stat --printf=%y "$n" | cut -d. -f1)"
				td="$(stat --printf=%y "$to" | cut -d. -f1)"
				[[ $ts == "$td" ]] && continue;
			fi

			cp -a "$n" "$to"
		done
	done
}

function copy_result_tools () {
	if ! mkdir -p "$BSP_OUTPUT_DIR"; then return 1; fi
	if ! cd "$BSP_ROOT_DIR"; then return 1; fi

	for file in "${BSP_RESULT_TOOLS[@]}"; do
		local files

		files=$(find $file -print \
			2> >(grep -v 'No such file or directory' >&2) | sort)

		for n in $files; do
			if [[ -d $n ]]; then
				continue
			fi

			to="$BSP_OUTPUT_DIR/$(basename "$n")"
			if [[ -f $to ]]; then
				ts="$(stat --printf=%y "$n" | cut -d. -f1)"
				td="$(stat --printf=%y "$to" | cut -d. -f1)"
				[[ ${ts} == "${td}" ]] && continue;
			fi
			cp -a "$n" "$to"
		done
	done
}

if [ "${BOARD_SOCNAME}" == "nxp3220" ];then
    copy_result_image

	if [ $? -eq 1 ]; then
		err "Could not find the resulting images.\nPlease rebuild your target image."
		return
	fi
    copy_result_tools

	if [ $? -eq 1 ]; then
		err "Could not find the path of BSP.\nPlease check your build environment."
		return
	fi
else
	cyan "BSP_TOOLS_DIR=$BSP_TOOLS_DIR"
    # # result copy
    ${BSP_TOOLS_DIR}/scripts/copyFilesToOutDir.sh ${BSP_ROOT_DIR} ${BSP_TOOLS_DIR} ${BSP_FILES_DIR} ${MACHINE_NAME} ${IMAGE_TYPE} true

    # # make rootfs.img
    # pushd ${BSP_OUTPUT_DIR}
    # ${BSP_TOOLS_DIR}/convert_tools/convert_images.sh ${MACHINE_NAME} ${IMAGE_TYPE}

    # # flashing tool copy
    # mkdir -p ${BSP_OUTPUT_DIR}/tools
    # cp -af ${BSP_OUTPUT_DIR}/bl1-*.bin ${BSP_OUTPUT_DIR}/tools/
    # cp -af ${BSP_OUTPUT_DIR}/partmap_emmc.txt ${BSP_OUTPUT_DIR}/tools/
    # cp -af ${BSP_TOOLS_DIR}/fusing_tools/standalone-fastboot-download.sh ${BSP_OUTPUT_DIR}/tools/
    # cp -af ${BSP_TOOLS_DIR}/fusing_tools/standalone-uboot-by-usb-download.sh ${BSP_OUTPUT_DIR}/tools/
    # cp -af ${BSP_TOOLS_DIR}/fusing_tools/usb-downloader ${BSP_OUTPUT_DIR}/tools/
    # cp -af ${BSP_OUTPUT_DIR}/partition.txt ${BSP_OUTPUT_DIR}/tools/
	# popd
fi







