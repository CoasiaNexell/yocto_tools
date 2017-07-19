#!/bin/bash

#Essentials: Packages needed to build an image on a headless system:
sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat

#Graphical and Eclipse Plug-In Extras: Packages recommended if the host system has graphics support or  if you are going to use the Eclipse IDE:
sudo apt-get install libsdl1.2-dev xter

#Documentation: Packages needed if you are going to build out the Yocto Project documentation manuals:
#sudo apt-get install make xsltproc docbook-utils fop dblatex xmlto

#SDK Installer Extras: Packages needed if you are going to be using the the standard or extensible SDK:
sudo apt-get install autoconf automake libtool libglib2.0-dev libarchive-dev

#OpenEmbedded Self-Test (oe-selftest): Packages needed if you are going to run oe-selftest:
sudo apt-get install python-git
