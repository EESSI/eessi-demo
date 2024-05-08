#!/bin/bash
set -e

if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then module load TensorFlow/2.13.0-foss-2023a
else echo "Don't know which TensorFlow module to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}" >&2; exit 1
fi


time python TensorFlow-2.x_mnist-test.py
