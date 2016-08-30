# -*- coding: utf-8 -*-
"""
Created on Fri Aug 26 16:11:21 2016

@author: choonghyun.jeon; suker@nexell.co.kr
"""

import sys
import os
import subprocess
import glob

_prompt_ = " > YOCTO_BUILD > "
commandDict = {'q':'QUIT', 'quit':'QUIT', 'exit':'QUIT', 'y':'YES','yes':'YES', 'n':'NO','no':'NO','c':'CLEAN','clean':'CLEAN'}

selectedWorkingSpace = None

options_user_input = []

linuxMark = '/'
winMark = '\\'
    
promptColors={"BOLD":"\033[1m",
              "BACKGROUND":"\033[7m",
              "YELLOW":"\033[33m",
              "LIGHT_YELLOW":"\033[1;33m",
              "GREEN":"\033[32m",
              "LIGHT_GREEN":"\033[1;32m",
              "RED":"\033[31m",
              "LIGHT_RED":"\033[1;31m",
              "CYAN":"\033[36m",
              "LIGHT_CYAN":"\033[1;36m",
              "RED_BLINK":"\033[5;31m",
              "ENDC":"\033[0m"}

_DebugMarkStr_ = "suker Debug ==> "
_InfoMarkStr_ = " ** ==> "

