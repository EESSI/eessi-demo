#!/bin/bash

# By default disable UCX and libfabric since we typically run these examples on demo nodes without fast interconnect
export OMPI_MCA_osc=${OMPI_MCA_osc:-"^ucx"}
export OMPI_MCA_btl=${OMPI_MCA_btl:-"^openib,ofi"}
export OMPI_MCA_pml=${OMPI_MCA_pml:-"^ucx"}
export OMPI_MCA_mtl=${OMPI_MCA_mtl:-"^ofi"}

if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then
    echo "Running demo for OpenFOAM v11 ..."
    module load OpenFOAM/11-foss-2023a
    
    # Allow oversubscription in case we don't have enough available cores
    export OMPI_MCA_rmaps_base_oversubscribe=${OMPI_MCA_rmaps_base_oversubscribe:-"true"}

    ./run_OpenFOAM_motorBike-tutorial.sh

elif [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2025.06" ]]; then
    echo "Running demo for OpenFOAM v13 ..."
    module load OpenFOAM/13-foss-2025a
    
    # Allow oversubscription in case we don't have enough available cores
    export PRTE_MCA_rmaps_default_mapping_policy=${PRTE_MCA_rmaps_default_mapping_policy:-":oversubscribe"}

    ./run_OpenFOAM_motorBike-tutorial.sh
else 
    echo "Don't know which OpenFOAM module to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}" >&2
    exit 1
fi
