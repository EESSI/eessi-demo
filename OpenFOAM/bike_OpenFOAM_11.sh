#!/bin/bash

which ssh &> /dev/null
if [ $? -ne 0 ]; then
    # if ssh is not available, set plm_rsh_agent to empty value to avoid OpenMPI failing over it
    # that's OK, because this is a single-node run
    export OMPI_MCA_plm_rsh_agent=''
fi

source $FOAM_BASH

if [ -z $EBROOTOPENFOAM ]; then
    echo "ERROR: OpenFOAM module not loaded?" >&2
    exit 1
fi

# Allow users to define the WORKDIR externally (for example a shared FS for multinode runs)
export WORKDIR="${WORKDIR:-/tmp/$USER/$$}"
echo "WORKDIR: $WORKDIR"
mkdir -p $WORKDIR
cd $WORKDIR
pwd

# motorBike, 2M cells
BLOCKMESH_DIMENSIONS="100 40 40"
# motorBike, 150M cells
#BLOCKMESH_DIMENSIONS="200 80 80"

# X*Y*Z should be equal to total number of available cores (across all nodes)
X=${X:-4}
Y=${Y:-2}
Z=${Z:-1}
# number of nodes
NODES=${NODES:-1}
# total number of cores
NP=$((X * Y * Z))
# cores per node
PPN=$(((NP + NODES -1)/NODES))

CASE_NAME=motorBike

if [ -d $CASE_NAME ]; then
    echo "$CASE_NAME already exists in $PWD!" >&2
    exit 1
fi

cp -r $WM_PROJECT_DIR/tutorials/incompressibleFluid/motorBike $CASE_NAME
chmod -R u+w $CASE_NAME
cd $CASE_NAME/$CASE_NAME
pwd

# generate mesh
# All Foam dictionary sub entries are accssed using / (<main entry>/<sub entry>) rather than . (<main entry>.<sub entry>)
echo "generating mesh..."
# Needed to reduce this to a smaller value 200 million is too big for 8 processes, therefore setting to 7 million.
foamDictionary  -entry castellatedMeshControls/maxGlobalCells -set 8000000 system/snappyHexMeshDict
foamDictionary -entry blocks -set "( hex ( 0 1 2 3 4 5 6 7 ) ( $BLOCKMESH_DIMENSIONS ) simpleGrading ( 1 1 1 ) )" system/blockMeshDict
foamDictionary -entry numberOfSubdomains -set $NP system/decomposeParDict
foamDictionary -entry hierarchicalCoeffs/n -set "($X $Y $Z)" system/decomposeParDict

# this needs to be moved to constant/geometry and not constant/triSurface/
cp $WM_PROJECT_DIR/tutorials/resources/geometry/motorBike.obj.gz constant/triSurface/
#surfaceFeaturesDict not available.
# surfaceFeatures 2>&1 | tee log.surfaceFeatures 
blockMesh 2>&1 | tee log.blockMesh
decomposePar -copyZero 2>&1 | tee log.decomposePar
mpirun -np $NP -ppn $PPN -hostfile hostlist snappyHexMesh -parallel -overwrite 2>&1 | tee log.snappyHexMesh
reconstructPar -constant
rm -rf ./processor*
renumberMesh -constant -overwrite 2>&1 | tee log.renumberMesh

# decompose mesh
echo "decomposing..."
foamDictionary -entry numberOfSubdomains -set $NP system/decomposeParDict
foamDictionary -entry decomposer -set multiLevel system/decomposeParDict # keyword method changed to decomposer
foamDictionary -entry multiLevelCoeffs -set "{}" system/decomposeParDict
foamDictionary -entry scotchCoeffs -set "{}" system/decomposeParDict
foamDictionary -entry multiLevelCoeffs/level0 -set "{}" system/decomposeParDict
foamDictionary -entry multiLevelCoeffs/level0/numberOfSubdomains -set $NODES system/decomposeParDict
foamDictionary -entry multiLevelCoeffs/level0/method -set scotch system/decomposeParDict
foamDictionary -entry multiLevelCoeffs/level1 -set "{}" system/decomposeParDict
foamDictionary -entry multiLevelCoeffs/level1/numberOfSubdomains -set $PPN system/decomposeParDict
foamDictionary -entry multiLevelCoeffs/level1/method -set scotch system/decomposeParDict

decomposePar -copyZero 2>&1 | tee log.decomposeParMultiLevel

# run simulation
echo "running..."
# limit run to first 200 time steps
foamDictionary -entry endTime -set 200 system/controlDict
foamDictionary -entry writeInterval -set 1000 system/controlDict
foamDictionary -entry runTimeModifiable -set "false" system/controlDict
foamDictionary -entry functions -set "{}" system/controlDict

mpirun --oversubscribe -np $NP potentialFoam -parallel 2>&1 | tee log.potentialFoam
time mpirun --oversubscribe -np $NP simpleFoam -parallel 2>&1 | tee log.simpleFoam

echo "cleanup..."
rm -rf $WORKDIR
