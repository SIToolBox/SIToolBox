use Healpix_types
use pix_tools

real(dp),dimension(:),allocatable :: M,M1
integer :: nside
integer :: i,j
character*20 cinmap,coutmap

print *,'This program will cconvert a map from the nested format to ring format'
print *,'The input should be in ascii format. For fits files, you need to &
convery those to ascii format with fits2d'
print *,'Enter the resolution parameter(Nside):'
read(*,*)nside

print *,'Enter the name of the input map'
read(*,*)cinmap

allocate(M(0:12*nside**2 - 1))
allocate(M1(0:12*nside**2 - 1))

open(unit=10,file=cinmap)
do i=0,nside*nside*12-1
   read(10,*)M(i)
end do
close(10)

do i=0,nside*nside*12-1
   call nest2ring(nside,i,j)
   M1(j)=M(i)
end do

print *,'Reading Compleate'
print *,'Enter the name of the output map:'
read(*,*)coutmap
 
open(unit=20,file=coutmap)
do i=0,nside*nside*12-1
!   print *,M(i)
   write(20,*)M1(i)
end do
close(20)

deallocate(M)
deallocate(M1)

stop
end
