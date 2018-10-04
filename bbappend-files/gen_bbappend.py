#!/usr/bin/env python
#

import sys
import os

PREBUILT_BBAPPEND_PATH = "/tools/bbappend-files"
INDEX_GEN_PATH=0
INDEX_PATCH=1

R_BL1='/recipes-bsp/bl1'
R_BL2='/recipes-bsp/bl2'
R_ATF='/recipes-bsp/arm-trusted-firmware'
R_LLOADER='/recipes-bsp/l-loader'
R_ARMV7_DISPATCHER='/recipes-bsp/armv7-dispatcher'
R_KERNEL='/recipes-kernel/linux'
R_OPTEE='/recipes-bsp/optee'
R_UBOOT='/recipes-bsp/u-boot'
R_GST_LIBS='/recipes-nexell-libs/gst-plugins'
R_NX_LIBS='/recipes-nexell-libs/nx-libs'
R_TESTSUITE='/recipes-application/testsuite'
R_GRAPHICS_XORG='/recipes-graphics/xorg-driver'
R_SMARTVOICE='/recipes-multimedia/smart-voice-app'
R_CGMINER='/recipes-miners/cgminer'
R_MODBUS_TCP_SERVER='/recipes-miners/modbus-tcp-server'

TEMPLATE1=[
    '### Nexell - For Yocto build with using local source, Below lines are auto generated codes',
    '',
    'S = "${WORKDIR}/git"',
    '',
    'do_myp() {',
    '    rm -rf ${S}',
    '    mv ${WORKDIR}${_SRC_PATH_BY_GEN_} ${S}',
    '    rm -rf ${WORKDIR}/home',
    '}',
    'addtask myp before do_patch after do_unpack',
    '',
]

TEMPLATE2=[
    'do_mypatch() {',
    '    cd ${S}',
    '    ${_PATCH_FILE_BY_GEN_}',
    '}',
    'addtask mypatch after do_patch',
    '',
]

TEMPLATE_KERNEL=[
    '### Nexell - For Yocto build with using local source, Below lines are auto generated codes',
    'EXTERNALSRC = "${_SRC_PATH_BY_GEN_}"',
    'EXTERNALSRC_BUILD = "${_SRC_PATH_BY_GEN_}"',
    '',
    'S = "${WORKDIR}/${_SRC_PATH_BY_GEN_}"',
    '',
    '#clean .config',
    'do_configure_prepend() {',
    '    echo "" > ${S}/.config',
    '}'
]

TEMPLATE_SRC_URI='SRC_URI="file://${_SRC_PATH_BY_GEN_}"'

###  ----------------------------------------------------------------------------------------------------------------------------------------
###  ------------------------------------------------------------ Usage ---------------------------------------------------------------------
###  ----------------------------------------------------------------------------------------------------------------------------------------
###  {bbappend file name : [[real src path, recipes location, /tmp/work/.../buildpath location], [patch file name]]}
###  ex)) 's5p6818-avn-ref-bl1.bbappend': [['/bl1/bl1-s5p6818',R_BL1], ['0001-s5p6818-avn-bl1.patch']],
###                    |                              |           |                     '--->> .patch file of bl1 recipe
###                    |                              |           |
###                    |                              |           '--->> meta-nexell/recipes-bsp/  path
###                    |                              '--->> local source path in Your Host PC
###                    |
###                    '----->> This .bbappend file name have to same name .bb file in meta-nexell/recipes-xxx/
###  ----------------------------------------------------------------------------------------------------------------------------------------

