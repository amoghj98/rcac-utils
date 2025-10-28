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


# script vars. DO NOT MODIFY
FLAG=false

# load module cmd to prevent weird bug experienced by few folks
source /etc/profile.d/modules.sh

#
module purge
module load conda
module load cuda

#
echo -e "Parsing paths...\t"

# verify installation
INSTALL_DIR=$(find $HOME -name rcac-utils)
if [[ ! $INSTALL_DIR == "/home/${USER}/rcac-utils" ]]; then
	echo -ne "[\033[1;33mWARNING\033[0m] Path Error: rcac-utils not installed in /home/${USER}. Moving...\t"
	mv $INSTALL_DIR /home/${USER}
else
	echo -ne "Verifying rcac-utils installation...\t"
fi

# necessary loading. DO NOT MODIFY
source /home/$USER/rcac-utils/config_rcac.bash

echo -e "[${green}DONE${nc}]"

# add rcac-utils to $PATH if not already added
if [[ ! $PATH == *"rcac-utils"* ]]; then
	echo -ne "Setting up paths...\t\t\t"
	echo 'export PATH="/home/'${USER}'/rcac-utils:$PATH"' >> $HOME/.bashrc
	FLAG=true
	echo -e "[${green}DONE${nc}]"
else
	echo -e "[${green}INFO${nc}] rcac-utils already in \$PATH. Nothing to do."
fi

# change default conda dir to prevent home directory from filling up
if [[ ! -d /scratch/${CLUSTER}/${USER}/.conda ]]; then
	echo -ne "Setting up conda directories...\t\t"
	mkdir -p /scratch/${CLUSTER}/${USER}/.conda/pkgs
	mkdir -p /scratch/${CLUSTER}/${USER}/.conda/envs
	conda config --add pkgs_dirs /scratch/${CLUSTER}/${USER}/.conda/pkgs
	conda config --add envs_dirs /scratch/${CLUSTER}/${USER}/.conda/envs
	echo -e "[${green}DONE${nc}]"
else
	echo -e "[${green}INFO${nc}] Directories already set up. Nothing to do."
fi

#
if ! grep -q "CONDA_ENVS_DIRS" $HOME/.bashrc; then
	echo -ne "Adding conda env variables to .bashrc...\t"
	echo '' >> $HOME/.bashrc
	echo 'export CONDARC="/home/'${USER}'/.condarc"' >> $HOME/.bashrc
	echo 'export CONDA_ENVS_DIRS="/scratch/'${CLUSTER}'/'${USER}'/.conda/envs"' >> $HOME/.bashrc
	echo 'export CONDA_PKGS_DIRS="/scratch/'${CLUSTER}'/'${USER}'/.conda/pkgs"' >> $HOME/.bashrc
	echo -e "[${green}DONE${nc}]"
else
	echo -e "[${green}INFO${nc}] Conda env variables already in .bashrc. Nothing to do."
fi

# add auto env export script to crontab
echo -ne "Setting up automatic conda env export...\t\t"
if [[ ! -d $HOME/ymls ]]; then
	mkdir $HOME/ymls
fi
ssh $USER@login01.gautschi.rcac.purdue.edu 'crontab < $HOME/rcac-utils/.crontab'
echo -e "[${green}INFO${nc}] Automatic conda environment export set up. Export will run at 23:45 everyday and YML files will be saved in $HOME/ymls"
echo -e "[${green}DONE${nc}]"

# clean up
echo -ne "Cleaning up...\t\t\t\t"
echo -e "[${green}DONE${nc}]"

if $FLAG; then
	echo -e "[${green}INFO${nc}] User action required: To complete setup, run\n\n\tsource $HOME/.bashrc\n"
fi