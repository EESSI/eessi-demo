#!/bin/bash
set -e

if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then 
    module load ESPResSo/4.2.1-foss-2023a 
    module load matplotlib/3.7.2-gfbf-2023a
    module load PyQt5/5.15.10-GCCcore-12.3.0
else echo "Don't know which ESPResSo module to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}" >&2; exit 1
fi

echo generating plate_capacitor_before.png and plate_capacitor_after.png ...

# allow oversubscription for this trivial case
export OMPI_MCA_rmaps_base_oversubscribe=true
mpirun -np 2 pypresso plate_capacitor.py
