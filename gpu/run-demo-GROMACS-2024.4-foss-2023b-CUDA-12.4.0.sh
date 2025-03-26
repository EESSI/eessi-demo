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
module avail GROMACS

# Check CPU module or build it
echo "Checking availablity of GROMACS/2024.4-foss-2023b"
if module is-avail GROMACS/2024.4-foss-2023b ; then
    echo "GROMACS/2024.4-foss-2023b module available, no need to build it."
else
    echo "GROMACS/2024.4-foss-2023b module NOT found, building from scratch."
    eb --force --robot GROMACS.2024.4-foss-2023b.eb --skip-test-step
fi

# Check GPU module or build it
echo "Checking availablity of GROMACS/2024.4-foss-2023b-CUDA-12.4.0"
if module is-avail GROMACS/2024.4-foss-2023b-CUDA-12.4.0 ; then
    echo "GROMACS/2024.4-foss-2023b-CUDA-12.4.0 module available, no need to build it."
else
    echo "GROMACS/2024.4-foss-2023b-CUDA-12.4.0 module NOT found, building from scratch."

    echo "Need to install CUDA locally and accept EULA"
    /cvmfs/software.eessi.io/versions/${EESSI_VERSION}/scripts/gpu_support/nvidia/install_cuda_host_injections.sh --cuda-version 12.4.0 --temp-dir /tmp/$USER/EESSI --accept-cuda-eula

    eb --force --robot GROMACS-2024.4-foss-2023b-CUDA-12.4.0.eb --cuda-compute-capabilities="$cc" --skip-test-step
fi

# Calculate and display execution time
end_time=$(date +%s)
execution_time=$((end_time - start_time))
echo "Time to Science: $execution_time seconds"

echo "Running TESTS:"

cd GROMACS
echo "GROMACS CPU"
module load GROMACS/2024.4-foss-2023b
# run the process 3 times - first run can be longer
# due to loading times of the modules from CVMFS
./run-cpu.sh || echo "ERROR!"
./run-cpu.sh || echo "ERROR!"
./run-cpu.sh || echo "ERROR!"
module unload GROMACS/2024.4-foss-2023b

echo "GROMACS GPU"
module load GROMACS/2024.4-foss-2023b-CUDA-12.4.0
# run the process 3 times - first run can be longer
# due to loading times of the modules from CVMFS
./run-gpu.sh || echo "ERROR!"
./run-gpu.sh || echo "ERROR!"
./run-gpu.sh || echo "ERROR!"
module unload GROMACS/2024.4-foss-2023b-CUDA-12.4.0
cd ..
