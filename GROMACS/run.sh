#!/bin/bash
set -e

if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then module load GROMACS/2024.1-foss-2023b
else 
  if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2025.06" ]]; then module load GROMACS/2025.2-foss-2025a
  else 
	echo "Don't know which GROMACS module to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}" >&2; exit 1
  fi
fi 

if [ ! -f GROMACS_TestCaseA.tar.gz ]; then
  curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
fi
if [ ! -f ion_channel.tpr ]; then
  tar xfz GROMACS_TestCaseA.tar.gz
fi

rm -f ener.edr logfile.log

# note: downscaled to just 1k steps (full run is 10k steps)
time gmx mdrun -s ion_channel.tpr -maxh 0.50 -resethway -noconfout -nsteps 1000 -g logfile
