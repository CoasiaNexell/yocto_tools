#!/usr/bin/env python
#

import sys
import os

PREBUILT_BBAPPEND_PATH = "/tools/bbappend-files"
INDEX_GEN_PATH = 0
INDEX_PATCH = 1

R_BL1 = '/recipes-bsp/bl1'
R_BL2 = '/recipes-bsp/bl2'
R_ATF = '/recipes-bsp/arm-trusted-firmware'
R_LLOADER = '/recipes-bsp/l-loader'
R_ARMV7_DISPATCHER = '/recipes-bsp/armv7-dispatcher'
R_KERNEL = '/recipes-kernel/linux'
R_OPTEE = '/recipes-bsp/optee'
R_UBOOT = '/recipes-bsp/u-boot'
R_GST_LIBS = '/recipes-nexell-libs/gst-plugins'
R_NX_LIBS = '/recipes-nexell-libs/nx-libs'
R_TESTSUITE = '/recipes-application/testsuite'
R_VID_API_TEST = '/recipes-application/nx_video_api_test'
R_GRAPHICS_XORG = '/recipes-graphics/xorg-driver'
R_QTAPPS = '/recipes-qt/nexell-apps'
R_SMARTVOICE = '/recipes-multimedia/smart-voice-app'
R_SDK = '/recipes-solutions/nexell-sdk'
R_NX_INIT = '/recipes-extended/nexell-init'
R_SVM_DAEMON = '/recipes-application/svm-daemon'
R_NX_QUICKREARCAM = '/recipes-application/nx-quickrearcam'

TEMPLATE0 = [
    '### Nexell - For Yocto build with using local source, Below lines are auto generated codes',
    '',
    'S = "${WORKDIR}/git"',
    'PV = "1.0+EXTERNAL_SRC"',
    '',
    'do_myp() {',
    '    rm -rf ${S}',
    '    mv ${WORKDIR}${_SRC_PATH_BY_GEN_} ${S}',
    '    rm -rf ${WORKDIR}/home',
    '}',
    'addtask myp before do_configure after do_unpack',
    '',
]

TEMPLATE1 = [
    '### Nexell - For Yocto build with using local source, Below lines are auto generated codes',
    '',
    'PV = "1.0+EXTERNAL_SRC"',
    '',
    'EXTERNALSRC = "${_SRC_PATH_BY_GEN_}"',
    'EXTERNALSRC_BUILD = "${_SRC_PATH_BY_GEN_}"',
    '',
    'S = "${WORKDIR}/${_SRC_PATH_BY_GEN_}"',
    '',
]

TEMPLATE2 = [
    '',
    'do_patch() {',
    '    :',
    '}',
    '',
    'do_mypatch() {',
    '    cd ${S}',
    '    if [ -e PATCH_DONE_BY_YOCTO ];then',
    '        ${_PATCH_FILE_REVERT_BY_GEN_}',
    '        rm PATCH_DONE_BY_YOCTO',
    '    fi',
    '    ${_PATCH_FILE_BY_GEN_}',
    '    touch PATCH_DONE_BY_YOCTO',
    '}',
    'addtask mypatch before do_compile after do_configure',
    '',
]

TEMPLATE_KERNEL = [
    '### Nexell - For Yocto build with using local source, Below lines are auto generated codes',
    'EXTERNALSRC = "${_SRC_PATH_BY_GEN_}"',
    'EXTERNALSRC_BUILD = "${_SRC_PATH_BY_GEN_}"',
    '',
    'S = "${WORKDIR}/${_SRC_PATH_BY_GEN_}"',
    '',
    '#clean .config',
    'do_configure_prepend() {',
    '    echo "" > ${S}/.config',
    '}',
    '',
]

TEMPLATE_SRC_URI = 'SRC_URI="file://${_SRC_PATH_BY_GEN_}"'

OPTEE_PATH_LIST = []
OPTEE_BUILD_BBAPPEND_PATH = ''
OPTEE_LINUXDRIVER_BBAPPEND_PATH = ''

