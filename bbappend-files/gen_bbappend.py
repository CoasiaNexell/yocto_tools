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
R_GRAPHICS_XORG='/recipes-graphics/xorg-driver'
R_QTAPPS='/recipes-qt/nexell-apps'

TEMPLATE1=[
    "### Nexell - For Yocto build with using local source, Below lines are auto generated codes",
    "",
    "S = \"${WORKDIR}/git\"",
    "",
    "do_myp() {",
    "    rm -rf ${S}",
    "    cp -a ${WORKDIR}${_SRC_PATH_BY_GEN_} ${S}",
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

TEMPLATE_KERNEL=[
    "### Nexell - For Yocto build with using local source, Below lines are auto generated codes",
    "",
    "S = \"${WORKDIR}/git\"",
    "B = \"${S}\"",
    "",
    "do_externalKenelSrcUsing() {",
    "    cd ${WORKDIR}",
    "    rm -rf git",
    "    ln -sf ${_SRC_PATH_BY_GEN_} git",
    "",
    "    cd ${TMPDIR}/work-shared",
    "    if [ ! -d ${COMPATIBLE_MACHINE} ];then ",
    "        mkdir ${COMPATIBLE_MACHINE}",
    "    fi",
    "    cd ${COMPATIBLE_MACHINE}",
    "    rm -rf kernel-source",
    "    ln -sf ${S} kernel-source",
    "}",
    "addtask externalKenelSrcUsing before do_kernel_configme after do_unpack",
    "",
    "do_fetch() {",
    "    :",
    "}",
    "do_unpack() {",
    "    :",
    "}",
    "do_kernel_checkout() {",
    "    :",
    "}",
    "do_validate_branches() {",
    "    :",
    "}",
    "do_patch() {",
    "    :",
    "}",
    "do_kernel_configme() {",
    "    :",
    "}",
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
    's5p4418-avn-ref-bl1.bbappend':         ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],
    's5p4418-navi-ref-bl1.bbappend':        ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],
    's5p6818-artik710-raptor-bl1.bbappend': ['ON',['/bl1/bl1-s5p6818',R_BL1,'/bl1-s5p6818'], []],
    's5p6818-avn-ref-bl1.bbappend':         ['ON',['/bl1/bl1-s5p6818',R_BL1,'/bl1-s5p6818'], []],
    's5p4418-smart-voice-bl1.bbappend':     ['ON',['/bl1/bl1-s5p4418',R_BL1,'/bl1-s5p4418'], []],

    'arm-trusted-firmware_%.bbappend':      ['ON',['/secure/arm-trusted-firmware','/recipes-bsp/arm-trusted-firmware','/arm-trusted-firmware'],[]],

    'l-loader_%.bbappend':                  ['ON',['/secure/l-loader','/recipes-bsp/l-loader','/l-loader'],[]],

    'optee-build_%.bbappend':      ['ON',['/secure/optee/optee_build',R_OPTEE,'/secure/optee_build'],    ['0001-optee-build-customize-for-yocto.patch']],
    'optee-client_%.bbappend':     ['ON',['/secure/optee/optee_client',R_OPTEE,'/secure/optee_client'],  []],
    'optee-linuxdriver_%.bbappend':['ON',['/secure/optee/optee_linuxdriver',R_OPTEE,'/secure/optee_linuxdriver'],[]],
    'optee-os_%.bbappend':         ['ON',['/secure/optee/optee_os',R_OPTEE,'/secure/optee_os'],          ['0001-optee-os-compile-error-patch.patch']],
    'optee-test_%.bbappend':       ['ON',['/secure/optee/optee_test',R_OPTEE,'/secure/optee_test'],      []],

    's5p4418-avn-ref-uboot_%.bbappend':         ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p4418-navi-ref-uboot_%.bbappend':        ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p6818-artik710-raptor-uboot_%.bbappend': ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p6818-avn-ref-uboot_%.bbappend':         ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],
    's5p4418-smart-voice-uboot_%.bbappend':     ['ON',['/u-boot/u-boot-2016.01',R_UBOOT,'/u-boot-2016.01'],[]],

    'gst-plugins-camera_%.bbappend':    ['ON',['/library/gst-plugins-camera',R_GST_LIBS,'/gst-plugins-camera'],[]],
    'gst-plugins-renderer_%.bbappend':  ['ON',['/library/gst-plugins-renderer',R_GST_LIBS,'/gst-plugins-renderer'],[]],
    'gst-plugins-scaler_%.bbappend':    ['ON',['/library/gst-plugins-scaler',R_GST_LIBS,'/gst-plugins-scaler'],[]],

    'libdrm-nx_%.bbappend':             ['ON',['/library/libdrm',R_NX_LIBS,'/libdrm'],[]],
    'nx-drm-allocator_%.bbappend':      ['ON',['/library/nx-drm-allocator',R_NX_LIBS,'/nx-drm-allocator'],[]],
    'nx-gst-meta_%.bbappend':           ['ON',['/library/nx-gst-meta',R_NX_LIBS,'/nx-gst-meta'],[]],
    'nx-renderer_%.bbappend':           ['ON',['/library/nx-renderer',R_NX_LIBS,'/nx-renderer'],[]],
    'nx-scaler_%.bbappend':             ['ON',['/library/nx-scaler',R_NX_LIBS,'/nx-scaler'],[]],
    'nx-v4l2_%.bbappend':               ['ON',['/library/nx-v4l2',R_NX_LIBS,'/nx-v4l2'],[]],
    'nx-video-api_%.bbappend':          ['ON',['/library/nx-video-api',R_NX_LIBS,'/nx-video-api'],['0001-nx-video-api-install-error-fix.patch']],

    'linux-s5p4418-avn-ref_%.bbappend':     ['ON',['/kernel/kernel-${LINUX_VERSION}',R_KERNEL,'/kernel-${LINUX_VERSION}'],[]],
    'linux-s5p4418-navi-ref_%.bbappend':    ['ON',['/kernel/kernel-${LINUX_VERSION}',R_KERNEL,'/kernel-${LINUX_VERSION}'],[]],
    'linux-s5p6818-artik710-raptor_%.bbappend': ['ON',['/kernel/kernel-${LINUX_VERSION}',R_KERNEL,'/kernel-${LINUX_VERSION}'],[]],
    'linux-s5p6818-avn-ref_%.bbappend':         ['ON',['/kernel/kernel-${LINUX_VERSION}',R_KERNEL,'/kernel-${LINUX_VERSION}'],[]],
    'linux-s5p4418-smart-voice_%.bbappend':     ['ON',['/kernel/kernel-${LINUX_VERSION}',R_KERNEL,'/kernel-${LINUX_VERSION}'],[]],

    'testsuite-s5p6818_%.bbappend' :            ['ON',['/apps/testsuite',R_TESTSUITE,'/testsuite'],[]],
    'testsuite-s5p4418_%.bbappend' :            ['ON',['/apps/testsuite',R_TESTSUITE,'/testsuite'],[]],

    'xf86-video-armsoc-nexell_%.bbappend' :     ['ON',['/library/xf86-video-armsoc',R_GRAPHICS_XORG,'/xf86-video-armsoc'],[]],

	'NxAudioPlayer_%.bbappend' :     ['ON',['/apps/QT/NxAudioPlayer',R_QTAPPS,'/apps/QT/NxAudioPlayer'],[]],
    'NxQuickRearCam_%.bbappend' :     ['ON',['/apps/QT/NxQuickRearCam',R_QTAPPS,'/apps/QT/NxQuickRearCam'],[]],
    'NxVideoPlayer_%.bbappend' :     ['ON',['/apps/QT/NxVideoPlayer',R_QTAPPS,'/apps/QT/NxVideoPlayer'],[]],
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
    print BBAPPEND_FILE_PATH + "  ---> OK "
    f = open(BBAPPEND_FILE_PATH,'w')

    #kernel
    if L_PATHS[1]==R_KERNEL :
        for patch in L_PATCH_FILES :
            kernel_patch_copy(curWorkingPath+"/yocto/meta-nexell"+R_KERNEL+"/files/"+patch, INTO_BBAPPEND_SRC_PATH)

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

    f.write("\n_SRC_PATH_BY_GEN_=\""   + INTO_BBAPPEND_SRC_PATH + "\"")
    f.write("\n_MOV_PATH_BY_GEN_=\""   + INTO_BBAPPEND_MOV_PATH + "\"")

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
						   
