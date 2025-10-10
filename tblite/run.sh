#!/bin/bash
set -e

if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then 
    module load tblite/0.4.0-gfbf-2023b
else 
    echo "Don't know which tblite module to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}" >&2; exit 1
fi

python tblite-single-point-GFN2-xTB.py
