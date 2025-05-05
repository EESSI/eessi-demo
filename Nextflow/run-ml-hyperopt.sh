#!/bin/bash
set -e

if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then
    module load Nextflow/24.10.2
    module load scikit-learn/1.4.0-gfbf-2023b
    module load matplotlib/3.8.2-gfbf-2023b
else
    echo "Don't know which modules to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}" >&2
    exit 1
fi

time nextflow run ml-hyperopt
