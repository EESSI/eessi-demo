#!/bin/bash

if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then
    echo "Running demo for OpenFOAM v11 ..."
    export OMPI_MCA_rmaps_base_oversubscribe=true
    ./bike_OpenFOAM_v11.sh
else 
    echo "Don't know which OpenFOAM module to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}" >&2
    exit 1
fi
