# F90 Compiler
FC="/usr/mpi/intel/mpich-3.0.4/bin/mpif90"

#INCLUDE Path, LIB Path, FLAG Path
INCLUDE="-I/home/sdas33/HOME/Healpix_2.15a/include"
LIB="-L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio"
FLAG="-fopenmp"



# -------------------- NOTHING TO CHANGE BELOW THIS LINE -----------------------------
#OBJ Path, BIN Path
OBJ="obj"
BIN="bin"

SLATEC_OBJ="obj/slatec"

#Compile bestimator
SRC="src/bestimator/"
$FC -O $INCLUDE -c $SRC/bestimator.f90  -o $OBJ/bestimator.o $FLAG
$FC -O $INCLUDE -c $SRC/BipoSH_ALMll_isotropic_Noise.f90 -o $OBJ/BipoSH_ALMll_isotropic_Noise.o $FLAG
$FC -O $INCLUDE -c $SRC/BipoSH_anisotropic_noise.f90  -o $OBJ/BipoSH_anisotropic_noise.o $FLAG
$FC $INCLUDE -o $BIN/bestimator1 $OBJ/bestimator.o $OBJ/BipoSH_ALMll_isotropic_Noise.o $OBJ/BipoSH_anisotropic_noise.o $LIB $FLAG

#Compile betaestimator
SRC="src/betaestimator"
$FC -O $INCLUDE -c $SRC/beta_estimation_nonoise.f90  -o $OBJ/beta_estimation_nonoise.o $FLAG
$FC -O $INCLUDE -c $SRC/beta_estimation_isotropicnoise.f90 -o $OBJ/beta_estimation_isotropicnoise.o $FLAG
$FC -O $INCLUDE -c $SRC/beta_estimation_anisotropicnoise.f90 -o $OBJ/beta_estimation_anisotropicnoise.o $FLAG
$FC -O $INCLUDE -c $SRC/betaestimator.f90  -o $OBJ/betaestimator.o $FLAG
$FC $INCLUDE -o $BIN/betaestimator $OBJ/betaestimator.o $OBJ/beta_estimation_nonoise.o $OBJ/beta_estimation_isotropicnoise.o $OBJ/beta_estimation_anisotropicnoise.o  $LIB $FLAG

#Compile Utility Packages
SRC="src/utility"
$FC -O $INCLUDE -c $SRC/fits2d.f90     -o $OBJ/fits2d.o $FLAG
$FC -O $INCLUDE -c $SRC/map2fits.f90   -o $OBJ/map2fits.o $FLAG
$FC -O $INCLUDE -c $SRC/nest2ring.f90  -o $OBJ/nest2ring.o $FLAG
$FC -O $INCLUDE -c $SRC/ring2nest.f90  -o $OBJ/ring2nest.o $FLAG
$FC -O $INCLUDE -c $SRC/rotatecoor.f90  -o $OBJ/ring2nest.o $FLAG

$FC $INCLUDE -o $BIN/fits2d    $OBJ/fits2d.o    $LIB $FLAG
$FC $INCLUDE -o $BIN/map2fits  $OBJ/map2fits.o  $LIB $FLAG
$FC $INCLUDE -o $BIN/nest2ring $OBJ/nest2ring.o $LIB $FLAG
$FC $INCLUDE -o $BIN/ring2nest $OBJ/ring2nest.o $LIB $FLAG

#Compile SLATEC files
SLATEC_SRC="src/slatec"
$FC -O $INCLUDE -c $SLATEC_SRC/clebsch.f  -o $SLATEC_OBJ/clebsch.o $FLAG
$FC -O $INCLUDE -c $SLATEC_SRC/d1mach.f   -o $SLATEC_OBJ/d1mach.o $FLAG 
$FC -O $INCLUDE -c $SLATEC_SRC/divide.f90 -o $SLATEC_OBJ/divide.o $FLAG
$FC -O $INCLUDE -c $SLATEC_SRC/drc3jj.f  -o $SLATEC_OBJ/drc3jj.o $FLAG
$FC -O $INCLUDE -c $SLATEC_SRC/drc3jm.f  -o $SLATEC_OBJ/drc3jm.o $FLAG
$FC -O $INCLUDE -c $SLATEC_SRC/fdump.f   -o $SLATEC_OBJ/fdump.o $FLAG 
$FC -O $INCLUDE -c $SLATEC_SRC/i1mach.f  -o $SLATEC_OBJ/i1mach.o $FLAG
$FC -O $INCLUDE -c $SLATEC_SRC/j4save.f  -o $SLATEC_OBJ/j4save.o $FLAG     
$FC -O $INCLUDE -c $SLATEC_SRC/xercnt.f  -o $SLATEC_OBJ/xercnt.o $FLAG
$FC -O $INCLUDE -c $SLATEC_SRC/xerhlt.f  -o $SLATEC_OBJ/xerhlt.o $FLAG
$FC -O $INCLUDE -c $SLATEC_SRC/xermsg.f  -o $SLATEC_OBJ/xermsg.o $FLAG
$FC -O $INCLUDE -c $SLATEC_SRC/xerprn.f  -o $SLATEC_OBJ/xerprn.o $FLAG 
$FC -O $INCLUDE -c $SLATEC_SRC/xersve.f  -o $SLATEC_OBJ/xersve.o $FLAG
$FC -O $INCLUDE -c $SLATEC_SRC/xgetua.f  -o $SLATEC_OBJ/xgetua.o $FLAG
ar rcs lib/libslatec.a $SLATEC_OBJ/clebsch.o $SLATEC_OBJ/d1mach.o $SLATEC_OBJ/divide.o $SLATEC_OBJ/drc3jj.o $SLATEC_OBJ/drc3jm.o $SLATEC_OBJ/fdump.o $SLATEC_OBJ/i1mach.o $SLATEC_OBJ/j4save.o $SLATEC_OBJ/xercnt.o $SLATEC_OBJ/xerhlt.o $SLATEC_OBJ/xermsg.o $SLATEC_OBJ/xerprn.o $SLATEC_OBJ/xersve.o $SLATEC_OBJ/xgetua.o

#Compile subroutines
$FC -O $INCLUDE -c src/subroutines/subroutines.f90  -o $OBJ/subroutines.o $FLAG
ar rcs lib/libsubroutines.a $OBJ/subroutines.o


#Compile Clebschgen 
$FC -O -c src/clebschgen/clebschgen.f90  -o $OBJ/clebschgen.o
$FC $INCLUDE -o $BIN/clebschgen $OBJ/clebschgen.o $OBJ/subroutines.o $SLATEC_OBJ/clebsch.o $SLATEC_OBJ/d1mach.o $SLATEC_OBJ/divide.o $SLATEC_OBJ/drc3jj.o $SLATEC_OBJ/drc3jm.o $SLATEC_OBJ/fdump.o $SLATEC_OBJ/i1mach.o $SLATEC_OBJ/j4save.o $SLATEC_OBJ/xercnt.o $SLATEC_OBJ/xerhlt.o $SLATEC_OBJ/xermsg.o $SLATEC_OBJ/xerprn.o $SLATEC_OBJ/xersve.o $SLATEC_OBJ/xgetua.o $LIB $FLAG





