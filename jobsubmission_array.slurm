#!/bin/bash -l

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


# FILENAME:  jobsubmission_array

#SBATCH -A cocosys
#SBATCH --nodes=1 
#SBATCH --time=6:00:00
#SBATCH --job-name=DEFAULT
#SBATCH --array=1-20%5                  # Array range (this creates 20 tasks with IDs from 1 to 20, with max 5 tasks concurrently. Set number of tasks to total number of iterations in loop, 20 in this case)
#SBATCH --gpus-per-node=1
#SBATCH --output=/home/%u/joboutput/%u_%A_%a.log
#SBATCH --error=/home/%u/joboutput/%u_%A_%a.log
#SBATCH --signal=B:USR1@60


# The sbatch comments above are a special kind of comment that act as arguments to the sbatch command unless superceded by cmd-line args in the launch file.
# DO NOT MODIFY THESE SPECIAL COMMENTS

# handle job renaming for default name jobs
if [[ $SLURM_JOB_NAME == "DEFAULT" ]]; then
	scontrol update job=$SLURM_JOB_ID JobName=$(whoami)_$SLURM_JOB_ID
fi

# trap SIGUSR1 coming from sbatch and pass to python script
trap 'sig_handler' SIGUSR1

# Print the hostname of the compute node on which this job is running.
echo -e "Hostname: $(/bin/hostname)\n"

# usage help message
usage() {
	echo "usage: $0 [-h] [-e ENV_NAME] [-t SCRIPT_TYPE] [-d JOB_SCRIPT_DIR] [-f SCRIPT_FILE]" 1>&2;
	echo "-h: Display help message"
	echo "-e ENV_NAME: Name of the script's conda environment. Defaults to 'base'"
	echo "-t SCRIPT_TYPE: Type of script to execute. Supported values: bash, python. Defaults to 'python'"
	echo "-d JOB_SCRIPT_DIR: Absolute path to directory containing the script to be run. Defaults to '${HOME}'"
	echo "-f SCRIPT_FILE: Name of python file to run. Defaults to helloWorld.py"
	exit 1;
}

# arg init
ENV_NAME=base
SCRIPT_DIR=$HOME/rcac-utils
SCRIPT_TYPE=python
SCRIPT_FILE=helloWorld.py

# read args
while getopts "he:t:d:f:" opts; do
	case "${opts}" in
		h)	usage;;
		e)	ENV_NAME=$OPTARG;;
		t)	SCRIPT_TYPE=$OPTARG;;
		d)  SCRIPT_DIR=$OPTARG;;
		f)	SCRIPT_FILE=$OPTARG;;
		*)	usage;;
	esac
done

# necessary init
module purge
module load conda
module load cuda
conda activate $ENV_NAME

# Change to the directory containing job script
cd $SCRIPT_DIR

for SEED in 0 1 2 3;
do
	for LR in {-5..-1..1};
	do
		lr=$(echo 10^$LR | bc -l)
		echo $SEED
		echo $lr
		# actual call to your python script (uncomment the desired version, comment the other one)
		# version 1: simple call, OS signalling from SLURM not implemented
		# $SCRIPT_TYPE $SCRIPT_FILE

		# version 2: better call, OS signalling from SLURM enabled (exception catching and handling left to the user)
		# $SCRIPT_TYPE $SCRIPT_FILE &
		# PID="$!"
		# wait "${PID}"
	done
done
