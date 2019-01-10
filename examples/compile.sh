# F90 Compiler
FC="/usr/mpi/intel/mpich-3.0.4/bin/mpif90"
INCLUDE="-I/home/sdas33/HOME/Healpix_2.15a/include"
LIB="-L/home/sdas33/HOME/Healpix_2.15a/lib -L/home/sdas33/HOME/cfitsio -lhealpix -lhpxgif -lcfitsio"

EXAMPLE_CODES="example_codes"
EXAMPLE_OBJ="example_obj"
EXAMPLE_BIN="example_bin"

$FC -O $INCLUDE -c $EXAMPLE_CODES/test_lm2n.f90          -o $EXAMPLE_OBJ/test_lm2n.o -fopenmp
$FC -O $INCLUDE -c $EXAMPLE_CODES/test_n2lm.f90          -o $EXAMPLE_OBJ/test_n2lm.o -fopenmp
$FC -O $INCLUDE -c $EXAMPLE_CODES/test_Clebsch2OneD.f90  -o $EXAMPLE_OBJ/test_Clebsch2OneD.o -fopenmp
$FC -O $INCLUDE -c $EXAMPLE_CODES/test_CalcBipoSH.f90    -o $EXAMPLE_OBJ/test_CalcBipoSH.o -fopenmp
$FC -O $INCLUDE -c $EXAMPLE_CODES/test_slatec.f90        -o $EXAMPLE_OBJ/test_slatec.o -fopenmp
$FC -O          -c $EXAMPLE_CODES/test_readClebs.f90     -o $EXAMPLE_OBJ/test_readClebs.o -fopenmp


$FC $INCLUDE -o $EXAMPLE_BIN/test_n2lm example_obj/test_n2lm.o ../lib/libsubroutines.a $LIB -fopenmp 
$FC $INCLUDE -o $EXAMPLE_BIN/test_lm2n example_obj/test_lm2n.o ../lib/libsubroutines.a $LIB -fopenmp 
$FC $INCLUDE -o $EXAMPLE_BIN/test_Clebsch2OneD example_obj/test_Clebsch2OneD.o ../lib/libsubroutines.a $LIB -fopenmp 
$FC $INCLUDE -o $EXAMPLE_BIN/test_CalcBipoSH example_obj/test_CalcBipoSH.o ../lib/libsubroutines.a $LIB -fopenmp 
$FC $INCLUDE -o $EXAMPLE_BIN/test_slatec example_obj/test_slatec.o ../lib/libslatec.a -fopenmp
$FC $INCLUDE -o $EXAMPLE_BIN/test_readClebs example_obj/test_readClebs.o ../lib/libsubroutines.a ../lib/libslatec.a $LIB -fopenmp





