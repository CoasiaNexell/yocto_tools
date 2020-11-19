#!/bin/bash

# This file implements general functions to setup environments

################################################################################
# Define color for the log message
################################################################################
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
NORMAL="\033[0;39m"
BRIGHT_BLACK="\033[90m"
BRIGHT_RED="\033[91m"
BRIGHT_GREEN="\033[92m"
BRIGHT_YELLOW="\033[93m"
BRIGHT_BLUE="\033[94m"
BRIGHT_MAGENTA="\033[95m"
BRIGHT_CYAN="\033[96m"
BRIGHT_WHITE="\033[97m"

################################################################################
# For log message
################################################################################
function msg () {
    echo -e "$NORMAL$*\033[0m";
}
function msg_err () { echo -e "$BRIGHT_RED$*\033[0m"; }
function msg_info () { echo -e "$BRIGHT_GREEN$*\033[0m"; }
function msg_debug () { echo -e "$BRIGHT_YELLOW$*\033[0m"; }
function msg_warn () { echo -e "$BRIGHT_CYAN$*\033[0m"; }
function msg_verbose () { echo -e "$BRIGHT_MAGENTA$*\033[0m"; }
function msg_with_color () {
	local text_color=$1; shift
	local message=("$@")
	echo -e "$text_color${message[@]}\033[0m";
}
function print_line () {
    cols=$(tput cols)
    if [ -n $1 ]; then
        for ((i=0; i<cols; i++));do printf "$1=\033[0m"; done; echo
    else
        for ((i=0; i<cols; i++));do printf "$WHITE=\033[0m"; done; echo
    fi
}

function print_build_header ()
{
    print_line $BRIGHT_CYAN
    echo -e "$BRIGHT_CYAN$*\033[0m";
    print_line $BRIGHT_CYAN
}

function print_build_error ()
{
    print_line $BRIGHT_RED
    echo -e "$BRIGHT_RED$*\033[0m";
    print_line $BRIGHT_RED
}

################################################################################
# For Usage
#-------------------------------------------------------------------------------
# $1 - The path of the configuration file for extracting the available target machines.
# $2 - The path of the configuration file for extracting the available target images.
################################################################################
function usage()
{
	local configs_dir=$1
	local meta_dir=$2
	local machine_dir="${configs_dir}"
	local nxp3220_image_dir="${meta_dir}/recipes-core/images/nxp3220"
	local image_dir="${meta_dir}/recipes-core/images"

	parse_avail_target_machine $machine_dir "conf" AVAIL_MACHINE_TABLE

	parse_avail_target_images $nxp3220_image_dir "bb" AVAIL_NXP3220_IMAGE_TABLE

	parse_avail_target_images $image_dir "bb" AVAIL_IMAGE_TABLE

	print_line $YELLOW
    msg_with_color $BRIGHT_YELLOW "Usage: source envesetup.sh <TARGET-MACHINE-NAME> <TARGET-IMAGE-TYPE>"
	msg_with_color $YELLOW "Available <TARGET-MACHINE-NAME> :"
	msg_with_color $BRIGHT_CYAN "${AVAIL_MACHINE_TABLE[@]}"
	msg_with_color $YELLOW "Available <TARGET-IMAGE-TYPE> :"
	msg_with_color $BRIGHT_CYAN "nxp3220 : ${AVAIL_NXP3220_IMAGE_TABLE[@]}"
	msg_with_color $BRIGHT_CYAN "s5p4418/s5p6818 : ${AVAIL_IMAGE_TABLE[@]}"
	msg "If you want to add new target machine & image, Please refer to the file as below :"
	msg "layers/meta-nexell/meta-nexell-distro/configs/<SOC-NAME>/machines/<TARGET-MACHINE-NAME>.conf"
	msg "nxp3220 : layers/meta-nexell/meta-nexell-distro/configs/<SOC-NAME>/images/nxp3220/<TARGET-IMAGE-TYPE>.conf"
	msg "s5pxx18 : layers/meta-nexell/meta-nexell-distro/configs/<SOC-NAME>/images/<TARGET-IMAGE-TYPE>.conf"
	print_line $YELLOW
}

################################################################################
# Parsing the arguments
#-------------------------------------------------------------------------------
# $1 - The path of the configuration files for extracting the available target machines.
# $2 - The path of the configuration files for extracting the available target images.
################################################################################
function parse_args()
{
	local configs_dir=$1 meta_dir=$2; shift 2
	local args=("$@")

	TEMP=`getopt -o "s:t:hvV:d:T:i:k:p:m:q" -- "${args[@]}"`
	eval set -- "$TEMP"

	while true; do
		case "$1" in
			-h ) usage $configs_dir $meta_dir; return 1;;
			-- ) break ;;
		esac
	done

	return 0
}

