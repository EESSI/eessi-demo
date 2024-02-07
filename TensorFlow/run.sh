#!/bin/bash
set -e

echo $EESSI_CVMFS_REPO
if [ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]; then
    echo $EESSI_VERSION
    if [ $EESSI_VERSION == "2023.06" ]; then
        module load TensorFlow/2.13.0-foss-2023a
    fi
elif [ $EESSI_CVMFS_REPO == "/cvmfs/pilot.eessi-hpc.org" ]; then
    if [ $EESSI_PILOT_VERSION == "2021.12" ]; then
        module load TensorFlow/2.3.1-foss-2020a-Python-3.8.2
    elif [ $EESSI_PILOT_VERSION == "2023.06" ]; then
        echo "No TensorFlow module available in ${EESSI_CVMFS_REPO}/versions/$EESSI_PILOT_VERSION"
        echo "Please use the latest version in the /cvmfs/software.eessi.io repo"
        exit 1;
    fi
fi


time python TensorFlow-2.x_mnist-test.py
