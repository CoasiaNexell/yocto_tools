#!/usr/bin/env python
#
import sys
import os
import fileinput

def optee_build_setup(socname,machineName,meta_nexell_path) :
    OPTEE_BUILD_BB_FILE = meta_nexell_path+"/recipes-bsp/optee/optee-build_git.bb"

    temp0 = "OPTEE_BUILD_TARGET_SOCNAME=\""+socname+"\""
    temp1 = "OPTEE_BUILD_TARGET_MACHINE=\""+machineName+"\""

    os.system('sed -i "/OPTEE_BUILD_TARGET_SOCNAME=/d" ' + OPTEE_BUILD_BB_FILE)
    os.system('sed -i "/OPTEE_BUILD_TARGET_MACHINE=/d" ' + OPTEE_BUILD_BB_FILE)
    f = open(OPTEE_BUILD_BB_FILE,'a')
    f.write(temp0)
    f.write("\n")
    f.write(temp1)
    f.close()
    #    for line in fileinput.input(OPTEE_BUILD_BB_FILE, inplace = 1):
    #        print line.replace("OPTEE_BUILD_TARGET_MACHINE=\"\"", "OPTEE_BUILD_TARGET_MACHINE=\""+machineName+"\""),

def optee_secure_setup(option,meta_nexell_path) :
    OPTEE_SECURE_INC_FILE = meta_nexell_path + "/recipes-bsp/optee/optee-secure.inc"

    if option == "ON":
        for line in fileinput.input(OPTEE_SECURE_INC_FILE, inplace = 1):
            print line.replace("SECURE-OPTEE=\"SECURE_ON=FALSE\"", "SECURE-OPTEE=\"SECURE_ON=1\""),
    else :
        for line in fileinput.input(OPTEE_SECURE_INC_FILE, inplace = 1):
            print line.replace("SECURE-OPTEE=\"SECURE_ON=TRUE\"", "SECURE-OPTEE=\"SECURE_ON=0\""),

def bl1_secure_setup(option,meta_nexell_path) :
    BL1_SECURE_INC_FILE = meta_nexell_path + "/recipes-bsp/bl1/bl1-secure.inc"

    if option == "ON":
        for line in fileinput.input(BL1_SECURE_INC_FILE, inplace = 1):
            print line.replace("SECURE-BL1=\"SECURE_ON=0\"", "SECURE-BL1=\"SECURE_ON=1\""),
    else :
        for line in fileinput.input(BL1_SECURE_INC_FILE, inplace = 1):
            print line.replace("SECURE-BL1=\"SECURE_ON=1\"", "SECURE-BL1=\"SECURE_ON=0\""),

def main(arg1,arg2,arg3,arg4):
#    optee_build_setup(arg2,arg3,arg4)
    optee_secure_setup(arg1,arg4)
    bl1_secure_setup(arg1,arg4)

if __name__ == "__main__":
    try :
        main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
    finally :
        pass
