#!/bin/bash

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


# FILENAME:  conda_env_installer

# necessary loading. DO NOT MODIFY
source config_rcac.bash

# system constants. DO NOT MODIFY
USER=$(whoami)
FLAG=false

# usage help message
usage() {
	echo "usage: $0 [-h] [-R] [-f YML_FILENAME] [-p YML_PATH] [-n ENV_NAME] [-P RQMT_TXT_FILE]" 1>&2;
	echo "-h: Display help message"
    echo "-R: Re-install env from default yml loaction"
	echo "-f YML_FILENAME: Name of env yml file. Defaults to 'environment.yml'"
    echo "-p YML_PATH: Path to yml file. Defaults to '${HOME}/rcac-utils'"
    echo "-n ENV_NAME: Name of env to be created. Defaults to 'environment'"
    echo "-P RQMT_TXT_FILENAME: File with absolute path to requirements.txt file"
	exit 1;
}

# arg init
YML_FILENAME=environment.yml
YML_PATH=$HOME/rcac-utils
ENV_NAME=environment
REINSTALL=""
PIP_FILE=""

# read args
while getopts "hf:p:n:RP:" opts; do
	case "${opts}" in
		h)	usage;;
		f)	YML_FILENAME=$OPTARG;;
        p)  YML_PATH=$OPTARG;;
        n)  ENV_NAME=$OPTARG;;
        R)  REINSTALL="true";;
        P)  PIP_FILE=$OPTARG;;
		*)	usage;;
	esac
done

# navigate to home dir
cd $HOME

if [ -d "anaconda3" ]; then
    read -p " $( echo -e "[${yellow}WARNING${nc}] Anaconda installation found! This conflicts with Lmod module conda and causes job failures. Should it be deleted? (y/n) ")" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || FLAG=true
    if $FLAG; then
        exit 1
    fi
    # remove custom anaconda dir
    rm -rf $HOME/anaconda3/
    # remove old conda installation scripts (if any)
    rm -f $HOME/Anaconda*.bash
fi

# import lmod conda module
module load conda
# import lmod cuda module to ensure the correct version of pytorch gets installed
module load cuda
# import lmod pip module
module load pip

# ensure conda install dir is in scratch
if [ ! -d "/scratch/${CLUSTER}/${USER}/.conda" ]; then
    echo -e "[${red}FATAL${nc}] Default conda install dir not in scratch! Re-run setup.bash"
    exit 1
fi

# set default paths if new conda location exists but isn't pointed to
if ! grep -q "/scratch/${CLUSTER}/${USER}/.conda/pkgs" "$HOME/.condarc"; then
    conda config --add pkgs_dirs /scratch/${CLUSTER}/${USER}/.conda/pkgs
    conda config --add envs_dirs /scratch/${CLUSTER}/${USER}/.conda/envs
fi

if [ $REINSTALL ]; then
    YML_PATH=$HOME/ymls
fi

# create env
echo -e "[${yellow}INFO${nc}] Installing env..."
conda env create --prefix /scratch/${CLUSTER}/${USER}/.conda/envs/${ENV_NAME} --file $YML_PATH/${YML_FILENAME}
echo -e "[${green}DONE${nc}]"

if [[ -f "$PIP_FILE" ]]; then
    conda activate $ENV_NAME
    echo -e "[${yellow}INFO${nc}] Installing pip dependencies..."
    pip install $PIP_FILE
    echo -e "[${green}DONE${nc}]"
    conda deactivate
elif [[ $PIP_FILE ]]; then
    echo -e "[${red}FATAL${nc}] Specified pip dependency file not found"
    exit 1
fi
