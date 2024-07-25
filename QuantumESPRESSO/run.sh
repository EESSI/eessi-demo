if [[ $EESSI_CVMFS_REPO == "/cvmfs/software.eessi.io" ]] && [[ $EESSI_VERSION == "2023.06" ]]; then
    echo "Running demo for QuantumESPRESSO 7.3.1 ..."
    module load QuantumESPRESSO/7.3.1-foss-2023a
    module load gnuplot/5.4.8-GCCcore-12.3.0
else
    echo "Don't know which QuantumESPRESSO module to load for ${EESSI_CVMFS_REPO}/versions/${EESSI_VERSION}" >&2
    exit 1
fi

if [ ! -f Si.pz-vbc.UPF ]; then
    curl -OL http://pseudopotentials.quantum-espresso.org/upf_files/Si.pz-vbc.UPF
fi

PSEUDO_DIR=$(pwd)
TMP_DIR=$(pwd)/tmp
RUN_COMMAND=""

echo "Parallel command:" $RUN_COMMAND
echo "Started at: " `date`

############################################################3
# Calculate the SCF charge density

IN=si_script.scf.in
OUT=si.scf.out
cat > $IN << EOF
&CONTROL
  calculation  = "scf",
  prefix       = "Si",
  pseudo_dir   = "$PSEUDO_DIR",
  outdir       = "$TMP_DIR",
  restart_mode = "from_scratch"
  tprnfor = .true.
  wf_collect=.true.
/
&SYSTEM
  ibrav     = 2,
  celldm(1) = 10.21,
  nat       = 2,
  ntyp      = 1,
  ecutwfc   = 20
  nbnd      = 5
/
&ELECTRONS
  conv_thr    = 1.D-8,
  mixing_beta = 0.7D0	,
/
ATOMIC_SPECIES
 Si  28.086  Si.pz-vbc.UPF
ATOMIC_POSITIONS
 Si 0.00 0.00 0.00
 Si 0.25 0.25 0.25
K_POINTS 
  10
   0.1250000  0.1250000  0.1250000   1.00
   0.1250000  0.1250000  0.3750000   3.00
   0.1250000  0.1250000  0.6250000   3.00
   0.1250000  0.1250000  0.8750000   3.00
   0.1250000  0.3750000  0.3750000   3.00
   0.1250000  0.3750000  0.6250000   6.00
   0.1250000  0.3750000  0.8750000   6.00
   0.1250000  0.6250000  0.6250000   3.00
   0.3750000  0.3750000  0.3750000   1.00
   0.3750000  0.3750000  0.6250000   3.00
EOF

echo -e "\tStart: " `date`
COMMAND="  $RUN_COMMAND pw.x"
echo -e "\t\t$COMMAND < $IN > $OUT"
$COMMAND < $IN > $OUT
echo -e "\tEnd: " `date`

############################################################3
# Calculate the bands

IN=si_script.bands.in
OUT=si.bands.out
cat > $IN << EOF
&CONTROL
  calculation  = "bands",
  prefix       = "Si",
  pseudo_dir   = "$PSEUDO_DIR",
  outdir       = "$TMP_DIR",
  tprnfor = .true.
  wf_collect=.true.
/
&SYSTEM
  ibrav     = 2,
  celldm(1) = 10.21,
  nat       = 2,
  ntyp      = 1,
  ecutwfc   = 20
  nbnd      = 8 
/
&ELECTRONS
  conv_thr    = 1.D-8,
  mixing_beta = 0.7D0	,
/
ATOMIC_SPECIES
 Si  28.086  Si.pz-vbc.UPF
ATOMIC_POSITIONS
 Si 0.00 0.00 0.00
 Si 0.25 0.25 0.25
K_POINTS {tpiba_b}
  6
    0.500 0.500 0.500 8 ! L
    0.000 0.000 0.000 8 ! Gamma
    0.000 1.000 0.000 8 ! X
    0.250 1.000 0.250 1 ! U
    0.750 0.750 0.000 8 ! K
    0.000 0.000 0.000 1 ! Gamma
EOF

echo -e "\tStart: " `date`
COMMAND="  $RUN_COMMAND pw.x"
echo -e "\t\t$COMMAND < $IN > $OUT"
$COMMAND < $IN > $OUT
echo -e "\tEnd: " `date`

############################################################3
# Post-processing

IN=si_script.bandspp.in
OUT=si.bandspp.out
cat > $IN << EOF
&bands
    prefix = "Si",
    outdir='$TMP_DIR'
    filband='Sibands.dat'
    lsym=.true.
 /
EOF

echo -e "\tStart: " `date`
COMMAND="  $RUN_COMMAND bands.x"
echo -e "\t\t$COMMAND < $IN > $OUT"
$COMMAND < $IN > $OUT
echo -e "\tEnd: " `date`


IN=si_script.plotband.in
OUT=si.plotband.out
cat > $IN << EOF
Sibands.dat
-6.0 10.0

Sibands.ps
6.377
1 6.377
EOF

echo -e "\tStart: " `date`
COMMAND="plotband.x"
echo -e "\t\t$COMMAND < $IN > $OUT"
$COMMAND < $IN > $OUT
echo -e "\tEnd: " `date`

echo "Run completed at: " `date`

rm -rf $TMP_DIR

############################################################3
# Plotting the bands

IN=Sibands.gnuplot
cat > $IN << EOF
set title "Si band structure from Sibands.dat.gnu"
#high-symmetry point:  0.5000 0.5000 0.5000   x coordinate   0.0000
#high-symmetry point:  0.0000 0.0000 0.0000   x coordinate   0.8660
#high-symmetry point:  0.0000 1.0000 0.0000   x coordinate   1.8660
#high-symmetry point:  0.2500 1.0000 0.2500   x coordinate   2.2196
#high-symmetry point:  0.7500 0.7500 0.0000   x coordinate   2.2196
#high-symmetry point:  0.0000 0.0000 0.0000   x coordinate   3.2802
L=0.0000
G1=0.8660
X=1.8660
U=2.2196
G2=3.2802
set xtics ("L" L,"{/Symbol G}" G1,"X" X,"U,K" U,"{/Symbol G}" G2) nomirror
set xrange [*:*]
set yrange [-13:4]
set grid x
set ylabel "Energy (eV)"
set nokey
EF = 6.377
set term post enhanced
set out "Sibands-nosym.ps"
plot "Sibands.dat.gnu" u 1:(\$2-EF) with linespoints pointtype 7 pointsize 0.5,\
	0 t "" w l lt 2
set term pngcairo
set out "Sibands-nosym.png"
replot
set term dumb size 120,40
set out 
replot
set term qt
set out
replot
EOF

echo -e "\tRunning gnuplot script: " `date`
gnuplot -p Sibands.gnuplot

exit
