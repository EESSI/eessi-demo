#!/bin/bash
set -e

if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then 
    module load R-bundle-Bioconductor/3.16-foss-2022b-R-4.2.2
elif [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2025.06" ]]; then 
    module load R-bundle-Bioconductor/3.20-foss-2024a-R-4.4.2
else echo "Don't know which Bioconductor module to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}" >&2; exit 1
fi

time Rscript dna.R
