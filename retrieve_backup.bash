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


# FILENAME:  retrieve_backup


# script vars. DO NOT MODIFY
TAR=false
TMUX=false
filecnt=0
TAR_PATH=$(pwd)

# system paths. DO NOT MODIFY
LARGE_FILE_PATH=/home/${USER}/largeFiles/
ARCHIVE_PATH=/home/${USER}/archives/

# system directives. DO NOT MODIFY
shopt -s nullglob

# necessary loading. DO NOT MODIFY
source config_slurm.bash

# usage help message
usage() {
	echo -e "Script to retrieve backup files from Fortress tape archive"
	echo -e "[${yellow}WARNING${nc}]: Fortress is a tape archive. Recovering files from FORTRESS can, therefore, take a very long time."
	echo "usage: $0 [-h] [-t FILE_TYPE] [-d SRC_DIR] [-n DEST_DIR] SRC_FILES" 1>&2;
	echo "-h: Display help message"
	echo -e "-t FILE_TYPE: Type of file to be retrieved from Fortress.\n\tExpected values:\n\t'a': File type archive\n\t'f': All other file types\n\tDefaults to 'a'"
	echo "-d SRC_DIR: Path of the backup to be retrieved, relative to the archives/ or largeFiles/ directory"
	echo "-n DEST_DIR: Absolute path of the retrived backup's destination directory. Defaults to  /scratch/${CLUSTER}/${USER}"
	echo "SRC_FILES: Files to be retrieved from FORTRESS. This is a REQUIRED argument"
	exit 1;
}

# arg init
FILE_TYPE=a
SRC_DIR=""
DEST_DIR="/scratch/${CLUSTER}/${USER}"
TAR_FILE="archive.tar"
SRC_FILES=""

# read args
while getopts "ht:d:n:" opts; do
	case "${opts}" in
		h)	usage;;
		t)	FILE_TYPE=$OPTARG;;
		d)  SRC_DIR=$OPTARG;;
		n)	TAR_FILE=$OPTARG;;
		*)	usage;;
	esac
done

# read all filenames to be backed up
shift $(( OPTIND - 1 ))
SRC_FILES=$@

# resolve destination path
if [[ $FILE_TYPE == "a" ]]; then
	SRC_PATH=/home/${USER}/archives/${SRC_DIR}
else
	SRC_PATH=/home/${USER}/largeFiles/${SRC_DIR}
fi

# sanity checks
# check if keytab exists
if [ ! -f $HOME/.private/hpss.unix.keytab ]; then
	echo -e "[${red}FATAL${nc}] ${red}Fortress keytab not found.${nc} Please generate and/or copy the keytab into your system using instructions provided here:\n\n\thttps://www.rcac.purdue.edu/index.php/knowledge/fortress/accounts#login_amp_keytabs\n"
	exit 1
fi

# idiot-proof source file specification
if [[ $SRC_FILES == "" ]]; then
	echo -e "[${red}FATAL${nc}] $0: Did not specify file to retrieve"
	exit 1
fi

# idiot-proof tar file name
if [[ $TAR_FILE != *".tar" ]]; then
	TAR_FILE=${TAR_FILE}.tar
fi

# make user run script in tmux session to prevent productivity loss
read -p "$( echo -e "[${green}INFO${nc}] This script may take a long time to complete. Are you running in a tmux session? (y/n): ")" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || TMUX=true
if $TMUX; then
	echo -e "[${yellow}WARNING${nc}] Do not run this script outside tmux!"
	exit
fi

# retrieve files over sftp
files=($SRC_FILES)
sftp ${USER}@sftp.fortress.rcac.purdue.edu <<EOF
$(for f in "${files[@]}"; do echo "get -P ${SRC_PATH}$f $DEST_DIR"; done)
exit
EOF

# auto untarring
if [[ $FILE_TYPE -eq "a" ]]; then
	read -p "$( echo -e "["${green}"INFO"${nc}"] Would you like to untar the retrieved files? (y/n): ")" confirm && [[ $confirm == [nN] || $confirm == [nN][oO] ]] || TAR=true
	if $TAR; then
		echo -ne "[${green}INFO${nc}] Untarring...\t\t\t"
		files=($SRC_FILES)
		cd $DEST_DIR
		for f in "${files[@]}"; do
			tar -xf ${f} -C $DEST_DIR
		done
		echo -e "[${green}DONE${nc}]"
		# path and file cleanup
		echo -ne "[${green}INFO${nc}] Cleaning up...\t\t"
		mv ./$DEST_DIR/* ./
		rm -rf ./$(echo $DEST_DIR | cut -c 2- | awk -F '/' '{print $1}')
		rm -f ./$SRC_FILES
		echo -e "[${green}DONE${nc}]"
	fi
fi