#!/bin/bash

function msg () { echo -e "\033[0;33m$*\033[0m"; }
function err () { echo -e "\033[0;31m$*\033[0m"; }
function green () { echo -e "\033[47;32m$*\033[0m"; }
function blue () { echo -e "\033[47;34m$*\033[0m"; }
function magenta () { echo -e "\033[47;35m$*\033[0m"; }
function cyan () { echo -e "\033[47;36m$*\033[0m"; }
function white () { echo -e "\033[0;37m$*\033[0m"; }

blue "BSP_ROOT_DIR = ${BSP_ROOT_DIR}"
blue "YOCTO_RESULT_OUT = ${YOCTO_RESULT_OUT}"

# Copy from deploy to result dir
BSP_RESULT_FILES=(
	"bl1-nxp3220.bin.raw"
	"bl1-nxp3220.bin.enc.raw"
	"bl1-nxp3220.bin.raw.ecc"
	"bl1-nxp3220.bin.enc.raw.ecc"
	"bl2.bin.raw"
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
	"boot/"
	"boot.img"
	"rootfs.img"
	"userdata.img"
	"misc/"
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
	"nxp3220_tools/scripts/partmap_fastboot.sh"
	"nxp3220_tools/scripts/partmap_diskimg.sh"
	"nxp3220_tools/scripts/usb-down.sh"
	"nxp3220_tools/scripts/configs/udown.bootloader.sh"
	"nxp3220_tools/scripts/configs/udown.bootloader-secure.sh"
	"nxp3220_tools/bin/linux-usbdownloader"
	"nxp3220_tools/bin/simg2dev"
	"nxp3220_tools/files/partmap_*.txt"
	"nxp3220_tools/files/secure-bl1-enckey.txt"
	"nxp3220_tools/files/secure-bl32-enckey.txt"
	"nxp3220_tools/files/secure-bl32-ivector.txt"
	"nxp3220_tools/files/secure-bootkey.pem"
	"nxp3220_tools/files/secure-userkey.pem"
	"nxp3220_tools/files/secure-jtag-hash.txt"
	"nxp3220_tools/files/secure-bootkey.pem.pub.hash.txt"
	"nxp3220_tools/files/efuse_cfg-aes_enb.txt"
	"nxp3220_tools/files/efuse_cfg-verify_enb-hash0.txt"
	"nxp3220_tools/files/efuse_cfg-sjtag_enb.txt"
)

function copy_result_image () {
	local deploy
	BUILD_MACHINE_NAME=${MACHINE_NAME%%-*}
	deploy=$YOCTO_BUILD_OUT/tmp/deploy/images/$BUILD_MACHINE_NAME
	green "MACHINE_NAME = $MACHINE_NAME"
	green "BUILD_MACHINE_NAME = $BUILD_MACHINE_NAME"
	green "deploy = $deploy"
	if [[ ! -d $deploy ]]; then
		err " No such directory : $deploy"
		exit 1
	fi

	if ! mkdir -p "$YOCTO_RESULT_OUT"; then exit 1; fi
	if ! cd "$deploy"; then exit 1; fi

	for file in "${BSP_RESULT_FILES[@]}"; do
		[[ $file == *BUILD_MACHINE_NAME* ]] && \
			file=$(echo "$file" | sed "s/BUILD_MACHINE_NAME/$BUILD_MACHINE_NAME/")

		local files
		files=$(find $file -print \
			2> >(grep -v 'No such file or directory' >&2) | sort)

		for n in $files; do
			[[ ! -e $n ]] && continue;

			to="$YOCTO_RESULT_OUT/$n"
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
	if ! mkdir -p "$YOCTO_RESULT_OUT"; then exit 1; fi
	if ! cd "$BSP_ROOT_DIR"; then exit 1; fi

	for file in "${BSP_RESULT_TOOLS[@]}"; do
		local files

		files=$(find $file -print \
			2> >(grep -v 'No such file or directory' >&2) | sort)

		for n in $files; do
			if [[ -d $n ]]; then
				continue
			fi

			to="$YOCTO_RESULT_OUT/$(basename "$n")"
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
    copy_result_tools
else
    # result copy
    ${META_NEXELL_PATH}/tools/copyFilesToOutDir.sh ${MACHINE_NAME} ${IMAGE_TYPE} true

    # make rootfs.img
    pushd ${YOCTO_RESULT_OUT}
    ${META_NEXELL_PATH}/tools/convert_tools/convert_images.sh ${MACHINE_NAME} ${IMAGE_TYPE}

    # flashing tool copy
    mkdir -p ${YOCTO_RESULT_OUT}/tools
    cp -af ${YOCTO_RESULT_OUT}/bl1-*.bin ${YOCTO_RESULT_OUT}/tools/
    cp -af ${YOCTO_RESULT_OUT}/partmap_emmc.txt ${YOCTO_RESULT_OUT}/tools/
    cp -af ${BSP_YOCTO_DIR}/meta-nexell/meta-nexell-distro/tools/fusing_tools/standalone-fastboot-download.sh ${YOCTO_RESULT_OUT}/tools/
    cp -af ${BSP_YOCTO_DIR}/meta-nexell/meta-nexell-distro/tools/fusing_tools/standalone-uboot-by-usb-download.sh ${YOCTO_RESULT_OUT}/tools/
    cp -af ${BSP_YOCTO_DIR}/meta-nexell/meta-nexell-distro/tools/fusing_tools/usb-downloader ${YOCTO_RESULT_OUT}/tools/
    cp -af ${YOCTO_RESULT_OUT}/partition.txt ${YOCTO_RESULT_OUT}/tools/
	popd
fi







