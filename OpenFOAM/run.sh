#!/bin/bash

if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then module load OpenFOAM/11-foss-2023a
./bike_OpenFOAM_11.sh
elif [[ $EESSI_CVMFS_REPO == "/cvmfs/pilot.eessi-hpc.org" ]] && [[ $EESSI_PILOT_VERSION == "2021.12" ]]; then module load OpenFOAM/8-foss-2020a
./bike_OpenFOAM8.sh
elif [[ $EESSI_CVMFS_REPO == "/cvmfs/pilot.eessi-hpc.org" ]] && [[ $EESSI_PILOT_VERSION == "2023.06" ]]
then echo There is no demo for OpenFOAM in "/cvmfs/pilot.eessi-hpc.org/versions/2023.06". Please use the EESSI production repo "/cvmfs/software.eessi.io".
exit 1;
else echo "Don't know which OpenFOAM module to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}$EESSI_PILOT_VERSION" >&2; exit 1
fi