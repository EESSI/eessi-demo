#!/bin/bash

module load GROMACS/2020.1-foss-2020a-Python-3.8.2

if [ ! -f GROMACS_TestCaseA.tar.gz ]; then
  curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
fi
if [ ! -f ion_channel.tpr ]; then
  tar xfz GROMACS_TestCaseA.tar.gz
fi

rm -f ener.edr logfile.log

# note: downscaled to just 1k steps (full run is 10k steps)
time -p gmx mdrun -s ion_channel.tpr -maxh 0.50 -resethway -noconfout -nsteps 1000 -g logfile