# ##  ----------------------------------------------------------------------------------------------------------------------------------------
# ##  ------------------------------------------------------------ Usage ---------------------------------------------------------------------
# ##  ----------------------------------------------------------------------------------------------------------------------------------------
# ##  {bbappend file name : [[real src path, recipes location, /tmp/work/.../buildpath location], [patch file name]]}
# ##  ex)) 's5p6818-avn-ref-bl1.bbappend': [['/bl1/bl1-s5p6818',R_BL1], ['0001-s5p6818-avn-bl1.patch']],
# ##                    |                              |           |                     '--->> .patch file of bl1 recipe
# ##                    |                              |           |
# ##                    |                              |           '--->> meta-nexell/recipes-bsp/  path
# ##                    |                              '--->> local source path in Your Host PC
# ##                    |
# ##                    '----->> This .bbappend file name have to same name .bb file in meta-nexell/recipes-xxx/
# ##  ----------------------------------------------------------------------------------------------------------------------------------------

HASH_RECIPENAME_PATH = {
    'bl1-s5p4418.bbappend':        [['/bl1/bl1-s5p4418', R_BL1], []],
    'bl1-s5p6818.bbappend':        [['/bl1/bl1-s5p6818', R_BL1], []],

    'bl2-s5p4418.bbappend':        [['/secure/bl2-s5p4418', R_BL2], []],

    'dispatcher-s5p4418.bbappend': [['/secure/armv7-dispatcher', R_ARMV7_DISPATCHER], []],

    'arm-trusted-firmware_%.bbappend':      [['/secure/arm-trusted-firmware', R_ATF], []],

    'l-loader_%.bbappend':                  [['/secure/l-loader', R_LLOADER], []],

    'u-boot-nexell.bbappend':           [['/u-boot/u-boot-2016.01', R_UBOOT], []],

    'optee-build_%.bbappend':           [['/secure/optee/optee_build', R_OPTEE], ['0001-optee-build-customize-for-yocto.patch']],
    'optee-client_%.bbappend':          [['/secure/optee/optee_client', R_OPTEE], []],
    'optee-linuxdriver_%.bbappend':     [['/secure/optee/optee_linuxdriver', R_OPTEE], []],
    'optee-os_%.bbappend':              [['/secure/optee/optee_os', R_OPTEE], ['0001-optee-os-compile-error-patch.patch']],
    'optee-test_%.bbappend':            [['/secure/optee/optee_test', R_OPTEE], ['0001-optee-test-compile-error-patch.patch']],

    'gst-plugins-camera_%.bbappend':    [['/library/gst-plugins-camera', R_GST_LIBS], []],
    'gst-plugins-renderer_%.bbappend':  [['/library/gst-plugins-renderer', R_GST_LIBS], []],
    'gst-plugins-scaler_%.bbappend':    [['/library/gst-plugins-scaler', R_GST_LIBS], []],
    'gst-plugins-video-dec_%.bbappend': [['/library/gst-plugins-video-dec', R_GST_LIBS], []],
    'gst-plugins-video-sink_%.bbappend': [['/library/gst-plugins-video-sink', R_GST_LIBS], []],

    'libdrm-nx_%.bbappend':             [['/library/libdrm', R_NX_LIBS], []],
    'nx-drm-allocator_%.bbappend':      [['/library/nx-drm-allocator', R_NX_LIBS], []],
    'nx-gst-meta_%.bbappend':           [['/library/nx-gst-meta', R_NX_LIBS], []],
    'nx-renderer_%.bbappend':           [['/library/nx-renderer', R_NX_LIBS], []],
    'nx-scaler_%.bbappend':             [['/library/nx-scaler', R_NX_LIBS], []],
    'nx-v4l2_%.bbappend':               [['/library/nx-v4l2', R_NX_LIBS], []],
    'nx-video-api_%.bbappend':          [['/library/nx-video-api', R_NX_LIBS], []],
    'nx-gl-tools_%.bbappend':           [['/library/nx-gl-tools', R_NX_LIBS], []],
    'nx-uds_%.bbappend':                [['/library/nx-uds', R_NX_LIBS], []],
    'nx-config_%.bbappend':             [['/library/nx-config', R_NX_LIBS], []],

    'linux-s5p4418.bbappend':           [['/kernel/kernel-${LINUX_VERSION}', R_KERNEL], []],
    'linux-s5p6818.bbappend':           [['/kernel/kernel-${LINUX_VERSION}', R_KERNEL], []],

    'testsuite_%.bbappend' :            [['/apps/testsuite', R_TESTSUITE], []],
    'smart-voice-testapp.bbappend' :            [['/apps/smartvoice', R_SMARTVOICE], []],

    'xf86-video-armsoc-nexell_%.bbappend' :     [['/library/xf86-video-armsoc', R_GRAPHICS_XORG], []],

    'nexell-daudio-sdk.bbappend' :        [['/solutions/displayaudio-sdk', R_SDK], []],
    'allgo-connectivity-sdk.bbappend' :   [['/solutions/allgo-connectivity-sdk', R_SDK], []],

    'nexell-init_%.bbappend' :          [['/apps/nx_init', R_NX_INIT], []],
    'svm-daemon_%.bbappend' :           [['/apps/svm_daemon', R_SVM_DAEMON], []],
    'nx-quickrearcam_%.bbappend' :      [['/apps/nx_quickrearcam', R_NX_QUICKREARCAM], []],
}


