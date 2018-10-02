#!/usr/bin/env python
#

import sys
import subprocess
import fileinput
import os

YOCTO_POKY = ['poky', '/yocto/poky']
YOCTO_META_OE = ['meta-openembedded', '/yocto/meta-openembedded']
YOCTO_OE_CORE = ['openembedded-core', '/yocto/openembedded-core']

YOCTO_COMPONENTS = [
 YOCTO_POKY,
 YOCTO_META_OE,
 YOCTO_OE_CORE,
]

class YoctoBranchCheck:
    def __init__(self, rootPath, txtFile):
        self.rootPath = os.path.abspath(rootPath)
        self.txtFile = os.path.abspath(txtFile)

    def writeBranchInfo(self):
        values=[]

        with open(self.txtFile,'a') as f :
            for component in YOCTO_COMPONENTS :
                os.chdir(self.rootPath + component[1])

                output=subprocess.check_output('git branch',shell=True)
                values = output.split('\n')
                for i in values:
                    if '*' in i :
                        f.write(component[0] + " - " + i.split(' ')[1] + "\n")

def main(rootPath, txtFile):
    ybc = YoctoBranchCheck(rootPath, txtFile)
    ybc.writeBranchInfo()

if __name__ == "__main__":
    try :
        #root path, .txt name
        main(sys.argv[1], sys.argv[2])
    finally :
        pass
