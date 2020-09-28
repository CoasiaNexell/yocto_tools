### Nexell - For Yocto build with using local source, Below lines are auto generated codes
EXTERNALSRC = "${_SRC_PATH_BY_GEN_}"
EXTERNALSRC_BUILD = "${_SRC_PATH_BY_GEN_}"

S = "${WORKDIR}/${_SRC_PATH_BY_GEN_}"

#clean .config
do_configure_prepend() {
    echo "" > ${S}/.config
}


SRC_URI="file://${_SRC_PATH_BY_GEN_}"

_SRC_PATH_BY_GEN_?="/home/ray/work2/yocto-btc08/kernel/kernel-${LINUX_VERSION}"