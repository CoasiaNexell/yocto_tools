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

INTERACTIVE_MODE=false

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
    ARGS=$(getopt -o i:c:h -- "$@");
    eval set -- "$ARGS";
    
    while true; do
            case "$1" in
                -i )
		    shift;
		    MACHINE_NAME=$1;
		    shift;
		    IMAGE_TYPE=$2;		    
		    INTERACTIVE_MODE=true;
		    break;
		    ;;
		-c )
		    shift;
		    MACHINE_NAME=$1;
		    shift;
		    IMAGE_TYPE=$2;
		    split_machine_name;
		    optee_clean;
		    exit 1;
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
    echo -e "\nUsage: $0 [-i interactive] <machine-name> <image-type>\n"
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
    bitbake ${MACHINE_NAME}-${IMAGE_TYPE}
}

function fusing_images()
{
    local ROOT_PATH=${TOP}
    RESULT_DIR="result-${MACHINE_NAME}-${IMAGE_TYPE}"
    
    echo -e "\n\033[0;34m ------------------------------------------------------------------ \033[0m"
    echo -e "\033[0;36m                      Convert images Running                        \033[0m"
    echo -e "\033[0;34m ------------------------------------------------------------------ \033[0m"    
   
    cd $ROOT_PATH/yocto/build-${MACHINE_NAME}-${IMAGE_TYPE}
    ../meta-nexell/tools/result-file-move.sh ${MACHINE_NAME} ${IMAGE_TYPE}
    cd $ROOT_PATH/yocto/${RESULT_DIR}
    ../meta-nexell/tools/convert_images.sh ${MACHINE_NAME} ${IMAGE_TYPE}

    echo -e "\n\033[0;34m --------------------------------------------------------------------------- \033[0m\n"
    echo -e "\033[0;36m  1. cd $ROOT_PATH/yocto/${RESULT_DIR}                                        \033[0m\n"
    echo -e "\033[0;36m     ../meta-nexell/tools/update_${BOARD_SOCNAME}.sh -p partmap_emmc.txt -r . \033[0m\n"
    echo -e "\033[0;36m     or                                                                       \033[0m\n"
    echo -e "\033[0;36m  2. ./tools/update.sh                                                        \033[0m\n"
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

parse_args $@
check_usage
split_machine_name

if [ ${INTERACTIVE_MODE} == "true" ];then
    python ./tools/build_and_update_interactive.py ${MACHINE_NAME} ${IMAGE_TYPE}
else
    gen_and_copy_bbappend
    bitbake_run
    fusing_images
fi