################################################################################
# For option menu
#-------------------------------------------------------------------------------
# $1 - Return the user-selected value.
# $2 - List of option menu
################################################################################
function choose_option () {
    local result=$1; shift
	local options=("$@")

	PS3='Please enter your choice: '
    select opt in ${options[@]}
    do
        if [[ -n $opt ]]; then
            eval "$result=${opt}"
            break
        else
            msg_err "invalid option $REPLY"
        fi
    done
}

################################################################################
# Parsing availavle target machines
#-------------------------------------------------------------------------------
# $1 - The path of the configuration files
# $2 - File extension
# $3 - Return the names of available target machines.
################################################################################
function parse_avail_target_machine () {
	local path=$1 deli=$2 table=$3
	local val value bb tmp

	if ! cd "$path"; then return 1; fi

	dirs=$(find ./ machines -type d -print \
		2> >(grep -v 'No such file or directory' >&2) | \
		grep -w "machines" | sort)

	for dir in $dirs; do
		cd "$dir"
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

			val="${val} $(echo "$i" | awk -F".${deli}" '{print $1}')"
			eval "$table=(${val})"
		done
		cd "$path"
	done
}

################################################################################
# Parsing availavle target images
#-------------------------------------------------------------------------------
# $1 - The path of the configuration files
# $2 - File extension
# $3 - Return the names of available target images.
################################################################################
function parse_avail_target_images () {
	local dir=$1 deli=$2 table=$3
	local val value bb tmp

	if ! cd "$dir"; then return 1; fi

	value=$(find ./ -maxdepth 1 -print \
		2> >(grep -v 'No such file or directory' >&2) | \
		grep -w ".*\.${deli}" | sort)

	for i in $value; do
		i="$(echo "$i" | cut -d'/' -f2)"
		if [[ -n $(echo "$i" | awk -F".${deli}" '{print $2}') ]]; then
			continue
		fi

		val="${val} $(echo "$i" | awk -F".${deli}" '{print $1}')"
		eval "$table=(${val})"
	done
}

################################################################################
# Checking availavle target
#-------------------------------------------------------------------------------
# $1 - The name of the machine or image.
# $2 - The list of available target machines or images.
################################################################################
function check_avail_target () {
	local name=$1; shift
	local table=("$@")

	if [ -z $name ]; then
		return 0;
	fi

	for i in ${table[@]}; do
		[ $i == "$name" ] && return 0;
	done

	return 1;
}

################################################################################
# Set target machine
#-------------------------------------------------------------------------------
# $1 - The path of the configuration files
# $2 - Return the names of the target machine.
# $3 - The name of the target machine entered by the user.
################################################################################
function set_target_machine ()
{
    local config_path=$1 output_machine=$2 input_machine=$3

	pushd `pwd`

    parse_avail_target_machine $config_path "conf" AVAIL_MACHINE_TABLE

	check_avail_target $input_machine "${AVAIL_MACHINE_TABLE[@]}"

    if [ $? -ne 0 ] ; then
		if [ -z "$input_machine" ]; then
			print_build_error "The target machine is empty.\nPlease select the correct target machine name from the options menu as below : "
		else
			print_line $BRIGHT_RED
			echo -e "$BRIGHT_YELLOW'$input_machine'\033[0m $BRIGHT_RED is not supported.\nPlease select the correct target machine name from the options menu as below :\033[0m"
			print_line $BRIGHT_RED
		fi
        print_build_header "List of supported target machines"

		# local output_name=""
		choose_option OUTPUT_NAME "${AVAIL_MACHINE_TABLE[@]}"

		eval "$output_machine=$OUTPUT_NAME"
	else
		eval "$output_machine=$input_machine"
    fi

	popd
}

################################################################################
# Set target image
#-------------------------------------------------------------------------------
# $1 - The path of the configuration files
# $2 - Return the names of the target image.
# $3 - The name of the target image entered by the user.
################################################################################
function set_target_image ()
{
    local config_path=$1 output_image=$2 input_image=$3

	pushd `pwd`

    parse_avail_target_images $config_path "bb" AVAIL_IMAGE_TABLE

    check_avail_target $input_image "${AVAIL_IMAGE_TABLE[@]}"

    if [ $? -ne 0 ] ; then
		print_build_error "$input_image is not supported.\nPlease select the correct target image name from the options menu as below : "
        print_build_header "List of supported target images"

		# local output_name
		choose_option OUTPUT_NAME "${AVAIL_IMAGE_TABLE[@]}"

		eval "$output_image=$OUTPUT_NAME"
	else
		eval "$output_image=$input_image"
    fi

	popd
}