def gen_bbappend_paths(curWorkingPath):
    global OPTEE_BUILD_BBAPPEND_PATH
    global OPTEE_LINUXDRIVER_BBAPPEND_PATH
    bbfilesL = HASH_RECIPENAME_PATH.keys()
    bbfilesL.sort()
    for bbafile in bbfilesL:
        gen_bbappend_files(bbafile, curWorkingPath, HASH_RECIPENAME_PATH[bbafile])
        print(bbafile)

    f = open(OPTEE_BUILD_BBAPPEND_PATH, 'a')
    f.write("\n\n")
    for i in OPTEE_PATH_LIST:
        f.write(i + "\n")
    f.close()

    f = open(OPTEE_LINUXDRIVER_BBAPPEND_PATH, 'a')
    f.write("\n\n")
    for i in OPTEE_PATH_LIST:
        f.write(i + "\n")
    f.close()


def gen_bbappend_files(bbappendfile, curWorkingPath, hashData):
    global OPTEE_BUILD_BBAPPEND_PATH
    global OPTEE_LINUXDRIVER_BBAPPEND_PATH
    L_PATHS = hashData[INDEX_GEN_PATH]
    L_PATCH_FILES = hashData[INDEX_PATCH]

    BBAPPEND_FILE_PATH = curWorkingPath + PREBUILT_BBAPPEND_PATH + L_PATHS[1] + '/' + bbappendfile

    INTO_BBAPPEND_SRC_PATH = curWorkingPath + L_PATHS[0]  # host PC's local source path
    INTO_BBAPPEND_PATCH_FILE = ""
    INTO_BBAPPEND_PATCH_R_FILE = ""
    print (BBAPPEND_FILE_PATH + "  ---> OK ")

    if L_PATHS[1] == R_BL1 or \
       L_PATHS[1] == R_OPTEE or \
       L_PATHS[1] == R_ATF or \
       L_PATHS[1] == R_KERNEL or \
       L_PATHS[1] == R_UBOOT or \
       L_PATHS[1] == R_LLOADER :
        optee_env_path_setup(INTO_BBAPPEND_SRC_PATH)

    f = open(BBAPPEND_FILE_PATH, 'w')

    # kernel
    if L_PATHS[1] == R_KERNEL:
        for patch in L_PATCH_FILES:
            kernel_patch_copy(curWorkingPath + "/yocto/meta-nexell/meta-nexell-distro" + R_KERNEL + "/files/" + patch, INTO_BBAPPEND_SRC_PATH)

        for i in TEMPLATE_KERNEL:
            f.write(i + "\n")

        f.write("\n" + TEMPLATE_SRC_URI)
        f.write("\n")

    # others
    else:
        if L_PATHS[1] == R_NX_LIBS or L_PATHS[1] == R_GST_LIBS or L_PATHS[1] == R_SDK:
            for i in TEMPLATE0:
                f.write(i + "\n")
        else:
            for i in TEMPLATE1:
                f.write(i + "\n")

        f.write("\n" + TEMPLATE_SRC_URI)
        f.write("\n")

        if len(L_PATCH_FILES) > 0:
            for i in L_PATCH_FILES:
                f.write("SRC_URI_append = \" file://" + i + "\"" + "\n")
                INTO_BBAPPEND_PATCH_FILE += "patch -p1 < ${WORKDIR}/" + i + " -f;"
                INTO_BBAPPEND_PATCH_R_FILE += "patch -R -p1 < ${WORKDIR}/" + i + " -f;"

            for i in TEMPLATE2:
                f.write(i + "\n")

            f.write("\n")
            f.write("\n_PATCH_FILE_BY_GEN_=\"" + INTO_BBAPPEND_PATCH_FILE + "\"")
            f.write("\n_PATCH_FILE_REVERT_BY_GEN_=\"" + INTO_BBAPPEND_PATCH_R_FILE + "\"")

        if "optee-build" in bbappendfile:
            f.write("\nLOCAL_KERNEL_SOURCE_USING=" + '"' + 'true' + '"')
            OPTEE_BUILD_BBAPPEND_PATH = BBAPPEND_FILE_PATH
        elif "optee-linuxdriver" in bbappendfile:
            f.write("\nLOCAL_KERNEL_SOURCE_USING=" + '"' + 'true' + '"')
            OPTEE_LINUXDRIVER_BBAPPEND_PATH = BBAPPEND_FILE_PATH
        else:
            pass

    f.write("\n_SRC_PATH_BY_GEN_?=\""   + INTO_BBAPPEND_SRC_PATH + "\"")

    f.close()