HASH_RECIPENAME_PATH = {
    'bl1-s5p4418.bbappend':        [['/bl1/bl1-s5p4418',R_BL1], []],
    'bl1-s5p6818.bbappend':        [['/bl1/bl1-s5p6818',R_BL1], []],

    'bl2-s5p4418.bbappend':        [['/secure/bl2-s5p4418',R_BL2], []],

    'dispatcher-s5p4418.bbappend': [['/secure/armv7-dispatcher',R_ARMV7_DISPATCHER], []],

    'arm-trusted-firmware_%.bbappend':      [['/secure/arm-trusted-firmware',R_ATF],[]],

    'l-loader_%.bbappend':                  [['/secure/l-loader',R_LLOADER],[]],

    'u-boot-nexell.bbappend':           [['/u-boot/u-boot-2016.01',R_UBOOT],[]],

    'optee-build_%.bbappend':           [['/secure/optee/optee_build',R_OPTEE],['0001-optee-build-customize-for-yocto.patch']],
    'optee-client_%.bbappend':          [['/secure/optee/optee_client',R_OPTEE],[]],
    'optee-linuxdriver_%.bbappend':     [['/secure/optee/optee_linuxdriver',R_OPTEE],[]],
    'optee-os_%.bbappend':              [['/secure/optee/optee_os',R_OPTEE],['0001-optee-os-compile-error-patch.patch']],
    'optee-test_%.bbappend':            [['/secure/optee/optee_test',R_OPTEE],['0001-optee-test-compile-error-patch.patch']],

    'gst-plugins-camera_%.bbappend':    [['/library/gst-plugins-camera',R_GST_LIBS],[]],
    'gst-plugins-renderer_%.bbappend':  [['/library/gst-plugins-renderer',R_GST_LIBS],[]],
    'gst-plugins-scaler_%.bbappend':    [['/library/gst-plugins-scaler',R_GST_LIBS],[]],
    'gst-plugins-video-dec_%.bbappend': [['/library/gst-plugins-video-dec',R_GST_LIBS],[]],
    'gst-plugins-video-sink_%.bbappend': [['/library/gst-plugins-video-sink',R_GST_LIBS],[]],

    'libdrm-nx_%.bbappend':             [['/library/libdrm',R_NX_LIBS],[]],
    'nx-drm-allocator_%.bbappend':      [['/library/nx-drm-allocator',R_NX_LIBS],[]],
    'nx-gst-meta_%.bbappend':           [['/library/nx-gst-meta',R_NX_LIBS],[]],
    'nx-renderer_%.bbappend':           [['/library/nx-renderer',R_NX_LIBS],[]],
    'nx-scaler_%.bbappend':             [['/library/nx-scaler',R_NX_LIBS],[]],
    'nx-v4l2_%.bbappend':               [['/library/nx-v4l2',R_NX_LIBS],[]],
    'nx-video-api_%.bbappend':          [['/library/nx-video-api',R_NX_LIBS],['0001-nx-video-api-install-error-fix.patch']],

    'linux-s5p4418.bbappend':           [['/kernel/kernel-${LINUX_VERSION}',R_KERNEL],[]],
    'linux-s5p6818.bbappend':           [['/kernel/kernel-${LINUX_VERSION}',R_KERNEL],[]],

    'testsuite_%.bbappend' :            [['/apps/testsuite',R_TESTSUITE],[]],

    'smart-voice-testapp.bbappend' :            [['/apps/smartvoice',R_SMARTVOICE],[]],

    'xf86-video-armsoc-nexell_%.bbappend' :     [['/library/xf86-video-armsoc',R_GRAPHICS_XORG],[]],
    'cgminer-gekko_%.bbappend' :     [['/apps/bitminer/cgminer',R_CGMINER],[]],
    'modbus-tcp-server_%.bbappend' :     [['/apps/bitminer/modbus-tcp-server',R_MODBUS_TCP_SERVER],[]],
}

def gen_bbappend_paths(curWorkingPath) :
    bbfilesL = HASH_RECIPENAME_PATH.keys()
    bbfilesL.sort()
    for bbafile in bbfilesL :
        gen_bbappend_files(bbafile, curWorkingPath, HASH_RECIPENAME_PATH[bbafile])

def gen_bbappend_files(bbappendfile,curWorkingPath,hashData) :
    L_PATHS = hashData[INDEX_GEN_PATH]
    L_PATCH_FILES = hashData[INDEX_PATCH]

    BBAPPEND_FILE_PATH = curWorkingPath + PREBUILT_BBAPPEND_PATH + L_PATHS[1] + '/' + bbappendfile

    INTO_BBAPPEND_SRC_PATH = curWorkingPath + L_PATHS[0]  #host PC's local source path
    INTO_BBAPPEND_PATCH_FILE=""
    print BBAPPEND_FILE_PATH + "  ---> OK "
    f = open(BBAPPEND_FILE_PATH,'w')

    #kernel
    if L_PATHS[1]==R_KERNEL :
        for patch in L_PATCH_FILES :
            kernel_patch_copy(curWorkingPath+"/yocto/meta-nexell/meta-nexell-distro"+R_KERNEL+"/files/"+patch, INTO_BBAPPEND_SRC_PATH)

        for i in TEMPLATE_KERNEL :
            f.write(i+"\n")

        f.write("\n"+TEMPLATE_SRC_URI)
        f.write("\n")

    #others
    else :
        for i in TEMPLATE1 :
            f.write(i+"\n")

        f.write("\n"+TEMPLATE_SRC_URI)
        f.write("\n")

        if len(L_PATCH_FILES) > 0 :
            for i in TEMPLATE2 :
                f.write(i+"\n")

            for i in L_PATCH_FILES :
                f.write("SRC_URI+=\"file://"+i+"\""+"\n")
                INTO_BBAPPEND_PATCH_FILE += "patch -p1 < ${WORKDIR}/"+i+";"
        
            f.write("\n")
            f.write("\n_PATCH_FILE_BY_GEN_=\"" + INTO_BBAPPEND_PATCH_FILE + "\"")

        if "optee-build" in bbappendfile :
            f.write("\nLOCAL_KERNEL_SOURCE_USING="+'"'+'true'+'"')
        elif "optee-linuxdriver" in bbappendfile :
            f.write("\nLOCAL_KERNEL_SOURCE_USING="+'"'+'true'+'"')
        else :
            pass

    f.write("\n_SRC_PATH_BY_GEN_?=\""   + INTO_BBAPPEND_SRC_PATH + "\"")

    f.close()

def kernel_patch_copy(patchPath, kernelSrcPath) :
    os.system("cp "+patchPath+" "+kernelSrcPath)

def main(arg1):
    gen_bbappend_paths(arg1)

if __name__ == "__main__":
    try :
        main(sys.argv[1])
    finally :
        pass

