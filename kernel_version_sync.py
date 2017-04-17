#!/usr/bin/env python
#

import sys
import os
import fileinput

class KernelVersionSync:
    KERNEL_VERSION = ""
    KERNEL_PATCHLEVEL = ""
    KERNEL_SUBLEVEL = ""
    bbappendPath = ""
    kernelSrcPath = ""

    def __init__(self, bbappendPath, rootPath, kernelDirName):
        self.bbappendPath = bbappendPath
        self.rootPath = rootPath
        self.kernelSrcPath = rootPath+"/kernel/"+kernelDirName
        self.kernelDirName = kernelDirName
        print "ROOT PATH : " + self.rootPath
        print "Kernel PATH : " + self.kernelSrcPath

    def getKernelMakeFile(self) :
        if os.path.exists(self.kernelSrcPath+"/Makefile")==True:
            print "kernel Makefile exist"
            with open(self.kernelSrcPath+"/Makefile") as f :
                for line in f :
                    if len(line) <= 1 :
                        continue

                    if "VERSION" in line and len(self.KERNEL_VERSION)<1 :
                        temp = line.split("=")
                        self.KERNEL_VERSION = temp[-1].lstrip().strip()
                        continue
                    elif "PATCHLEVEL" in line and len(self.KERNEL_PATCHLEVEL)<1 :
                        temp = line.split("=")
                        self.KERNEL_PATCHLEVEL = temp[-1].lstrip().strip()
                        continue
                    elif "SUBLEVEL" in line and len(self.KERNEL_SUBLEVEL)<1 :
                        temp = line.split("=")
                        self.KERNEL_SUBLEVEL = temp[-1].lstrip().strip()
                        continue

                    if len(self.KERNEL_VERSION)>0 and len(self.KERNEL_PATCHLEVEL)>0 and len(self.KERNEL_SUBLEVEL)>0:
                        return
        else:
            print "kernel source check please, No exist Makefile in Kernel Source " + str(path)

    def setBBAPPENDfile(self):
        if os.path.exists(self.bbappendPath)==True:
            print "exist "+self.bbappendPath
            with open(self.bbappendPath,'a') as f :
                linux_version = self.KERNEL_VERSION + "." + self.KERNEL_PATCHLEVEL + "." + self.KERNEL_SUBLEVEL
                print "Linux Kernel VERSION = " + linux_version
                f.write("\nLINUX_VERSION = \"" + linux_version + "\"\n")
                f.write("PV = \"" + linux_version + "\"\n")
                f.write("\n_SRC_PATH_BY_GEN_=\"" + self.kernelSrcPath + "\"")
                f.write("\n_MOV_PATH_BY_GEN_=\"" + self.rootPath + "/" + self.kernelDirName + "\"")
        else:
            print "bbappend file does not exist"

def main(bbappendPath, rootPath, kernelDirName):
    kvs = KernelVersionSync(bbappendPath, rootPath, kernelDirName)
    kvs.getKernelMakeFile()
    kvs.setBBAPPENDfile()

if __name__ == "__main__":
    try :
        main(sys.argv[1], sys.argv[2], sys.argv[3])
    finally :
        pass
