#!/bin/bash

echo $EESSI_CVMFS_REPO
if [ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]; then
    echo $EESSI_VERSION
    if [ $EESSI_VERSION == "2023.06" ]; then
        module load TensorFlow/2.13.0-foss-2023a
    fi
fi

"module load TensorFlow/2.3.1-foss-2020a-Python-3.8.2"

time python TensorFlow-2.x_mnist-test.py
