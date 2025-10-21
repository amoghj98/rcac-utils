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


# FILENAME:  joblauncher

# load module cmd to prevent weird bug experienced by few folks
source /etc/profile.d/modules.sh

# necessary imports
source config_rcac.bash

# system constants. DO NOT MODIFY
JOB_FILE_PATH=$CONFIG_PATH
FLAG=false

# notification mail param setup. DO NOT MODIFY
MAIL=""
MAIL_TYPE=BEGIN,END,FAIL,TIME_LIMIT_90

# interactive job flag. DO NOT MODIFY
INTERACTIVE=""

# file name setup
JOB_NAME=""
LOG_PATH="${HOME}/joboutput/"

# usage help message
usage() {
	echo -e "\nusage: $0 [-h] [-j JOB_SUBMISSION_SCRIPT] [-t SCRIPT_TYPE] [-d SCRIPT_DIR] [-f SCRIPT_FILE] [-l LOG_PATH] [-e ENV_NAME] [-n JOB_NAME] [-g N_GPUS] [-c N_CPUS] [-q QUEUE] [-Q QoS] [-p PARTITION] [-T MAX_TIME] [-s SIG_INTERVAL] [-m] [-i]" 1>&2;
	echo -e "-h: Display help message"
	echo -e "-j JOB_SUBMISSION_SCRIPT: Name of job submission script. Defaults to 'jobsubmissionscript.sub'"
	echo -e "-t SCRIPT_TYPE: Type of script to execute. Supported values: bash, python. Defaults to 'python'"
	echo -e "-d SCRIPT_DIR: Absolute path to directory containing the python/other code script to be run. Defaults to '${HOME}/rcac-utils'"
	echo -e "-f SCRIPT_FILE: Name of python file to run. Defaults to helloWorld.py"
	echo -e "-l LOG_PATH: Absolute path to logging directory. Defaults to ${HOME}/joboutput"
	echo -e "-e ENV_NAME: Name of the script's conda environment. Defaults to 'base'" 
	echo -e "-n JOB_NAME: Name of the job. Defaults to ${USER}_%j, where %j is the job number"
	echo -e "-g N_GPUS: Number of GPU cards required. Defaults to 1"
	echo -e "-c N_CPUS: Number of CPUs required. Defaults to 14.\n\t[${yellow}WARNING${nc}] Gautschi restricts N_CPUS to 14 per requested GPU. Supply this arg accordingly"
	echo -e "-q QUEUE: SLURM queue to launch job on. Supported values: kaushik, cocosys. Defaults to 'cocosys'"
	echo -e "-Q QoS: Quality-of-Service to be associated with the job. Supported values: normal, preemptible. Defaults to 'normal'"
	echo -e "-p PARTITION: Name of partition to run on. Defaults to 'cocosys'"
	echo -e "-T MAX_TIME: Max job time. After executing for this much time, the job is killed.\n\tSpecify in dd-hh:mm:ss format. Defaults to 6:00:00 (6 hrs)"
	echo -e "-s SIG_INTERVAL: SIGUSR1 is sent to the user script these many seconds before MAX_TIME is reached. Supported values: [0, 65535]. Defaults to 60.\n\t[${yellow}WARNING${nc}] Handling of OS signal is left to the user"
	echo -e "-m: Email notification flag. If set, sends email notification on job start, end, fail, and upon reaching 90% of specified job time limit"
	echo -e "-i: Interactive Job Flag. If set, the requested resource set is allocated in interactive fashion. Allows for the spawning of multiple jobs on the same hardware resources\n\t[${yellow}WARNING${nc}] Setting this flag causes all arguments except the resource requesting arguments to be ignored."
	exit 1;
}

# arg init
N_GPUS=1
N_CPUS=14
PARTITION=cocosys
QOS_LEVEL=normal
MAX_TIME=6:00:00
ENV_NAME=base
JOB_SUBMISSION_SCRIPT=jobsubmissionscript.sub
SCRIPT_TYPE=python
SCRIPT_DIR=$HOME/rcac-utils
SCRIPT_FILE=helloWorld.py
SIG_INTERVAL=60

