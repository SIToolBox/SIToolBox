use healpix_types
use fitstools, only:input_map


real(dp),allocatable,dimension(:,:) :: M
character*20 :: inmap,outmap
integer :: i
integer ::nside

print *,'Enter Nside for the map'
read(*,*)nside
allocate(M(0:nside*nside*12 -1,1:1))
print *,'Enter the input map'
read(*,*)inmap
call input_map(inmap,M,nside*nside*12,1)
print *,'Successful conversion'
print *,'Enter the output file name'
read(*,*)outmap

open(unit=10,file=outmap)
do i=0,nside*nside*12-1
   write(10,*)M(i,1)
end do
close(10)

stop
end
