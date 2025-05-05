#!/bin/bash
set -e

if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then
    module load Nextflow/24.10.2
    module load BLAST+/2.14.1-gompi-2023a
else
    echo "Don't know which modules to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}" >&2
    exit 1
fi

time nextflow run blast-example