class mainScript :    
    def __init__(self, path1, path2, mn, it) :
        self.thisScriptPath = path1
        self.workingPath = path2
        self.machine_name = mn
        self.image_type = it
        self.root_path = self.workingPath
        self.yocto_path = self.root_path + linuxMark + "yocto"
        self.meta_nexell_path = self.yocto_path + linuxMark + "meta-nexell"
        self.update_paths()
        
    def update_paths(self) :        
        self.build_path = self.yocto_path + linuxMark + "build-" + self.machine_name + "-" + self.image_type
        self.result_path = self.yocto_path + linuxMark + "result-" + self.machine_name + "-" + self.image_type
        
    def yes(self,msg) :
        print "    "+promptColors["GREEN"]+"'y' or 'yes' "+promptColors["ENDC"]+" --> " + promptColors["RED_BLINK"] + msg + promptColors["ENDC"]
    def no(self) :
        print "    "+promptColors["GREEN"]+"'n' or 'no' "+promptColors["ENDC"]+" --> Change MachineName and Image Type"
    def optee_clean(self) :
        print "    "+promptColors["GREEN"]+"'c' or 'clean' "+promptColors["ENDC"]+" --> cleansstate ATF & optee : s5p6818 only!"
    def quit_exit(self) :
        print "    "+promptColors["GREEN"]+"'q' or 'exit' or 'quit' "+promptColors["ENDC"]+" --> Quit this script"

    def build_infos(self) :
        print promptColors["LIGHT_RED"]+" Build Info "+promptColors["ENDC"]
        print "    "+promptColors["YELLOW"] + "MACHINE_NAME => " + self.machine_name + promptColors["ENDC"]    
        print "    "+promptColors["YELLOW"] + "IMAGE_TYPE => "   + self.image_type + promptColors["ENDC"]
        print "    "+promptColors["YELLOW"]+_InfoMarkStr_+"script Path "+promptColors["ENDC"] +promptColors["LIGHT_CYAN"]+self.thisScriptPath+promptColors["ENDC"]
        print "    "+promptColors["YELLOW"]+_InfoMarkStr_+"working Path "+promptColors["ENDC"] +promptColors["LIGHT_CYAN"]+self.workingPath+promptColors["ENDC"]
        print "    "+promptColors["YELLOW"]+_InfoMarkStr_+"build Path "+promptColors["ENDC"] +promptColors["LIGHT_CYAN"]+"build-"+self.build_path + promptColors["ENDC"]
        print "    "+promptColors["YELLOW"]+_InfoMarkStr_+"result Path "+promptColors["ENDC"] +promptColors["LIGHT_CYAN"]+"result-"+self.result_path + promptColors["ENDC"]

    def change_machine_name(self) :
        print "================================================================"
        print promptColors["CYAN"]+"Input MACHINE NAME AND IMAGE TYPE  : "+promptColors["ENDC"] # + promptColors["LIGHT_RED"]+""+promptColors["ENDC"]
        print "    "+promptColors["GREEN"] + "CURRENT MACHINE_NAME => " + self.machine_name + promptColors["ENDC"]
        print "    "+promptColors["GREEN"] + "CURRENT IMAGE_TYPE => "   + self.image_type + promptColors["ENDC"]
        print "================================================================\n"

    def check_machine_name(self) :
        print "================================================================"
        print promptColors["CYAN"]+"This is a build script : "+promptColors["ENDC"] # + promptColors["LIGHT_RED"]+""+promptColors["ENDC"]
        print "================================================================"
        self.build_infos()
        print "================================================================"
        print promptColors["CYAN"]+"Input your command : "+promptColors["ENDC"] # + promptColors["LIGHT_RED"]+""+promptColors["ENDC"]
        self.yes("Build Start !!")
        self.no()
        self.optee_clean()
        self.quit_exit()
        print "================================================================\n"
        
    def check_update(self) :
        print "================================================================"
        print promptColors["CYAN"]+"This is a update script : "+promptColors["ENDC"] # + promptColors["LIGHT_RED"]+""+promptColors["ENDC"]
        print "================================================================"
        self.build_infos()
        print "    "+promptColors["GREEN"] + "RESULT_PATH => " + self.workingPath+"/yocto/result-"+self.machine_name+"-"+self.image_type + promptColors["ENDC"]
        print ""
        self.yes("Target Board Download now !!")
        self.quit_exit()
        print "================================================================\n"
    
    def buildConversation(self) :
        wSpace = None
    
        while 1 :
            self.check_machine_name()
            wSpace = raw_input(_prompt_).lower()
            if wSpace in commandDict.keys() :
                if commandDict[wSpace]=='QUIT' :
                    print "GoodBye!! \n"
                    sys.exit()
                elif commandDict[wSpace]=='YES' :
                    self.runningScript("build")
                    break
                elif commandDict[wSpace]=='NO' :                    
                    self.userInputMachineName()
                    self.update_paths()
                elif commandDict[wSpace]=='CLEAN' :
                    self.runningScript("opteeClean")
                    break
                else :
                    break
               
    
    def updateConversation(self) :
        wSpace = None
        while 1 :
            self.check_update()
            wSpace = raw_input(_prompt_).lower()
            if wSpace in commandDict.keys() :
                if commandDict[wSpace]=='QUIT' :
                    print "GoodBye!! \n"
                    sys.exit()
                elif commandDict[wSpace]=='YES' :
                    self.runningScript("update")
                    self.complete_msg()
                    break
                elif commandDict[wSpace]=='NO' :
                    print "GoodBye!! \n"
                    sys.exit()
                else :
                    pass

    def userInputMachineName(self) :
        self.change_machine_name()
        mnStr = raw_input(_prompt_+" NEW MACHINE_NAME => ").lower()
        itStr = raw_input(_prompt_+" NEW IMAGE_TYPE   => ").lower()
        self.machine_name = mnStr
        self.image_type = itStr
        print "complete "
        
    def runningScript(self, command) :
        if command=="build" :
            os.chdir(self.root_path+"/tools/bbappend-files")
            os.system("./gen_bbappend.sh " + self.root_path)
            os.system("cp -a " + self.root_path + "/tools/bbappend-files/* " + self.meta_nexell_path)

            os.chdir(self.thisScriptPath)
            os.system("./source_env_bitbake.sh " + self.machine_name + " " + self.image_type + " " + self.yocto_path)

            os.chdir(self.build_path)
            os.system("../meta-nexell/tools/result-file-move.sh " + self.machine_name + " " + self.image_type)
            os.chdir(self.result_path)
            os.system("../meta-nexell/tools/convert_images.sh " + self.machine_name + " " + self.image_type)
            
        elif command=="opteeClean" :
            os.chdir(self.build_path)
            if self.machine_name == "s5p6818-artik710-raptor" :
                os.system("../optee_clean_artik7.sh")
            elif self.machine_name == "s5p6818-avn-ref" :
                os.system("../optee_clean_avn.sh")
            else :
                print "Optee Clean does not necessary or This is a first build ~~"            

        elif command=="update" :
            updatescript = ""
            if "s5p6818" in self.machine_name :
                updatescript = "update_s5p6818.sh"
            elif "s5p4418" in self.machine_name :
                updatescript = "update_s5p4418.sh"
            else :
                return

            os.chdir(self.root_path)
            os.system("./yocto/meta-nexell/tools/" + updatescript + " -p " + self.result_path + "/partmap_emmc.txt -r " + self.result_path)
        else :
            pass

    def bash_commands(self, runpath, commands) :
        excuteCommand = 'bash'
        os.chdir(runpath)
        for i in commands :
            try :
                out_bytes = subprocess.call([excuteCommand,i])
            except subprocess.CalledProcessError as e:
                out_bytes = e.output
                code = e.returncode
                print out_bytes, code

    def complete_msg(self) :
        print "================================================================"
        print promptColors["LIGHT_RED"] + "    Target Download Complete !!     " + promptColors["ENDC"]
        print "================================================================\n"
        
def main(machine_name,image_type):
    suker = mainScript(os.path.dirname(os.path.abspath(__file__)), os.getcwd(), machine_name, image_type)
#    print _DebugMarkStr_+os.path.dirname(os.path.abspath(__file__))
#    print _DebugMarkStr_+__file__
    suker.buildConversation()
    suker.updateConversation()
    
if __name__ == "__main__":
    try :         
        main(sys.argv[1],sys.argv[2])
    finally : 
        pass
