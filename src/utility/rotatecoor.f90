use healpix_types
use coord_v_convert, only: coordsys2euler_zyz
use alm_tools

real(dp) :: map(0:12*512*512-1),z(1:2),psi,theta,phi
real(dp), allocatable,  dimension(:,:) :: dw8
complex(dpc),allocatable,dimension(:,:,:) :: alm
real(DP), dimension(:,:), allocatable :: plm 
!real(dp),allocatable,dimension(:,:) ::cl
character*20 fmap,fCl
character :: InC,OutC


allocate(dw8(1:1024,1:1))
dw8=1.0_dp
allocate(alm(1:1, 0:1024, 0:1024))
allocate(plm(0:12*512*512-1,1:3)) 
!allocate(cl(1:1024,1:1))

print *,'Enter the file contaning file:'
read(*,*)fmap

z(1)=0.0_dp
z(2)=0.0_dp

open(unit=3,file=fmap)

do 10 i=0,12*512*512-1
   read(3,*)map(i)
10 continue
close(unit=3)

print *,'Enter the input coordinate system (G / E / C / Q)'
print *,'   G = Galactic'
print *,'   E = Ecliptic'
print *,'   C = Celestial'
print *,'   Q = Equatorial'
print *,'Default value G'
read(*,'(a)')InC

if(InC .ne. 'E' .and. InC .ne. 'C' .and. Inc .ne. 'Q') then 
  print *, 'Using default value'
  Inc = 'G'
end if

print *,'Enter the output coordinate system (G / E / C / Q)'
print *,'   G = Galactic'
print *,'   E = Ecliptic'
print *,'   C = Celestial'
print *,'   Q = Equatorial'
print *,'Default value E'
read(*,'(a)')OutC

if(OutC .ne. 'G' .and. OutC .ne. 'C' .and. Outc .ne. 'Q') then 
  print *, 'Using default value'
  OutC = 'E'
end if


print *,'Enter the file for writing the map'
read(*,*)fcl

alm = 0.0
call map2alm(512,1024,1024,map(0:12*512*512-1), alm ,z,dw8)
deallocate(dw8)

!call coordsys2euler_zyz(2000.0_dp,2000.0_dp,'G','E',psi,theta,phi)
call coordsys2euler_zyz(2000.0_dp,2000.0_dp,InC,OutC,psi,theta,phi)

call rotate_alm(1024,alm,psi,theta,phi)

!call plm_gen(512,1024,1024, plm) 
!call alm2cl(1024,1024,alm,cl)
call alm2map(512, 1024, 1024, alm, map(0:12*512*512-1))!, plm) 

open(unit=4, file=fCl)
do 20 i=0,12*512*512-1
   write(4,*)map(i)
20 continue
close(unit=4)

stop
end