# read args
while getopts "hj:t:d:f:l:e:n:g:c:q:Q:p:T:s:mi" opts; do
	case "${opts}" in
		h)	usage;;
		j)	JOB_SUBMISSION_SCRIPT=$OPTARG;;
		t)	SCRIPT_TYPE=$OPTARG;;
		d)  SCRIPT_DIR=$OPTARG;;
		f)	SCRIPT_FILE=$OPTARG;;
		l)	LOG_PATH=$OPTARG;;
		e)	ENV_NAME=$OPTARG;;
		n)	JOB_NAME=$OPTARG;;
		g)  N_GPUS=$OPTARG;;
		c)  N_CPUS=$OPTARG;;
		q)	QUEUE=$OPTARG;;
		Q)	QOS_LEVEL=$OPTARG;;
		p)	PARTITION=$OPTARG;;
		T)	MAX_TIME=$OPTARG;;
		s)	SIG_INTERVAL=$OPTARG;;
		m)	MAIL=true;;
		i)	INTERACTIVE=true;;
		*)	usage;;
	esac
done

# remainder of filename setup
OUT_FILE="${LOG_PATH}${JOB_NAME}"
ERR_FILE="${LOG_PATH}${JOB_NAME}"

# sanity checks
SUPPORTED_SCRIPTS=("bash" "python")
if [[ ! " ${SUPPORTED_SCRIPTS[@]} " =~ " $SCRIPT_TYPE " ]]; then
	echo -e "[${red}FATAL${nc}] Unsupported script type"
	usage
	exit 1
fi

SUPPORTED_QUEUES=("kaushik" "cocosys")
if [[ ! " ${SUPPORTED_QUEUES[@]} " =~ " $QUEUE " ]]; then
	echo -e "[${red}FATAL${nc}] Unsupported queue"
	exit 1
fi

SUPPORTED_QOS_LEVELS=("normal" "preemptible")
if [[ ! " ${SUPPORTED_QOS_LEVELS[@]} " =~ " $QOS_LEVEL " ]]; then
	echo -e "[${red}FATAL${nc}] Unsupported QoS"
	exit 1
fi

if [[ ! $QUEUE == "cocosys" ]] && [[ $PARTITION == "cocosys" ]]; then
	echo -e "[${red}FATAL${nc}] Jobs on cocosys partition must be launched from the cocosys queue!"
	exit 1
fi

if [[ $N_GPUS -gt 0 ]] && [[ $((${CLUSTER}"_gpu_"${PARTITION})) -eq 0 ]]; then
	echo -e "[${red}FATAL${nc}] GPU requirement specified, but selected partition ${PARTITION} does not contain GPUs!"
	exit 1
fi

# essential computation
DIV=$((${CLUSTER}"_cpu_"${PARTITION}))
N_NODES=$(((($N_CPUS+$DIV-1))/$DIV))

# control requested CPU count
if [[ $N_GPUS -gt 0 ]]; then
	REQ_CPUS_PER_GPU=$(($N_CPUS/$N_GPUS))
# else
# 	CPU_ONLY_PARTITIONS=("highmem")
# 	if [[ ! " ${CPU_ONLY_PARTITIONS[@]} " =~ " $PARTITION " ]]; then
# 		# does not support cpu-only jobs on partitions other than highmem right now, TODO
# 		echo -e "[${red}FATAL${nc}] Launching CPU-only jobs not supported on partition $PARTITION. CPU-only jobs can only be launched on partition(s): $CPU_ONLY_PARTITIONS"
# 		exit -1
# 	fi
fi
MAX_CPUS_PER_GPU=$(($DIV/$((${CLUSTER}"_gpu_"${PARTITION}))))
if [[ $REQ_CPUS_PER_GPU -gt $MAX_CPUS_PER_GPU ]] && [[ $PARTITION == "cocosys" ]]; then
	echo -e "[${yellow}WARNING${nc}] Requested number of CPUs per GPU exceeds allowed threshold. Clamping CPU count at threshold value of ${MAX_CPUS_PER_GPU} CPUs/GPU"
	CPUS_PER_GPU=$MAX_CPUS_PER_GPU