def optee_env_path_setup(path):
    if "bl1-s5p6818" in path:
        OPTEE_PATH_LIST.append('PATH_BL1 := "' + path + '"')
    elif "l-loader" in path:
        OPTEE_PATH_LIST.append('PATH_L-LOADER := "' + path + '"')
    elif "optee_build" in path:
        OPTEE_PATH_LIST.append('PATH_OPTEE_BUILD := "' + path + '"')
    elif "optee_client" in path:
        OPTEE_PATH_LIST.append('PATH_OPTEE_CLIENT := "' + path + '"')
    elif "optee_linuxdriver" in path:
        OPTEE_PATH_LIST.append('PATH_OPTEE_LINUXDRIVER := "' + path + '"')
    elif "optee_os" in path:
        OPTEE_PATH_LIST.append('PATH_OPTEE_OS := "' + path + '"')
    elif "optee_test" in path:
        OPTEE_PATH_LIST.append('PATH_OPTEE_TEST := "' + path + '"')
    elif "u-boot" in path:
        OPTEE_PATH_LIST.append('PATH_U-BOOT := "' + path + '"')
    elif "arm-trusted-firmware" in path:
        OPTEE_PATH_LIST.append('PATH_ATF := "' + path + '"')


def kernel_patch_copy(patchPath, kernelSrcPath):
    os.system("cp " + patchPath + " " + kernelSrcPath)


def rm_bbappend_paths(curWorkingPath):
    bbfilesL = HASH_RECIPENAME_PATH.keys()
    bbfilesL.sort()
    for bbafile in bbfilesL:
        rm_bbappend_files(bbafile, curWorkingPath, HASH_RECIPENAME_PATH[bbafile])


def rm_bbappend_files(bbappendfile, curWorkingPath, hashData):
    L_PATHS = hashData[INDEX_GEN_PATH]

    BBAPPEND_FILE_PATH = curWorkingPath + "/yocto/meta-nexell/meta-nexell-distro" + L_PATHS[1] + '/' + bbappendfile
    dummy_FILE_PATH = curWorkingPath + "/yocto/meta-nexell/meta-nexell-distro" + L_PATHS[1] + '/dummy'
    os.system("rm -rf " + BBAPPEND_FILE_PATH)
    os.system("rm -rf " + dummy_FILE_PATH)

    BBAPPEND_FILE_PATH2 = curWorkingPath + "/tools/bbappend-files" + L_PATHS[1] + '/' + bbappendfile
    os.system("rm -rf " + BBAPPEND_FILE_PATH2)


def main(arg1, arg2):
    if arg2 == "generate":
        gen_bbappend_paths(arg1)
    else:
        rm_bbappend_paths(arg1)


if __name__ == "__main__":
    try:
        main(sys.argv[1], sys.argv[2])
    finally:
        pass
