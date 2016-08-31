#!/usr/bin/env python
#

import sys
import os

PREBUILT_BBAPPEND_PATH = "/tools/bbappend-files"
INDEX_BBAPPEND=0
INDEX_GEN_PATH=1
INDEX_PATCH=2

R_BL1='/recipes-bsp/bl1'
R_KERNEL='/recipes-kernel/linux'
R_OPTEE='/recipes-bsp/optee'
R_UBOOT='/recipes-bsp/u-boot'
R_GST_LIBS='/recipes-nexell-libs/gst-plugins'
R_NX_LIBS='/recipes-nexell-libs/nx-libs'
R_TESTSUITE='/recipes-application/testsuite'


HASH_RECIPENAME_PATH = {
    's5p4418-avn-ref-bl1.bbappend':         ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], ['0001-bl1-AVN.patch']],
    's5p4418-navi-ref-bl1.bbappend':        ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], ['0001-NAVI-NSP4330-Bl1-Board-SETTING.patch']],
    's5p6818-artik710-raptor-bl1.bbappend': ['ON',['/bl1/bl1-s5p6818',R_BL1,'/bl1-s5p6818'], []],
    's5p6818-avn-ref-bl1.bbappend':         ['ON',['/bl1/bl1-s5p6818',R_BL1,'/bl1-s5p6818'], ['0001-s5p6818-avn-bl1.patch']],

    'arm-trusted-firmware_%.bbappend':      ['ON',['/secure/arm-trusted-firmware','/recipes-bsp/arm-trusted-firmware','/arm-trusted-firmware'],
					     ['0001-ATF-SECURE_ON-flags-setting.patch']],

    'l-loader_%.bbappend':                  ['ON',['/secure/l-loader','/recipes-bsp/l-loader','/l-loader'],[]],

    'optee-build_%.bbappend':      ['ON',['/secure/optee/optee_build',R_OPTEE,'/secure/optee_build'],    ['0001-optee-build-customize-for-yocto.patch']],
    'optee-client_%.bbappend':     ['ON',['/secure/optee/optee_client',R_OPTEE,'/secure/optee_client'],  []],
    'optee-linuxdriver_%.bbappend':['ON',['/secure/optee/optee_linuxdriver',R_OPTEE,'/secure/optee_linuxdriver'],[]],
    'optee-os_%.bbappend':         ['ON',['/secure/optee/optee_os',R_OPTEE,'/secure/optee_os'],          ['0001-optee-os-compile-error-patch.patch']],
    'optee-test_%.bbappend':       ['ON',['/secure/optee/optee_test',R_OPTEE,'/secure/optee_test'],      []],

    's5p4418-avn-ref-uboot_%.bbappend':         ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],['0001-bootcmd-add-for-avn-yocto.patch']],
    's5p4418-navi-ref-uboot_%.bbappend':        ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],['0001-bootcmd-add-for-navi-yocto.patch']],
    's5p6818-artik710-raptor-uboot_%.bbappend': ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p6818-avn-ref-uboot_%.bbappend':         ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],['0001-bootcmd-add-for-avn-s5p6818.patch']],
    
    'gst-plugins-camera_%.bbappend':    ['ON',['/library/gst-plugins-camera',R_GST_LIBS,'/gst-plugins-camera'],[]],
    'gst-plugins-renderer_%.bbappend':  ['ON',['/library/gst-plugins-renderer',R_GST_LIBS,'/gst-plugins-renderer'],[]],
    'gst-plugins-scaler_%.bbappend':    ['ON',['/library/gst-plugins-scaler',R_GST_LIBS,'/gst-plugins-scaler'],[]],
    'gst-plugins-video-dec_%.bbappend': ['ON',['/library/gst-plugins-video-dec',R_GST_LIBS,'/gst-plugins-video-dec'],[]],
    'gst-plugins-video-enc_%.bbappend': ['ON',['/library/gst-plugins-video-enc',R_GST_LIBS,'/gst-plugins-video-enc'],[]],
    'gst-plugins-video-sink_%.bbappend':['ON',['/library/gst-plugins-video-sink',R_GST_LIBS,'/gst-plugins-video-sink'],[]],

    'libdrm-nx_%.bbappend':             ['ON',['/library/libdrm',R_NX_LIBS,'/libdrm'],[]],
    'libomxil-nx_%.bbappend':           ['ON',['/library/libomxil-nx',R_NX_LIBS,'/libomxil-nx'],[]],
    'nx-drm-allocator_%.bbappend':      ['ON',['/library/nx-drm-allocator',R_NX_LIBS,'/nx-drm-allocator'],[]],
    'nx-gst-meta_%.bbappend':           ['ON',['/library/nx-gst-meta',R_NX_LIBS,'/nx-gst-meta'],[]],
    'nx-renderer_%.bbappend':           ['ON',['/library/nx-renderer',R_NX_LIBS,'/nx-renderer'],[]],
    'nx-scaler_%.bbappend':             ['ON',['/library/nx-scaler',R_NX_LIBS,'/nx-scaler'],[]],
    'nx-v4l2_%.bbappend':               ['ON',['/library/nx-v4l2',R_NX_LIBS,'/nx-v4l2'],[]],
    'nx-video-api_%.bbappend':          ['ON',['/library/nx-video-api',R_NX_LIBS,'/nx-video-api'],['0001-nx-video-api-install-error-fix.patch']],

    'linux-s5p4418-avn-ref_%.bbappend':     ['OFF',['/kernel/kernel-4.1.15',R_KERNEL,'/kernel-4.1.15'],
				           ['0001-Yocto-avn-ref-defconfig-changed-for-QT-working.patch','0001-Yocto-mali400-Kbuild-compile-error-fix.patch']],
    'linux-s5p4418-navi-ref_%.bbappend':    ['OFF',['/kernel/kernel-4.1.15',R_KERNEL,'/kernel-4.1.15'],
				           ['0001-Yocto-navi-ref-defconfig-changed-for-QT-working.patch', '0001-Yocto-mali400-Kbuild-compile-error-fix.patch']],
    'linux-s5p6818-artik710-raptor_%.bbappend': ['OFF',['/kernel/kernel-4.1.15',R_KERNEL,'/kernel-4.1.15'],
						       ['0001-Yocto-mali400-Kbuild-compile-error-fix.patch']],
    'linux-s5p6818-avn-ref_%.bbappend':         ['OFF',['/kernel/kernel-4.1.15',R_KERNEL,'/kernel-4.1.15'],
					               ['0001-Yocto-mali400-Kbuild-compile-error-fix.patch','0001-drm_lcd.patch']],

    'testsuite_%.bbappend' :            ['ON',['/apps/testsuite',R_TESTSUITE,'/testsuite'],[]],
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
						   