elif [[ $REQ_CPUS_PER_GPU -eq 0 ]]; then
	echo -e "[${yellow}WARNING${nc}] Requested number of CPUs is less than the requested number of GPUs. Setting CPU count to ${N_GPUS}"
	CPUS_PER_GPU=$((1))
else
	CPUS_PER_GPU=$REQ_CPUS_PER_GPU
fi

# protect compute resources!
if [[ $N_NODES -ge 2 ]]; then
	read -p "$( echo -e "["${yellow}"WARNING"${nc}"] The requested number of tasks requires more than one node. MPI-enabled code necessary to run multi-node workloads. Non-MPI code will result in wasted compute resources. Is your code MPI-enabled? (y/n): ")" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || FLAG=true
	if $FLAG; then
		echo -e "[${red}FATAL${nc}] Attempted multi-node run with non-MPI workload. Exiting..."
		exit 1
	fi
fi

# mail arg construction
MAIL_ARGS="--mail-type=${MAIL_TYPE} --mail-user=${USER}@purdue.edu"

# job name construction
USR_SPEC_JOB_NAME="--job-name=${JOB_NAME}"

# call to sbatch to launch the job
# sbatch args are arranged thus:
# sbatch \
# 	-p [PARTITION] : Name of compute partition on which to run job
#	-q [QOS_LEVEL] : Quality-of-Service level
#	--job-name=[JOB_NAME] : User-defined job name
#	--output=[OUTPUT_LOG_FILE_NAME] : Name of output log file along with its absolute path
#	--error=[ERROR_LOG_FILE_PATH] : Name of error log file along with its absolute path
#	--gpus-per-node=[N_GPUS] : Number of GPU cards to allocate to the job
#	--gres=[GEN_HDWARE_RQMT] : General Hardware requirements of the job. Jobs requiring GPUs must set this to "gpu"
#	-t [WALL_CLK_TIME] : Wall clock time. Once started, a job will run for exactly this much time before it is killed and its resurces are released. If a job terminates earlier than this time, then resources are released immediately.
#	--signal=[SIG_NAME@TIME] : When this arg is used, SLURM sends signal "SIG_NAME" to the script "TIME" seconds before WALL_CLK_TIME is reached. To prevent data loss, users must implement methods to catch this signal to save state and perform other necessary cleanup.
#	--nodes=[N_NODES] : Minimum number of nodes to allocate to the job. (Max nodes can also be spcified, consult man page)
#	--cpus-per-gpu [CPUS_PER_GPU] : Number of CPU cores to be allocated to the job per allocated GPU.
#	-A [QUEUE] : Name of queue to submit job to. H200s are accessed using queue "cocosys". NRL's private queue is named "kaushik"
#
#	For more info about sbatch, consult the sbatch man page using "man sbatch"
if [[ ! $INTERACTIVE ]]; then
	sbatch \
		-p $PARTITION -q $QOS_LEVEL \
		${MAIL:+"$MAIL_ARGS"} \
		${JOB_NAME:+"$USR_SPEC_JOB_NAME"} \
		# --output="${OUT_FILE}.log" --error="${ERR_FILE}.log" \
		--gpus-per-node=$N_GPUS --gres=gpu:$N_GPUS -t $MAX_TIME --signal=B:SIGUSR1@${SIG_INTERVAL} --nodes=$N_NODES --cpus-per-gpu=$CPUS_PER_GPU -A $QUEUE \
		$JOB_FILE_PATH/${JOB_SUBMISSION_SCRIPT} -e $ENV_NAME -t $SCRIPT_TYPE -d $SCRIPT_DIR -f $SCRIPT_FILE
else
	salloc \
		-p $PARTITION -q $QOS_LEVEL \
		${MAIL:+"$MAIL_ARGS"} \
		${JOB_NAME:+"$USR_SPEC_JOB_NAME"} \
		--gpus-per-node=$N_GPUS --gres=gpu:$N_GPUS -t $MAX_TIME --signal=R:SIGUSR1@${SIG_INTERVAL} --nodes=$N_NODES --cpus-per-gpu=$CPUS_PER_GPU -A $QUEUE
fi
