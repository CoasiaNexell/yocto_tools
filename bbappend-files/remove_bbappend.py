#!/usr/bin/env python
#

import sys
import os

PREBUILT_BBAPPEND_PATH = "/tools/bbappend-files"
INDEX_BBAPPEND=0
INDEX_GEN_PATH=1
INDEX_PATCH=2

R_BL1='/recipes-bsp/bl1'
R_BL2='/recipes-bsp/bl2'
R_ARMV7_DISPATCHER='/recipes-bsp/armv7-dispatcher'
R_KERNEL='/recipes-kernel/linux'
R_OPTEE='/recipes-bsp/optee'
R_UBOOT='/recipes-bsp/u-boot'
R_GST_LIBS='/recipes-nexell-libs/gst-plugins'
R_NX_LIBS='/recipes-nexell-libs/nx-libs'
R_TESTSUITE='/recipes-application/testsuite'
R_GRAPHICS_XORG='/recipes-graphics/xorg-driver'
R_QTAPPS='/recipes-qt/nexell-apps'
R_SMARTVOICE='/recipes-multimedia/smart-voice-app'

HASH_RECIPENAME_PATH = {
    's5p4418-avn-ref-bl1.bbappend':         ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],
    's5p4418-navi-ref-bl1.bbappend':        ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],
    's5p4418-smart-voice-bl1.bbappend':     ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],
    's5p4418-ff-voice-bl1.bbappend':     ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],
    's5p4418-daudio-ref-bl1.bbappend':      ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],
    's5p6818-artik710-raptor-bl1.bbappend': ['ON',['/bl1/bl1-s5p6818',R_BL1,'/bl1-s5p6818'], []],
    's5p6818-avn-ref-bl1.bbappend':         ['ON',['/bl1/bl1-s5p6818',R_BL1,'/bl1-s5p6818'], []],
    's5p6818-kick-st-bl1.bbappend':         ['ON',['/bl1/bl1-s5p6818',R_BL1,'/bl1-s5p6818'], []],
    's5p4418-daudio-covi-bl1.bbappend':      ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],
	's5p4418-svm-ref-bl1.bbappend':        ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],
    's5p4418-daudio-cona-bl1.bbappend':      ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],
	's5p4418-cluster-bl1.bbappend':      ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],

    's5p4418-avn-ref-bl2.bbappend':         ['ON',['/secure/bl2-s5p4418',R_BL2,'/secure-s5p4418'], []],
    's5p4418-navi-ref-bl2.bbappend':        ['ON',['/secure/bl2-s5p4418',R_BL2,'/secure-s5p4418'], []],
    's5p4418-smart-voice-bl2.bbappend':     ['ON',['/secure/bl2-s5p4418',R_BL2,'/secure-s5p4418'], []],
    's5p4418-ff-voice-bl2.bbappend':     ['ON',['/secure/bl2-s5p4418',R_BL2,'/secure-s5p4418'], []],
    's5p4418-daudio-ref-bl2.bbappend':      ['ON',['/secure/bl2-s5p4418',R_BL2,'/secure-s5p4418'], []],
    's5p4418-daudio-covi-bl2.bbappend':      ['ON',['/secure/bl2-s5p4418',R_BL2,'/secure-s5p4418'], []],
	's5p4418-svm-ref-bl2.bbappend':        ['ON',['/secure/bl2-s5p4418',R_BL2,'/secure-s5p4418'], []],
    's5p4418-daudio-cona-bl2.bbappend':      ['ON',['/secure/bl2-s5p4418',R_BL2,'/secure-s5p4418'], []],
	's5p4418-cluster-bl2.bbappend':      ['ON',['/secure/bl2-s5p4418',R_BL2,'/secure-s5p4418'], []],

    's5p4418-avn-ref-dispatcher.bbappend':         ['ON',['/secure/armv7-dispatcher',R_ARMV7_DISPATCHER,'/armv7-dispatcher'], []],
    's5p4418-navi-ref-dispatcher.bbappend':        ['ON',['/secure/armv7-dispatcher',R_ARMV7_DISPATCHER,'/armv7-dispatcher'], []],
    's5p4418-smart-voice-dispatcher.bbappend':     ['ON',['/secure/armv7-dispatcher',R_ARMV7_DISPATCHER,'/armv7-dispatcher'], []],
    's5p4418-ff-voice-dispatcher.bbappend':     ['ON',['/secure/armv7-dispatcher',R_ARMV7_DISPATCHER,'/armv7-dispatcher'], []],
    's5p4418-daudio-ref-dispatcher.bbappend':      ['ON',['/secure/armv7-dispatcher',R_ARMV7_DISPATCHER,'/armv7-dispatcher'], []],
    's5p4418-daudio-covi-dispatcher.bbappend':      ['ON',['/secure/armv7-dispatcher',R_ARMV7_DISPATCHER,'/armv7-dispatcher'], []],
	's5p4418-svm-ref-dispatcher.bbappend':        ['ON',['/secure/armv7-dispatcher',R_ARMV7_DISPATCHER,'/armv7-dispatcher'], []],
    's5p4418-daudio-cona-dispatcher.bbappend':      ['ON',['/secure/armv7-dispatcher',R_ARMV7_DISPATCHER,'/armv7-dispatcher'], []],
	's5p4418-cluster-dispatcher.bbappend':      ['ON',['/secure/armv7-dispatcher',R_ARMV7_DISPATCHER,'/armv7-dispatcher'], []],

    'arm-trusted-firmware_%.bbappend':      ['ON',['/secure/arm-trusted-firmware','/recipes-bsp/arm-trusted-firmware','/arm-trusted-firmware'],[]],

    'l-loader_%.bbappend':                  ['ON',['/secure/l-loader','/recipes-bsp/l-loader','/l-loader'],[]],

    'optee-build_%.bbappend':      ['ON',['/secure/optee/optee_build',R_OPTEE,'/secure/optee_build'],    []],
    'optee-client_%.bbappend':     ['ON',['/secure/optee/optee_client',R_OPTEE,'/secure/optee_client'],  []],
    'optee-linuxdriver_%.bbappend':['ON',['/secure/optee/optee_linuxdriver',R_OPTEE,'/secure/optee_linuxdriver'],[]],
    'optee-os_%.bbappend':         ['ON',['/secure/optee/optee_os',R_OPTEE,'/secure/optee_os'],          []],
    'optee-test_%.bbappend':       ['ON',['/secure/optee/optee_test',R_OPTEE,'/secure/optee_test'],      []],

    's5p4418-avn-ref-uboot_%.bbappend':         ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p4418-navi-ref-uboot_%.bbappend':        ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p4418-smart-voice-uboot_%.bbappend':     ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p4418-ff-voice-uboot_%.bbappend':     ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p4418-daudio-ref-uboot_%.bbappend':      ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p6818-artik710-raptor-uboot_%.bbappend': ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p6818-avn-ref-uboot_%.bbappend':         ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p6818-kick-st-uboot_%.bbappend':         ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p4418-daudio-covi-uboot_%.bbappend':      ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
	's5p4418-svm-ref-uboot_%.bbappend':        ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p4418-daudio-cona-uboot_%.bbappend':      ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
	's5p4418-cluster-uboot_%.bbappend':      ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],

    'gst-plugins-camera_%.bbappend':    ['ON',['/library/gst-plugins-camera',R_GST_LIBS,'/gst-plugins-camera'],[]],
    'gst-plugins-renderer_%.bbappend':  ['ON',['/library/gst-plugins-renderer',R_GST_LIBS,'/gst-plugins-renderer'],[]],
    'gst-plugins-scaler_%.bbappend':    ['ON',['/library/gst-plugins-scaler',R_GST_LIBS,'/gst-plugins-scaler'],[]],

    'libdrm-nx_%.bbappend':             ['ON',['/library/libdrm',R_NX_LIBS,'/libdrm'],[]],
    'nx-drm-allocator_%.bbappend':      ['ON',['/library/nx-drm-allocator',R_NX_LIBS,'/nx-drm-allocator'],[]],
    'nx-gst-meta_%.bbappend':           ['ON',['/library/nx-gst-meta',R_NX_LIBS,'/nx-gst-meta'],[]],
    'nx-renderer_%.bbappend':           ['ON',['/library/nx-renderer',R_NX_LIBS,'/nx-renderer'],[]],
    'nx-scaler_%.bbappend':             ['ON',['/library/nx-scaler',R_NX_LIBS,'/nx-scaler'],[]],
    'nx-v4l2_%.bbappend':               ['ON',['/library/nx-v4l2',R_NX_LIBS,'/nx-v4l2'],[]],
    'nx-video-api_%.bbappend':          ['ON',['/library/nx-video-api',R_NX_LIBS,'/nx-video-api'],[]],

    'linux-s5p4418-avn-ref_%.bbappend':         ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'],  []],
    'linux-s5p4418-navi-ref_%.bbappend':        ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'],  []],
    'linux-s5p4418-smart-voice_%.bbappend':     ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'],  []],
    'linux-s5p4418-ff-voice_%.bbappend':     ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'],  []],
    'linux-s5p4418-daudio-ref_%.bbappend':      ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'],  []],
    'linux-s5p6818-artik710-raptor_%.bbappend': ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'], []],
    'linux-s5p6818-avn-ref_%.bbappend':         ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'], []],
    'linux-s5p6818-kick-st_%.bbappend':         ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'], []],
    'linux-s5p4418-daudio-covi_%.bbappend':      ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'],  []],
	'linux-s5p4418-svm-ref_%.bbappend':        ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'],  []],
    'linux-s5p4418-daudio-cona_%.bbappend':      ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'],  []],
	'linux-s5p4418-cluster_%.bbappend':      ['ON',['/kernel/kernel-4.4.x',R_KERNEL,'/kernel-4.4.x'],  []],

    'testsuite-s5p4418_%.bbappend' :            ['ON',['/apps/testsuite',R_TESTSUITE,'/testsuite'],[]],
    'testsuite-s5p6818_%.bbappend' :            ['ON',['/apps/testsuite',R_TESTSUITE,'/testsuite'],[]],

    'smart-voice-testapp.bbappend' :          ['ON',['/apps/smartvoice',R_SMARTVOICE,'/smartvoice'],[]],

    'xf86-video-armsoc-nexell_%.bbappend' :     ['ON',['/library/xf86-video-armsoc',R_GRAPHICS_XORG,'/xf86-video-armsoc'],[]],

    'NxAudioPlayer_%.bbappend' :                ['ON',['/apps/QT/NxAudioPlayer',R_QTAPPS,'/apps/QT/NxAudioPlayer'],[]],
    'NxQuickRearCam_%.bbappend' :               ['ON',['/apps/QT/NxQuickRearCam',R_QTAPPS,'/apps/QT/NxQuickRearCam'],[]],
    'NxVideoPlayer_%.bbappend' :                ['ON',['/apps/QT/NxVideoPlayer',R_QTAPPS,'/apps/QT/NxVideoPlayer'],[]],
}

def rm_bbappend_paths(curWorkingPath) :
    bbfilesL = HASH_RECIPENAME_PATH.keys()
    bbfilesL.sort()
    for bbafile in bbfilesL :
        if HASH_RECIPENAME_PATH[bbafile][0]=='ON' :
	    rm_bbappend_files(bbafile, curWorkingPath, HASH_RECIPENAME_PATH[bbafile])

def rm_bbappend_files(bbappendfile,curWorkingPath,hashData) :
    L_PATHS = hashData[INDEX_GEN_PATH]

    BBAPPEND_FILE_PATH = curWorkingPath + "/yocto/meta-nexell" + L_PATHS[1] + '/' + bbappendfile
    dummy_FILE_PATH = curWorkingPath + "/yocto/meta-nexell" + L_PATHS[1] + '/dummy'
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

