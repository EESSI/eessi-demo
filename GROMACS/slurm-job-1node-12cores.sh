#!/bin/bash
#SBATCH --job-name=EESSI-demo-GROMACS
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --time=01:00:00
#SBATCH --export=NONE

cd $SLURM_SUBMIT_DIR

source /cvmfs/pilot.eessi-hpc.org/latest/init/bash

module load GROMACS/2020.1-foss-2020a-Python-3.8.2

if [ ! -f GROMACS_TestCaseA.tar.gz ]; then
  curl -OL https://repository.prace-ri.eu/ueabs/GROMACS/1.2/GROMACS_TestCaseA.tar.gz
fi
if [ ! -f ion_channel.tpr ]; then
  tar xfz GROMACS_TestCaseA.tar.gz
fi

rm -f ener.edr logfile.log

# note: downscaled to just 1k steps (full run is 10k steps)
time gmx mdrun -ntmpi 1 -ntomp $SLURM_CPUS_PER_TASK -s ion_channel.tpr -maxh 0.50 -resethway -noconfout -nsteps 1000 -g logfile
