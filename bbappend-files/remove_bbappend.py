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

HASH_RECIPENAME_PATH = {
    'bl1-s5p4418.bbappend':        [['/bl1/bl1-s5p4418',R_BL1], []],
    'bl1-s5p6818.bbappend':        [['/bl1/bl1-s5p6818',R_BL1], []],

    'bl2-s5p4418.bbappend':        [['/secure/bl2-s5p4418',R_BL2], []],

    'dispatcher-s5p4418.bbappend': [['/secure/armv7-dispatcher',R_ARMV7_DISPATCHER], []],

    'arm-trusted-firmware_%.bbappend':      [['/secure/arm-trusted-firmware',R_ATF],[]],

    'l-loader_%.bbappend':                  [['/secure/l-loader',R_LLOADER],[]],

    'u-boot-nexell.bbappend':           [['/u-boot/u-boot-2016.01',R_UBOOT],[]],

    'optee-build_%.bbappend':           [['/secure/optee/optee_build',R_OPTEE],[]],
    'optee-client_%.bbappend':          [['/secure/optee/optee_client',R_OPTEE],[]],
    'optee-linuxdriver_%.bbappend':     [['/secure/optee/optee_linuxdriver',R_OPTEE],[]],
    'optee-os_%.bbappend':              [['/secure/optee/optee_os',R_OPTEE],[]],
    'optee-test_%.bbappend':            [['/secure/optee/optee_test',R_OPTEE],[]],

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
    'nx-video-api_%.bbappend':          [['/library/nx-video-api',R_NX_LIBS],[]],

    'linux-s5p4418.bbappend':           [['/kernel/kernel-${LINUX_VERSION}',R_KERNEL],[]],
    'linux-s5p6818.bbappend':           [['/kernel/kernel-${LINUX_VERSION}',R_KERNEL],[]],

    'testsuite_%.bbappend' :            [['/apps/testsuite',R_TESTSUITE],[]],

    'smart-voice-testapp.bbappend' :            [['/apps/smartvoice',R_SMARTVOICE],[]],

    'xf86-video-armsoc-nexell_%.bbappend' :     [['/library/xf86-video-armsoc',R_GRAPHICS_XORG],[]],
    'cgminer-gekko_%.bbappend' :     [['/apps/bitminer/cgminer',R_CGMINER],[]],
    'modbus-tcp-server_%.bbappend' :     [['/apps/bitminer/modbus-tcp-server',R_MODBUS_TCP_SERVER],[]],
}

def rm_bbappend_paths(curWorkingPath) :
    bbfilesL = HASH_RECIPENAME_PATH.keys()
    bbfilesL.sort()
    for bbafile in bbfilesL :
        rm_bbappend_files(bbafile, curWorkingPath, HASH_RECIPENAME_PATH[bbafile])

def rm_bbappend_files(bbappendfile,curWorkingPath,hashData) :
    L_PATHS = hashData[INDEX_GEN_PATH]

    BBAPPEND_FILE_PATH = curWorkingPath + "/yocto/meta-nexell/meta-nexell-distro" + L_PATHS[1] + '/' + bbappendfile
    dummy_FILE_PATH = curWorkingPath + "/yocto/meta-nexell/meta-nexell-distro" + L_PATHS[1] + '/dummy'
    os.system("rm -rf " + BBAPPEND_FILE_PATH)
    os.system("rm -rf " + dummy_FILE_PATH)

    BBAPPEND_FILE_PATH2 = curWorkingPath + "/tools/bbappend-files" + L_PATHS[1] + '/' + bbappendfile
    os.system("rm -rf " + BBAPPEND_FILE_PATH2)

def main(arg1):
    rm_bbappend_paths(arg1)

if __name__ == "__main__":
    try :
        main(sys.argv[1])
    finally :
        pass
						   
