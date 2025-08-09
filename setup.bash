#!/bin/bash -i

# Copyright (c) 2025, Amogh S. Joshi

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# FILENAME:  setup


# Text colour escape codes. DO NOT MODIFY
white='\033[1;37m'
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
nc='\033[0m'

# script vars. DO NOT MODIFY
FLAG=false


#
CLUSTER=$(echo $(hostname) | cut -d '.' -f 2)
echo -ne "Parsing paths...\t\t\t\t"
if [[ "gautschi" == *"$CLUSTER"* ]]; then
	module purge
	module load conda
	module load cuda
	INSTALL_DIR=$(find $HOME -name rcac-utils)
else
	CLUSTER=$(echo $(hostname) | cut -d '.' -f 1)
	INSTALL_DIR=$(find /home/min/a/${USER} /home/nano01/a/${USER} -name rcac-utils 2>/dev/null)
fi
echo -e "[${green}DONE${nc}]"

# verify installation
echo -ne "Verifying rcac-utils installation...\t\t"

if [[ "gautschi" == *"$CLUSTER"* ]]; then
	if [[ ! $INSTALL_DIR == "/home/${USER}/rcac-utils" ]]; then
		echo -ne "\n[\033[1;33mWARNING\033[0m] Invalid Path spec: rcac-utils not installed in /home/${USER}. Moving...\t"
		mv $INSTALL_DIR /home/${USER}
	fi
	INSTALL_DIR=/home/${USER}
else
	if [[ ! $INSTALL_DIR == "/home/${CLUSTER}/a/${USER}/rcac-utils" ]]; then
		echo -ne "\n[\033[1;33mWARNING\033[0m] Invalid Path spec: rcac-utils not installed in /home/${CLUSTER}/a/${USER}. Moving...\t"
		mv $INSTALL_DIR /home/${CLUSTER}/a/${USER}
	fi
	INSTALL_DIR=/home/${CLUSTER}/a/${USER}
fi

echo -e "[${green}DONE${nc}]"

# necessary loading. DO NOT MODIFY
echo -ne "Loading configs...\t\t\t\t"

source ${INSTALL_DIR}/rcac-utils/config_slurm.bash

echo -e "[${green}DONE${nc}]"

# add rcac-utils to $PATH if not already added
if [[ ! $PATH == *"rcac-utils"* ]]; then
	echo -ne "Setting up paths...\t\t\t\t"
	echo 'export PATH="'${INSTALL_DIR}'/rcac-utils:$PATH"' >> $HOME/.bashrc
	FLAG=true
	echo -e "[${green}DONE${nc}]"
else
	echo -e "[${green}INFO${nc}] rcac-utils already in \$PATH. Nothing to do."
fi

# change default conda dir to prevent home directory from filling up
if [[ "gautschi" == *"$CLUSTER"* ]]; then
	mkdir -p /scratch/${CLUSTER}/${USER}/.conda/pkgs
	mkdir -p /scratch/${CLUSTER}/${USER}/.conda/envs
	conda config --add pkgs_dirs /scratch/${CLUSTER}/${USER}/.conda/pkgs
	conda config --add envs_dirs /scratch/${CLUSTER}/${USER}/.conda/envs
fi

# add auto env export script to crontab
echo -ne "Setting up automatic conda env export...\t"
if [[ ! -d $INSTALL_DIR/ymls ]]; then
	mkdir $INSTALL_DIR/ymls
fi

if [[ "gautschi" == *"$CLUSTER"* ]]; then
	ssh $USER@login01.gautschi.rcac.purdue.edu 'crontab < $HOME/rcac-utils/.crontab'
	echo -e "[${green}INFO${nc}] Automatic conda environment export set up. Export will run at 23:45 everyday and YML files will be saved in $HOME/ymls"
	echo -e "[${green}DONE${nc}]"
else
	crontab < $INSTALL_DIR/rcac-utils/.crontab
fi

echo -e "[${green}DONE${nc}]"

# clean up
echo -ne "Cleaning up...\t\t\t\t\t"
echo -e "[${green}DONE${nc}]"

if $FLAG; then
	echo -e "\n[${green}INFO${nc}] User action required: To complete setup, run\n\n\tsource $HOME/.bashrc\n"
fi