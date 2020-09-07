#!/bin/bash
# set -e

# nxp3220-daudio2, s5p4418-navi-ref, s5p6818-avn-ref, s5p4418-daudio-covi, s5p4418-smart-voice ...
MACHINE_NAME=$1

# nexell-image-qt, qt ...
IMAGE_TYPE=$2

# s5p4418, s5p6818 ...
BOARD_SOCNAME=${MACHINE_NAME%%-*}
# daudio2, navi-ref, avn-ref , ...
BOARD_NAME=${MACHINE_NAME#*-}
# navi, avn, convergence ...
BOARD_PREFIX=${BOARD_NAME%-*}
# covi, voice ...
BOARD_POSTFIX=${BOARD_NAME#*-}

POKY_VERSION="sumo"

# Top path
BSP_ROOT_DIR=`readlink -e -n "$(cd "$(dirname "$0")" && pwd)"`
BSP_YOCTO_DIR=$BSP_ROOT_DIR/layers
META_NEXELL_PATH=$BSP_YOCTO_DIR/meta-nexell/meta-nexell-distro
YOCTO_BUILD_OUT=$BSP_ROOT_DIR/build/build-${MACHINE_NAME}-${IMAGE_TYPE}
YOCTO_RESULT_OUT=$BSP_ROOT_DIR/out/result-${MACHINE_NAME}-${IMAGE_TYPE}
BSP_VENDOR_DIR=$BSP_ROOT_DIR/vendor/nexell
YOCTO_MACHINE_CONFIGS=$META_NEXELL_PATH/configs/$BOARD_SOCNAME/machines
YOCTO_FEATURE_CONFIGS=$META_NEXELL_PATH/configs/$BOARD_SOCNAME/images

if [ "${BOARD_SOCNAME}" == "nxp3220" ]; then
	BUILD_MACHINE_NAME="$(echo "$MACHINE_NAME" | cut -d'-' -f 1)"
	BSP_TOOLS_DIR=$BSP_ROOT_DIR/nxp3220_tools
	YOCTO_IMAGE_ROOTFS=$META_NEXELL_PATH/recipes-core/images/$BOARD_SOCNAME
	MACHINE_SUPPORT=( "nxp3220" )
else
	BUILD_MACHINE_NAME=$MACHINE_NAME
	BSP_TOOLS_DIR=$BSP_ROOT_DIR/tools
	YOCTO_IMAGE_ROOTFS=$META_NEXELL_PATH/recipes-core/images
	if [ "${BOARD_SOCNAME}" == "s5p4418" ]; then
		MACHINE_SUPPORT=( "s5p4418" )
	else
		MACHINE_SUPPORT=( "s5p6818" )
	fi
fi

BUILD_LOCAL_CONF="$YOCTO_BUILD_OUT/conf/local.conf"
BUILD_LAYER_CONF="$YOCTO_BUILD_OUT/conf/bblayers.conf"
BITBAKE_IMAGE_TYPE=()
function msg () { echo -e "\033[0;33m$*\033[0m"; }
function err () { echo -e "\033[0;31m$*\033[0m"; }
function green () { echo -e "\033[47;32m$*\033[0m"; }
function blue () { echo -e "\033[47;34m$*\033[0m"; }
function magenta () { echo -e "\033[47;35m$*\033[0m"; }
function cyan () { echo -e "\033[47;36m$*\033[0m"; }
function white () { echo -e "\033[0;37m$*\033[0m"; }

function parse_avail_target () {
	local dir=$1 deli=$2 table=$3
	local val value bb tmp
	[[ $4 ]] && declare -n avail=$4;

	if ! cd "$dir"; then return 1; fi

	value=$(find ./ -maxdepth 1 -print \
		2> >(grep -v 'No such file or directory' >&2) | \
		grep -w ".*\.${deli}" | sort)

	for i in $value; do
		i="$(echo "$i" | cut -d'/' -f2)"
		if [[ -n $(echo "$i" | awk -F".${deli}" '{print $2}') ]]; then
			continue
		fi

		if [[ $i == *local.conf* ]] || [[ $i == *bblayers.conf* ]]; then
			continue
		fi

		local match=false
		if [[ ${#avail[@]} -ne 0 ]]; then
			for n in "${avail[@]}"; do
				if [[ $i == *$n* ]]; then
					match=true
					break;
				fi
			done
		else
			match=true
		fi

		[[ $match != true ]] && continue;

		tmp="${tmp} $(echo "$i" | awk -F".${deli}" '{print $1}')"
		eval "BITBAKE_IMAGE_TYPE=(\"${tmp}\")"

		if [ "${BOARD_SOCNAME}" != "nxp3220" ]; then
			if [ ${deli} == "bb" ]; then
				bb=${i#*-}
				val="${val} $(echo "$bb" | awk -F".${deli}" '{print $1}')"
				eval "$table=(\"${val}\")"
			else
				val="${val} $(echo "$i" | awk -F".${deli}" '{print $1}')"
				eval "$table=(\"${val}\")"
			fi
		else
			val="${val} $(echo "$i" | awk -F".${deli}" '{print $1}')"
			eval "$table=(\"${val}\")"
		fi

	done
}

function check_avail_target () {
	local name=$1 table=$2

	if [ -z $name ]; then
		return
	fi

	for i in ${table}; do
		for n in ${name}; do
			[ $i == "$n" ] && return;
		done
	done

	err ""
	err " Not support $name"
	err " Availiable: $table"
	err ""

	# show_info
	# exit 1;
	return 1;
}

if [ "${BOARD_SOCNAME}" == "nxp3220" ]; then
	BUILD_MACHINE_NAME="$(echo "$MACHINE_NAME" | cut -d'-' -f 1)"
	BSP_TOOLS_DIR=$BSP_ROOT_DIR/nxp3220_tools
else
	BUILD_MACHINE_NAME=$MACHINE_NAME
	BSP_TOOLS_DIR=$BSP_ROOT_DIR/tools
fi

parse_avail_target "$YOCTO_MACHINE_CONFIGS" "conf" AVAIL_MACHINE_TABLE MACHINE_SUPPORT
cyan "====== Available MACHINE ====="
for i in "${!AVAIL_MACHINE_TABLE[@]}"; do
	cyan "${AVAIL_MACHINE_TABLE[$i]}"
done
[ $? -ne 0 ] && cd $BSP_ROOT_DIR && return;

parse_avail_target "$YOCTO_IMAGE_ROOTFS" "bb" AVAIL_IMAGE_TABLE
cyan "====== Available IMAGE_TYPE ====="
for i in "${!AVAIL_IMAGE_TABLE[@]}"; do
	cyan "${AVAIL_IMAGE_TABLE[$i]}"
done
[ $? -ne 0 ] && cd $BSP_ROOT_DIR && return;

check_avail_target "$MACHINE_NAME" "$AVAIL_MACHINE_TABLE"
[ $? -ne 0 ] && cd $BSP_ROOT_DIR && return;

check_avail_target "$IMAGE_TYPE" "$AVAIL_IMAGE_TABLE"
[ $? -ne 0 ] && cd $BSP_ROOT_DIR && return;

# oe-init-build-env
cd $BSP_ROOT_DIR
mkdir -p $YOCTO_BUILD_OUT
mkdir -p $YOCTO_RESULT_OUT
source layers/poky/oe-init-build-env $YOCTO_BUILD_OUT

declare -A BUILD_LOCAL_CONF_CONFIGURE=(
	["BSP_ROOT_DIR"]="$BSP_ROOT_DIR"
	["BSP_VENDOR_DIR"]="$BSP_VENDOR_DIR"
	["BSP_TOOLS_DIR"]="$BSP_TOOLS_DIR"
	["BSP_TARGET_MACHINE"]="$MACHINE_NAME"
	["BSP_TARGET_SOCNAME"]="$BOARD_SOCNAME"
	["BSP_TARGET_BOARD_NAME"]="$BOARD_NAME"
	["BSP_TARGET_BOARD_PREFIX"]="$BOARD_PREFIX"
	["BSP_TARGET_BOARD_POSTFIX"]="$BOARD_POSTFIX"
	["BSP_TARGET_IMAGE_TYPE"]="$IMAGE_TYPE"
	["INITRAMFS_IMAGE"]="$IMAGE_TYPE"
)

function merge_conf_file () {
	local src=$1 cmp=$2 dst=$3

	while IFS='' read i;
    do
		merge=true
		while IFS='' read n;
		do
			[[ -z $i ]] && break;
			[[ $i == *BBMASK* ]] || [[ $i == *_append* ]] && break;
			[[ $i == *+=* ]] && break;
			[[ ${i:0:1} = "#" ]] && break;

			[[ -z $n ]] && continue;
			[[ $n == *BBMASK* ]] || [[ $n == *_append* ]] && continue;
			[[ $n == *+=* ]] && continue;
			[[ ${n:0:1} = "#" ]] && continue;

			ti=${i%=*} ti=${ti%% *}
			tn=${n%=*} tn=${tn%% *}

			# replace
			if [[ $ti == "$tn" ]]; then
				i=$(echo "$i" | sed -e "s/[[:space:]]\+/ /g")
				n=$(echo "$n" | sed -e "s/[[:space:]]\+/ /g")
				sed -i -e "s|$n|$i|" "$dst"
				merge=false
				break;
			fi
		done < "$src"

		# merge
        if [[ $merge == true ]] && [[ ${i:0:1} != "#" ]]; then
			i=$(echo "$i" | sed -e "s/[[:space:]]\+/ /g")
			echo "$i" >> "$dst";
        fi
	done < "$cmp"
}

function parse_conf_machine () {
	local dst=$BUILD_LOCAL_CONF
    local src="$YOCTO_MACHINE_CONFIGS/local.conf"
	local cmp="$YOCTO_MACHINE_CONFIGS/$MACHINE_NAME.conf"

	[[ ! -f $src ]] && exit 1;

	msg ""
	msg "local.conf [MACHINE]"
	msg " - copy    = $src"

	cp "$src" "$dst"

	rep="\"$BUILD_MACHINE_NAME\""
	sed -i "s/^MACHINE.*/MACHINE = $rep/" "$dst"

	msg " - merge   = $cmp"
	msg " - to      = $dst\n"

	echo "" >> "$dst"
	echo "# PARSING: $cmp" >> "$dst"
	merge_conf_file "$src" "$cmp" "$dst"

	for i in "${!BUILD_LOCAL_CONF_CONFIGURE[@]}"; do
		key="$i"
		rep="\"${BUILD_LOCAL_CONF_CONFIGURE[$i]//\//\\/}\""
		sed -i "s/^$key =.*/$key = $rep/" "$dst"
	done
	echo "# PARSING DONE" >> "$dst"
}

function parse_conf_image () {
    local dst=$BUILD_LOCAL_CONF
	local srcs=( $YOCTO_FEATURE_CONFIGS/${IMAGE_TYPE##*-}.conf )

	# for i in $BB_TARGET_FEATURES; do
	# 	srcs+=( $YOCTO_FEATURE_CONFIGS/$i.conf )
	# done

	for i in "${srcs[@]}"; do
		[[ ! -f $i ]] && continue;
		msg "local.conf [IMAGE]"
		msg " - merge   = $i"
		msg " - to      = $dst\n"

		echo "" >> "$dst"
		echo "# PARSING: $i" >> "$dst"
		merge_conf_file "$dst" "$i" "$dst"
		echo "# PARSING DONE" >> "$dst"
        done
}

function parse_conf_bblayer () {
	local src="$YOCTO_MACHINE_CONFIGS/bblayers.conf"
    local dst=$BUILD_LAYER_CONF

	msg "bblayers.conf"
	msg " - copy    = $src"
	msg " - to      = $dst\n"
	[[ ! -f $src ]] && exit 1;

    cp -a "$src" "$dst"
	local rep="\"${BSP_YOCTO_DIR//\//\\/}\""
	sed -i "s/^BSPPATH :=.*/BSPPATH := $rep/" "$dst"
}

parse_conf_machine
parse_conf_image
parse_conf_bblayer

# make-mod-scripts clean + make mrproper virtual/kernel
function kernel_make_clean()
{
	echo -e "\n ------------------------------------------------------------------ "
	echo -e "                        kernel clean                                "
	echo -e " ------------------------------------------------------------------ "

	pushd ${BSP_VENDOR_DIR}/kernel/kernel-4.4.x
	make ARCH=${ARM_ARCH} clean
	rm -rf .kernel-meta oe-logs oe-workdir .metadir .scmversion source

	# make-mod-scripts.bb build error fix
	if [ "${POKY_VERSION}" == "sumo" ];then
		make mrproper
		if [ -e ${YOCTO_BUILD_OUT}/tmp/work/clone_kernel_src ]; then
			rm -rf ${YOCTO_BUILD_OUT}/tmp/work/clone_kernel_src
		fi
		mkdir -p ${YOCTO_BUILD_OUT}/tmp/work/clone_kernel_src
		cp -a * ${YOCTO_BUILD_OUT}/tmp/work/clone_kernel_src/
	fi

	popd
}

declare -a clean_recipes_s5p4418=("nexell-${IMAGE_TYPE}" "virtual/kernel" "u-boot-nexell" "bl1-s5p4418")
declare -a clean_recipes_s5p6818=("optee-build" "optee-linuxdriver" "nexell-${IMAGE_TYPE}" "virtual/kernel" "u-boot-nexell" "bl1-s5p4418")
declare -a clean_recipes_nxlibs_1=("libdrm-nx" "nx-drm-allocator" "nx-gst-meta" "nx-renderer" "nx-scaler" "nx-v4l2" "nx-video-api" "nx-vidtex" "nx-gl-tools" "nx-uds" "nx-config")
declare -a clean_recipes_nxlibs_2=("libdrm-nx" "nx-drm-allocator" "nx-gst-meta" "nx-renderer" "nx-scaler" "nx-v4l2" "nx-video-api" "nx-vidtex" "nx-uds" "nx-config")
declare -a clean_recipes_gstlibs=("gst-plugins-camera" "gst-plugins-renderer" "gst-plugins-scaler" "gst-plugins-video-dec" "gst-plugins-video-sink")
declare -a clean_recipes_sdk=("nexell-daudio-sdk" "allgo-connectivity-sdk")

function copy_build_scripts()
{
    local secure=
    local TMP_WORK_PATH=${YOCTO_BUILD_OUT}/tmp/work

    if ! [ -d $TMP_WORK_PATH ];then
	mkdir -p $TMP_WORK_PATH
    fi

    #for secure boot support
    if [ "${BOARD_SOCNAME}" == "s5p6818" ]; then
        echo "SECURE OFF" > ${YOCTO_BUILD_OUT}/secure.cfg; secure="OFF"
        python ${META_NEXELL_PATH}/tools/secure_tools/secure-setup.py ${secure} ${BOARD_SOCNAME} ${MACHINE_NAME} ${META_NEXELL_PATH}

    fi

    touch ${TMP_WORK_PATH}/SOURCE_PATH_FOR_OPTEE.txt
    touch ${TMP_WORK_PATH}/LINUX_STANDARD_BUILD_PATH.txt

    cp -a ${META_NEXELL_PATH}/tools/optee_pre_operation.sh ${YOCTO_BUILD_OUT}
    echo -e "\033[0;33m                                                                    \033[0m"
    echo -e "\033[0;33m #########  Start bitbake pre operateion for optee & ATF ########## \033[0m"
    echo -e "\033[0;33m                                                                    \033[0m"

    if [ ! -e ${YOCTO_BUILD_OUT}/OPTEE_PRE_OPERATION_DONE ];then
		${YOCTO_BUILD_OUT}/optee_pre_operation.sh ${MACHINE_NAME}
		touch ${YOCTO_BUILD_OUT}/OPTEE_PRE_OPERATION_DONE
    else
		echo -e "\033[0;33m #########  Already Done, optee & ATF pre-fetch & pre-unpack ########## \033[0m"
    fi

    mkdir -p ${TMP_WORK_PATH}/use-post-process
}

if [ "${BOARD_SOCNAME}" == "s5p4418" ];then
	ARM_ARCH="arm"
	if [ "${IMAGE_TYPE}" == "ubuntu" ]; then
        cd ${YOCTO_BUILD_OUT}
        mkdir -p tmp/work/extra-rootfs-support
    fi
	copy_build_scripts
	kernel_make_clean
	echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_s5p4418[@]} \033[0m"
	echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_gstlibs[@]} \033[0m"
	if [ ${IMAGE_TYPE} == "qt" ];then
		echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_sdk[@]} \033[0m"
		echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_nxlibs_1[@]} \033[0m"
		bitbake -c cleanall ${clean_recipes_s5p4418[@]} ${clean_recipes_nxlibs_1[@]} ${clean_recipes_gstlibs[@]} ${clean_recipes_sdk[@]}
	else
		echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_nxlibs_2[@]} \033[0m"
		bitbake -c cleanall ${clean_recipes_s5p4418[@]} ${clean_recipes_nxlibs_2[@]} ${clean_recipes_gstlibs[@]}
	fi
fi

if [ "${BOARD_SOCNAME}" == "s5p6818" ];then
	ARM_ARCH="arm64"
	if [ "${IMAGE_TYPE}" == "ubuntu" ]; then
        cd ${YOCTO_BUILD_OUT}
        mkdir -p tmp/work/extra-rootfs-support
    fi
	copy_build_scripts
	kernel_make_clean
	echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_s5p6818[@]} \033[0m"
	echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_gstlibs[@]} \033[0m"
	if [ ${IMAGE_TYPE} == "qt" ];then
		echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_nxlibs_1[@]} \033[0m"
		bitbake -c cleanall ${clean_recipes_s5p6818[@]} ${clean_recipes_nxlibs_1[@]} ${clean_recipes_gstlibs[@]}
	else
		echo -e "\033[47;34m CLEAN TARGET : ${clean_recipes_nxlibs_2[@]} \033[0m"
		bitbake -c cleanall ${clean_recipes_s5p6818[@]} ${clean_recipes_nxlibs_2[@]} ${clean_recipes_gstlibs[@]}
	fi
fi

magenta "You can now run 'bitbake <image_type> \t"
magenta "Your image_types are: \t"

for i in "${!BITBAKE_IMAGE_TYPE[@]}"; do
	green "${BITBAKE_IMAGE_TYPE[$i]}"
done

#cp -af $BSP_ROOT_DIR/tools/copy-results-images.sh .

export BOARD_SOCNAME BSP_ROOT_DIR BSP_YOCTO_DIR META_NEXELL_PATH RESULT_PATH YOCTO_BUILD_OUT YOCTO_RESULT_OUT MACHINE_NAME IMAGE_TYPE

# in case of nxp3220
# bitbake nexell-image-qt

# in case of s5p4418 or s5p6818
# bitbake nexell-qt


