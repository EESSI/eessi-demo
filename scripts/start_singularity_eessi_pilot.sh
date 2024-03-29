#!/bin/bash

# honor $TMPDIR if it is already defined, use /tmp otherwise
if [ -z $TMPDIR ]; then
    export WORKDIR=/tmp/$USER
else
    export WORKDIR=$TMPDIR/$USER
fi

mkdir -p ${WORKDIR}/{var-lib-cvmfs,var-run-cvmfs,home}
export SINGULARITY_BIND="${WORKDIR}/var-run-cvmfs:/var/run/cvmfs,${WORKDIR}/var-lib-cvmfs:/var/lib/cvmfs"
export SINGULARITY_HOME="${WORKDIR}/home:/home/$USER"
export EESSI_PILOT="container:cvmfs2 pilot.eessi-hpc.org /cvmfs/pilot.eessi-hpc.org"
singularity shell --fusemount "$EESSI_PILOT" docker://ghcr.io/eessi/client-pilot:centos7
