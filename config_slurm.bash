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


# FILENAME:  config_slurm


# Text colour escape codes. DO NOT MODIFY
white='\033[1;37m'
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
nc='\033[0m'

# system constants. DO NOT MODIFY
USER=$(whoami)

#
CLUSTER=$(echo $(hostname) | cut -d '.' -f 2)
if [[ $CLUSTER == *"gautschi"* ]]; then
	CONFIG_PATH=/home/${USER}/rcac-utils
	QUEUE=cocosys
else
	CLUSTER=$(echo $(hostname) | cut -d'.' -f 1)
	if [[ $CLUSTER == *"cocosys"* ]]; then
		CONFIG_PATH=/scratch/${CLUSTER}/a/${USER}/rcac-utils
		QUEUE=batch
	else
		CONFIG_PATH=/home/${CLUSTER}/a/${USER}/rcac-utils
		QUEUE=batch
	fi
fi

# Cluster constants. DO NOT MODIFY
# Gautschi CPU cores/node
gautschi_cpu_ai=112
gautschi_cpu_cocosys=112
gautschi_cpu_cpu=192
gautschi_cpu_highmem=192
gautschi_cpu_smallgpu=128
gautschi_cpu_profiling=192

# Cluster constants. DO NOT MODIFY
# Gautschi GPU cards per node
gautschi_gpu_ai=8
gautschi_gpu_cocosys=8
gautschi_gpu_cpu=0
gautschi_gpu_highmem=0
gautschi_gpu_smallgpu=2
gautschi_gpu_profiling=0

# Cluster constants. DO NOT MODIFY
# Nano CPU cores/node
nano01_cpu_batch=40
nano02_cpu_batch=40
nano03_cpu_batch=40
nano04_cpu_batch=40
nano05_cpu_batch=40
nano06_cpu_batch=40
nano12_cpu_batch=40
cocosys01_cpu_cocosys=512
cocosys02_cpu_cocosys=512

# Cluster constants. DO NOT MODIFY
# Nano GPU cards per node
nano01_gpu_batch=0
nano02_gpu_batch=0
nano03_gpu_batch=0
nano04_gpu_batch=0
nano05_gpu_batch=0
nano06_gpu_batch=0
nano12_gpu_batch=0
cocosys01_gpu_cocosys=0
cocosys02_gpu_cocosys=0
