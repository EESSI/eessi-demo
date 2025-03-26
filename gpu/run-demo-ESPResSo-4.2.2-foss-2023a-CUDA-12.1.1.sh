#!/usr/bin/env bash
set -e

# Record start time
start_time=$(date +%s)

# Source 
echo "Sourcing lmod"
source /cvmfs/software.eessi.io/versions/2023.06/init/lmod/bash
module load EESSI
module load EESSI-extend
export EESSI_SKIP_REMOVED_MODULES_CHECK=1

# Install latest EasyBuild (5.0.0)
eb --install-latest-eb-release
module swap EasyBuild/5.0.0

# Get NVIDIA cc
cc=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -1)
echo "Detected NVIDIA Cuda Capability: $cc"

# Get all available modules overview
module avail ESPResSo

# Check CPU module or build it
echo "Checking availablity of ESPResSo/4.2.2-foss-2023a"
if module is-avail ESPResSo/4.2.2-foss-2023a ; then
    echo "ESPResSo/4.2.2-foss-2023a module available, no need to build it."
else
    echo "ESPResSo/4.2.2-foss-2023a module NOT found, building from scratch."
    eb --force --robot ESPResSo-4.2.2-foss-2023a.eb --skip-test-step
fi

# Check GPU module or build it
echo "Checking availablity of ESPResSo/4.2.2-foss-2023a-CUDA-12.1.1"
if module is-avail ESPResSo/4.2.2-foss-2023a-CUDA-12.1.1 ; then
    echo "ESPResSo/4.2.2-foss-2023a-CUDA-12.1.1 module available, no need to build it."
else
    echo "ESPResSo/4.2.2-foss-2023a-CUDA-12.1.1 module NOT found, building from scratch."
    
    echo "Need to install CUDA locally and accept EULA"
    /cvmfs/software.eessi.io/versions/${EESSI_VERSION}/scripts/gpu_support/nvidia/install_cuda_host_injections.sh --cuda-version 12.1.1 --temp-dir /tmp/$USER/EESSI --accept-cuda-eula

    eb --force --robot ESPResSo-4.2.2-foss-2023a-CUDA-12.1.1.eb --cuda-compute-capabilities="$cc" --skip-test-step
fi

# Calculate and display execution time
end_time=$(date +%s)
execution_time=$((end_time - start_time))
echo "Time to Science: $execution_time seconds"

echo "Running TESTS:"

cd ESPResSo
echo "ESPResSo CPU"
module load ESPResSo/4.2.2-foss-2023a
module load matplotlib/3.7.2-gfbf-2023a
module load tqdm/4.66.1-GCCcore-12.3.0
module load mpl-ascii/0.10.0-gfbf-2023a
# run the process 3 times - first run can be longer
# due to loading times of the modules from CVMFS
./run-cpu.sh || echo "ERROR!"
./run-cpu.sh || echo "ERROR!"
./run-cpu.sh || echo "ERROR!"
module unload ESPResSo/4.2.2-foss-2023a

echo "ESPResSo GPU"
module load ESPResSo/4.2.2-foss-2023a-CUDA-12.1.1
module load matplotlib/3.7.2-gfbf-2023a
module load tqdm/4.66.1-GCCcore-12.3.0
module load mpl-ascii/0.10.0-gfbf-2023a
# run the process 3 times - first run can be longer
# due to loading times of the modules from CVMFS
./run-gpu.sh || echo "ERROR!"
./run-gpu.sh || echo "ERROR!"
./run-gpu.sh || echo "ERROR!"
module unload ESPResSo/4.2.2-foss-2023a-CUDA-12.1.1
cd ..
