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

TEMPLATE1=[
    "### Nexell - For Yocto build with using local source, Below lines are auto generated codes",
    "",
    "S = \"${WORKDIR}/git\"",
    "",
    "do_myp() {",
    "    rm -rf ${S}",
    "    cp -a ${WORKDIR}${_MOV_PATH_BY_GEN_} ${S}",
    "    rm -rf ${WORKDIR}/home",
    "}",
    "addtask myp before do_patch after do_unpack",
]

TEMPLATE2=[
    "do_mypatch() {",
    "    cd ${S}",
    "    ${_PATCH_FILE_BY_GEN_}",
    "}",
    "addtask mypatch after do_patch",
]

TEMPLATE_SRC_URI="SRC_URI=\"file://${_SRC_PATH_BY_GEN_}\""

###  ---------------------------------------------------------------------------------------------------------------------------------------------------
###  ------------------------------------------------------------------ Usage --------------------------------------------------------------------------
###  ---------------------------------------------------------------------------------------------------------------------------------------------------
###  {bbappend file name : [[real src path, recipes location, /tmp/work/.../buildpath location], [patch file name]]}
###  ex)) 's5p6818-avn-ref-bl1.bbappend': ['OFF',['/bl1/bl1-s5p6818',R_BL1,'/bl1-s5p6818'], ['0001-s5p6818-avn-bl1.patch']],
###                    |                     |              |           |     |                      '--->> .patch file of bl1 recipe
###                    |                     |              |           |     '--->> /tmp/work/.../s5p6818-avn-ref-bl1/.../ src dir after copy .bbappend
###                    |                     |              |           '--->> meta-nexell/recipes-bsp/  path
###                    |                     |              '--->> local source path in Your Host PC
###                    |                     '----->> Use local source Yes or No
###                    '----->> This .bbappend file name have to same name .bb file in meta-nexell/recipes-xxx/
###  ---------------------------------------------------------------------------------------------------------------------------------------------------

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

def gen_bbappend_paths(curWorkingPath) :
    bbfilesL = HASH_RECIPENAME_PATH.keys()
    bbfilesL.sort()
    for bbafile in bbfilesL :
        if HASH_RECIPENAME_PATH[bbafile][0]=='ON' :
	    gen_bbappend_files(bbafile, curWorkingPath, HASH_RECIPENAME_PATH[bbafile])

def gen_bbappend_files(bbappendfile,curWorkingPath,hashData) :
    L_PATHS = hashData[INDEX_GEN_PATH]
    L_PATCH_FILES = hashData[INDEX_PATCH]

    BBAPPEND_FILE_PATH = curWorkingPath + PREBUILT_BBAPPEND_PATH + L_PATHS[1] + '/' + bbappendfile

    INTO_BBAPPEND_SRC_PATH = curWorkingPath + L_PATHS[0]  #host PC's local source path
    INTO_BBAPPEND_MOV_PATH = curWorkingPath + L_PATHS[2]  #move to yocto tmp/work path
    INTO_BBAPPEND_PATCH_FILE=""
    print BBAPPEND_FILE_PATH
    f = open(BBAPPEND_FILE_PATH,'w')
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

    f.write("\n_SRC_PATH_BY_GEN_=\""   + INTO_BBAPPEND_SRC_PATH + "\"")
    f.write("\n_MOV_PATH_BY_GEN_=\""   + INTO_BBAPPEND_MOV_PATH + "\"")

    f.close()


def main(arg1):
    gen_bbappend_paths(arg1)

if __name__ == "__main__":
    try :
        main(sys.argv[1])
    finally :
        pass
						   
