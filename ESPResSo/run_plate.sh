#!/bin/bash
set -e

if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then
    module load ESPResSo/4.2.2-foss-2023a-CUDA-12.1.1
    module load matplotlib/3.7.2-gfbf-2023a
    module load tqdm/4.66.1-GCCcore-12.3.0
    module load mpl-ascii/0.10.0-gfbf-2023a
else echo "Don't know which ESPResSo module to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}" >&2; exit 1
fi

python poiseuille.py --gpu