################################################################################
# Merge configuration files to destination folder.
#-------------------------------------------------------------------------------
# $1 - local.conf
# $2 - $MACHINE_NAME.conf
# $3 - output
################################################################################
function merge_conf_file () {
	local src=$1 cmp=$2 dst=$3

	while IFS='' read -r i || [ -n "$i" ];
    do
		merge=true
		while IFS='' read n || [ -n "$n" ];
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

################################################################################
# Parse configuration files of the machine
#-------------------------------------------------------------------------------
################################################################################
function parse_conf_machine () {
	local machine_name=$1 dst=$2 src=$3 cmp=$4
	declare -n local_configs=$5

	[[ ! -f $src ]] && return 1;

	msg ""
	msg "local.conf [MACHINE]"
	msg " - copy    = $src"

	cp "$src" "$dst"

	rep="\"$machine_name\""
	sed -i "s/^MACHINE.*/MACHINE = $rep/" "$dst"

	msg " - merge   = $cmp"
	msg " - to      = $dst\n"

	echo "" >> "$dst"
	echo "# PARSING: $cmp" >> "$dst"
	merge_conf_file "$src" "$cmp" "$dst"

	for i in "${!local_configs[@]}"; do
		key="$i"
		rep="\"${local_configs[$i]//\//\\/}\""
		sed -i "s/^$key =.*/$key = $rep/" "$dst"
	done

	echo "# PARSING DONE" >> "$dst"
}

################################################################################
# Parse configuration files of the image
#-------------------------------------------------------------------------------
################################################################################
function parse_conf_image () {
    local dst=$1; shift
	local srcs=("$@")

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

################################################################################
# Parse configuration files of the bblayer
#-------------------------------------------------------------------------------
################################################################################
function parse_conf_bblayer () {
	local path=$1
	local src=$2
    local dst=$3

	msg "bblayers.conf"
	msg " - copy    = $src"
	msg " - to      = $dst\n"

	[[ ! -f $src ]] && return 1;

    cp -a "$src" "$dst"
	local rep="\"${path//\//\\/}\""
	sed -i "s/^BSPPATH :=.*/BSPPATH := $rep/" "$dst"
}

################################################################################
# Copy build script to build directory
#-------------------------------------------------------------------------------
################################################################################
function copy_build_scripts()
{
    local secure=
    local TMP_WORK_PATH=${1}/tmp/work

    if ! [ -d $TMP_WORK_PATH ];then
	mkdir -p $TMP_WORK_PATH
    fi

    #for secure boot support
#if [ "${BOARD_SOCNAME}" == "s5p6818" ]; then
#        echo "SECURE OFF" > ${YOCTO_BUILD_OUT}/secure.cfg; secure="OFF"
#        python ${META_NEXELL_PATH}/tools/secure_tools/secure-setup.py ${secure} ${BOARD_SOCNAME} ${MACHINE_NAME} ${META_NEXELL_PATH}

#    fi

#touch ${TMP_WORK_PATH}/SOURCE_PATH_FOR_OPTEE.txt
#    touch ${TMP_WORK_PATH}/LINUX_STANDARD_BUILD_PATH.txt

#    cp -a ${META_NEXELL_PATH}/tools/optee_pre_operation.sh ${YOCTO_BUILD_OUT}
#    echo -e "\033[0;33m                                                                    \033[0m"
#    echo -e "\033[0;33m #########  Start bitbake pre operateion for optee & ATF ########## \033[0m"
#    echo -e "\033[0;33m                                                                    \033[0m"

#    if [ ! -e ${YOCTO_BUILD_OUT}/OPTEE_PRE_OPERATION_DONE ];then
#		${YOCTO_BUILD_OUT}/optee_pre_operation.sh ${MACHINE_NAME}
#		touch ${YOCTO_BUILD_OUT}/OPTEE_PRE_OPERATION_DONE
#    else
#		echo -e "\033[0;33m #########  Already Done, optee & ATF pre-fetch & pre-unpack ########## \033[0m"
#    fi

#    mkdir -p ${TMP_WORK_PATH}/use-post-process
}