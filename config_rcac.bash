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


# FILENAME:  config_rcac


# Text colour escape codes. DO NOT MODIFY
white='\033[1;37m'
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
nc='\033[0m'

# system constants. DO NOT MODIFY
QUEUE=cocosys
USER=$(whoami)
CONFIG_PATH=/home/${USER}/rcac-utils
CLUSTER=$(echo $(hostname) | cut -d '.' -f 2)

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
