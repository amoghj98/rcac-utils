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


# FILENAME:  monitor


# load module cmd to prevent weird bug experienced by few folks
source /etc/profile.d/modules.sh

# system constants. DO NOT MODIFY
QUEUE=kaushik
JOB_FILE_PATH=$HOME/rcac-utils
USER=$(whoami)

# usage help message
usage() {
	echo "usage: $0 [-h] [-s SESSION_NAME] [-w WINDOW_NAME]" 1>&2;
	echo "-h: Display help message"
	echo "-s SESSION_NAME: Name of the tmux session running monitor commands. Defaults to 'monitor'"
    echo "-w WINDOW_NAME: Name of the tmux window running monitor commands. Defaults to 'job_status'"
	exit 1;
}

# arg init
SESSION_NAME="monitor"
WINDOW_NAME="job_status"

# read args
while getopts "hs:" opts; do
	case "${opts}" in
		h)	usage;;
		s)	SESSION_NAME=$OPTARG;;
		*)	usage;;
	esac
done

module load monitor

#Get width and lenght size of terminal, this is needed if one wants to resize a detached session/window/pane
#with resize-pane command here
set -- $(stty size) #$1=rows, $2=columns

# create new session
tmux new-session -s $SESSION_NAME -n $WINDOW_NAME -d -x "$2" -y "$(($1 - 1))"
tmux send-keys -t $SESSION_NAME 'watch -n 60 squeue -u $USER' C-m

#rename pane 0
tmux set -p @mytitle "user_jobs"

# split window vertically
tmux split-window -v
tmux send-keys -t $SESSION_NAME 'squeue -a -p cocosys' C-m
# tmux send-keys -t $SESSION_NAME 'squeue -a -p ai' C-m

#rename pane 1
tmux set -p @mytitle "cluster_load"

# attach session
tmux attach -t $SESSION_NAME

# show queue
# tmux new-session -d -s $SESSION_NAME watch -n 1 squeue -u $USER