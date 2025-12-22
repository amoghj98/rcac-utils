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


# FILENAME:  auto_env_export

source /etc/profile.d/modules.sh
module purge

CLUSTER=$(echo $(hostname) | cut -d '.' -f 2)
if [[ $CLUSTER == *"gautschi"* ]]; then
	INSTALL_DIR=/home/${USER}
    module load conda
else
	CLUSTER=$(echo $(hostname) | cut -d '.' -f 1)
	INSTALL_DIR=/home/${CLUSTER}/a/${USER}
fi

cd $INSTALL_DIR/rcac-utils

# source $HOME/.bashrc
source ./config_slurm.bash

env_array=$(eval "conda env list | cut -d ' ' -f1")
env_array=${env_array[@]:4}
for e in $env_array; do
    conda activate $e
    conda env export -n $e>"$INSTALL_DIR/ymls/$e.yml"
    conda deactivate
done