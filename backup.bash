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


# FILENAME:  backup


# necessary loading. DO NOT MODIFY
source config_slurm.bash

# script vars. DO NOT MODIFY
FLAG=false
TAR=false
TMUX=false
filecnt=0
TAR_PATH=/scratch/${CLUSTER}/${USER}/

# system paths. DO NOT MODIFY
LARGE_FILE_PATH=/home/${USER}/largeFiles/
ARCHIVE_PATH=/home/${USER}/archives/

# system directives. DO NOT MODIFY
shopt -s nullglob

# usage help message
usage() {
	echo -e "Script to backup files to Fortress tape archive\n"
	echo -e "[${yellow}WARNING${nc}]: Fortress is a tape archive and works best with a few, large files. Large sets of small files should be compressed into archives with utilities such as htar"
	echo "usage: $0 [-h] [-t FILE_TYPE] [-d DEST_DIR] [-n TAR_FILE_NAME] [-p OVERRIDE_PATH] SRC_FILES" 1>&2;
	echo "-h: Display help message"
	echo -e "-t FILE_TYPE: Type of file to be transferred to Fortress.\n\tExpected values:\n\t'a': File type archive\n\t'd': Filte type directory\n\t'f': All other file types\n\tDefaults to 'a'"
	echo "-d DEST_DIR: Name of the backup destination directory."
	echo "-n TAR_FILE_NAME: Name of the backup tar file. Defaults to 'archive.tar'"
	echo -e "-p OVERRIDE_PATH: Override path to destination dir on Fortress.\n\t[${yellow}WARNING${nc}] Only use this arg if you know what you are doing!"
	echo "SRC_FILES: Absolute path of the file(s) to be backed up. This is a REQUIRED argument"
	exit 1;
}

# arg init
FILE_TYPE=a
DEST_DIR=""
OVERRIDE_PATH=""
TAR_FILE="archive.tar"
SRC_FILES=""

# read args
while getopts "ht:d:n:p:" opts; do
	case "${opts}" in
		h)	usage;;
		t)	FILE_TYPE=$OPTARG;;
		d)  DEST_DIR=$OPTARG;;
		n)	TAR_FILE=$OPTARG;;
		p)	OVERRIDE_PATH=$OPTARG;;
		*)	usage;;
	esac
done

# read all filenames to be backed up
shift $(( OPTIND - 1 ))
SRC_FILES=$@
echo "src files: ${SRC_FILES}"

# resolve destination path
if [[ ! $OVERRIDE_PATH == "" ]]; then
	DEST_PATH=$OVERRIDE_PATH
elif [[ $FILE_TYPE == "a" ]]; then
	DEST_PATH=/home/${USER}/archives
	[[ $DEST_DIR ]] && DEST_PATH+="/"${DEST_DIR} || DEST_PATH=$DEST_PATH
else
	DEST_PATH=/home/${USER}/largeFiles
	[[ $DEST_DIR ]] && DEST_PATH+="/"${DEST_DIR} || DEST_PATH=$DEST_PATH
fi

# sanity checks
# check if keytab exists
if [ ! -f $HOME/.private/hpss.unix.keytab ]; then
	echo -e "[${red}FATAL${nc}] ${red}Fortress keytab not found.${nc} Please generate and/or copy the keytab into your system using instructions provided here:\n\n\thttps://www.rcac.purdue.edu/index.php/knowledge/fortress/accounts#login_amp_keytabs\n"
	exit 1
fi

# idiot-proof source file specification
if [[ $SRC_FILES == "" ]]; then
	echo -e "[${red}FATAL${nc}] $0: Did not specify file to be backed up"
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

# if backing up dir, tar by default!
if [[ $FILE_TYPE != "f" ]]; then
	TAR=true
else
	# perf constraint. tar file for user if they can't
	echo -e "[${yellow}WARNING${nc}]: ${yellow}Fortress is a tape archive and works best with a few, large files. Large sets of small files should be compressed into archives with utilities such as htar${nc}"
	read -p "Are you attempting to transfer several small files? (y/n): " confirm && [[ $confirm == [nN] || $confirm == [nN][oO] ]] || FLAG=true
	if $FLAG; then
		echo -e "[${yellow}WARNING${nc}] Transferring several small files may significantly impact backup performance"
		read -p "$( echo -e "["${green}"INFO"${nc}"] Would you like to tar the files before backup? (y/n): ")" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || TAR=true
		if $TAR; then
			echo -e "[${red}FATAL${nc}] Please read the warning message and try again. Aborting transfer..."
			exit 1
		else
			TAR=true
		fi
	fi
fi

# count number of files to be tarred
let filecnt=$(grep -o '.tar' <<< "$SRC_FILES" | wc -l)

# perform sftp txn
if [[ $FILE_TYPE != "f" ]] || [[ $TAR ]]; then
	if [[ $DEST_PATH != "/home/${USER}" ]]; then
		htar_large -cf ${DEST_PATH}/${TAR_FILE} $SRC_FILES
	else
		read -p "$( echo -e "["${yellow}"WARNING"${nc}"] Passwordless backup can not used when backing up files directly into the home directory. Continue? (y/n) ")" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || FLAG=true
		if $FLAG; then
			echo -e "[${red}FATAL${nc}] Can not use passwordless auth for backing up into home directory!"
		else
			tar -cf ${TAR_PATH}/${TAR_FILE} $SRC_FILES
			sftp ${USER}@sftp.fortress.rcac.purdue.edu <<EOF
			put -P ${TAR_PATH}/${TAR_FILE} $DEST_PATH
			exit
EOF
		fi
	fi
else
	files=($SRC_FILES)
	sftp ${USER}@sftp.fortress.rcac.purdue.edu <<EOF
	$(for f in "${files[@]}"; do echo "put -P $f $DEST_PATH"; done)
	exit
EOF
fi

# cleanup
echo -ne "[${green}INFO${nc}] Cleaning up...\t"
rm -f ${TAR_PATH}/${TAR_FILE}
echo -e "[${green}DONE${nc}]"
