#!/usr/bin/env bash
set -e
umask 002

# Record start time
start_time=$(date +%s)

# Install NVIDIA Driver
# install nvidia fabric-manager and start (due to nvlink switch)
echo "You need to install NVIDIA driver or NVIDIA fabric-manager for nvlink switch"

# Build CUDA-Samples from Easyconfig via EESSI-extend
#cc=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -1)
cc=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | uniq)
echo "Detected NVIDIA Cuda Capability: $cc"

# Install EESSI
sudo mkdir -p /opt/eessi
sudo chmod 777 /opt/eessi

echo "Installing EESSI"
sudo ../scripts/install_cvmfs_eessi.sh

# Source EESSI
echo "Sourcing lmod"
source /cvmfs/software.eessi.io/versions/2023.06/init/lmod/bash
module load EESSI
export EESSI_SKIP_REMOVED_MODULES_CHECK=1

# Link DRIVER libraries
echo "Linking NVIDIA drivers to host_libraries"
# Once the changes are merged, use the line below from upstream.
# /cvmfs/software.eessi.io/versions/${EESSI_VERSION}/scripts/gpu_support/nvidia/link_nvidia_host_libraries.sh
./scripts/gpu_support/nvidia/link_nvidia_host_libraries.sh

# Checking CUDA modules
echo "Checking availablity of CUDA"
module load EESSI-extend

module avail CUDA

if module is-avail CUDA/12.1.1; then
    echo "CUDA 12.1.1 module available, no need to build it."
else
    echo "CUDA 12.1.1 module NOT found. Need to build it from scratch."

    # Install CUDA 12.1.1 to host_injections.
    echo "Installing CUDA 12.1.1 to host_injections"
    # Using updated version of the script to include LMOD module
    # /cvmfs/software.eessi.io/versions/${EESSI_VERSION}/scripts/gpu_support/nvidia/install_cuda_host_injections.sh --cuda-version 12.1.1 --temp-dir /tmp/$USER/EESSI --accept-cuda-eula
    ./scripts/gpu_support/nvidia/install_cuda_host_injections.sh --cuda-version 12.1.1 --temp-dir /tmp/$USER/EESSI --accept-cuda-eula

    # Flush tmp dir to save space
    rm /tmp/$USER/EESSI -rf
fi

if module is-avail CUDA/12.4.0; then
    echo "CUDA 12.4.0 module available, no need to build it."
else
    echo "CUDA 12.4.0 module NOT found. Need to build it from scratch."

    # Install CUDA 12.4.0 to host_injections.
    echo "Installing CUDA 12.4.0 to host_injections"
    # Using updated version of the script to include LMOD module
    # /cvmfs/software.eessi.io/versions/${EESSI_VERSION}/scripts/gpu_support/nvidia/install_cuda_host_injections.sh --cuda-version 12.1.1 --temp-dir /tmp/$USER/EESSI --accept-cuda-eula
    ./scripts/gpu_support/nvidia/install_cuda_host_injections.sh --cuda-version 12.4.0 --temp-dir /tmp/$USER/EESSI --accept-cuda-eula 

    # Flush tmp dir to save space
    rm /tmp/$USER/EESSI -rf
fi

if module is-avail CUDA-Samples; then
    echo "CUDA-Samples module available, no need to build it."
else
    echo "CUDA-Samples module NOT found, no need to build it."

    eb --force --robot CUDA-Samples-12.1-GCC-12.3.0-CUDA-12.1.1.eb --cuda-compute-capabilities="$cc"

fi

module load CUDA-Samples
deviceQuery

# Calculate and display execution time
end_time=$(date +%s)
execution_time=$((end_time - start_time))
echo "Time to Science: $execution_time seconds"

