#!/bin/bash
set -e

if [ ! -f GROMACS_TestCaseA.tar.gz ]; then
  curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
fi
if [ ! -f ion_channel.tpr ]; then
  tar xfz GROMACS_TestCaseA.tar.gz
fi

rm -f ener.edr logfile.log

time gmx mdrun -s ion_channel.tpr -maxh 0.50 -resethway -noconfout -nsteps 10000 -g logfile
