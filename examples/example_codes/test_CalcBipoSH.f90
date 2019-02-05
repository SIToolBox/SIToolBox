! Package : SI Toolkit
! Version : Beta / V1.0
! Date    : 01.04.2017   (UW Madison)
! Code    : Example

! Date    : 03.07.2017   (Example Code, written in UW Madison)

 
   use healpix_types
   use alm_tools
   use pix_tools
   use omp_lib

   integer,parameter :: LMAX = 2
   integer,parameter :: llMAX = 1024    ! We take lmax as llmax to differenciate it from LMAX 
   integer,parameter :: clbllMAX = 1024
   integer,parameter :: clbLMAX = 2
   integer :: nside = 512               ! Map Nside
   integer :: i,j,k,kk                  ! Variables used in loops etc
   integer :: llmain                    ! l_max (1024) and L_max (2)   of A^{L,M}_{l,l+d}
   integer :: l2min,l2max               ! l2 can Vary within l-L to l+L in A^{L,M}_{l1,l2}
   integer :: m1max,m1min               ! Range of values that M can take
   integer :: recno,r,h,l1,l2,m1  

   real(dp),allocatable,dimension(:,:) :: Clo
   real(sp), allocatable, dimension(:,:) :: Map2
   real(dp) :: cleb
   real(dp),allocatable,dimension(:) :: Clebs
   real(dp), allocatable, dimension(:) :: Qr,Qi                            ! Variables for updating Map alm's  
   real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,-LMAX:LMAX)  
   real(dp) :: ALMlli(0:LMAX,0:LMAX,0:llMAX,-LMAX:LMAX) 
   real(dp), dimension(2) :: z
   real(dp), allocatable, dimension(:,:) :: dw8

   complex(spc), allocatable, dimension(:,:,:) :: alm

   character(2) :: ci,cj,cl1
   character :: fileinput*500,filename*100,filenamei*100 


   !!
   !! Allocating the arrrays
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 
   allocate(Clebs(0:35000000))
   allocate(Qr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Qi(0:(llmax+1)*(llmax+2)/2-1))
   allocate(dw8(1:2*nside, 1:3))
   allocate(Map2(0:12*nside*nside-1,1:3))
   allocate(Clo(0:llmax,50))
   allocate(alm(1:3, 0:llmax, 0:llmax))


   Npix = 12*nside*nside

   !!
   !!   Read the map file
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   write(*,*)"Enter Filename"
   read(*,*)fileinput 

   open(unit=141,file=fileinput)
   do i=0,Npix-1
     read(141,*)Map2(i,1)
   end do
   close(unit=141)


   dw8 = 1.0_dp
   z = (-1.d0,1.d0)


   call map2alm(nside, llmax, llmax, map2, alm, z, dw8)


   open(1,file='/home/sdas33/DATA/Final_beta_estimation/clebsch/clebs.dat', action='read',status="OLD")
   do i=0,LMAX
     do k=0,llmax
       l1=k           ! k --> l1  
       l2min=l1
       IF (Abs(i-k).ge.k) l2min=Abs(k-i)
       l2max=llmax
       IF ((i+k).lt.llmax) l2max=(i+k)
       do h=l2min,l2max
         l2=h         ! h --> l2
         do j=0,i
           m1max = min(l1,l2-j)
           m1min = max(-l1,-l2-j)
           do r=1,int(m1max-m1min)+1 
             m1=int(m1min+float(r-1)) 
             call Sii(i,j,k,h,m1,llmax,recno)
             read(1,*)recno,cleb
             Clebs(recno)=cleb  
           enddo 
         enddo
       enddo
     enddo
   enddo
   close(1)


   write(*,*)"Hi.." 

   MyLMax = 2
   l1 =0
   do i=0,MyLMax
     do j=0,i
       do kk=0,i
         l1 = l1+1
         write(ci,"(I1)")i 
         write(cj,"(I1)")j
         write(cl1,"(I1)")kk
         filename  = 'BIPOSH/SI101AR_'//trim(ci)//trim(cj)//'_ll'//trim(cl1)//'.d'
         filenamei = 'BIPOSH/SI101AI_'//trim(ci)//trim(cj)//'_ll'//trim(cl1)//'.d'
         write(*,*)filename,filenamei
         open(unit=8154+l1,file=filename)
         open(unit=9168+l1,file=filenamei)
       end do
     end do
   end do


   !!
   !!  Initiallize Data. Also initiallise alm to Data for faster convergence  
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   k = 0
   do i = 0,llmax
      do j = 0,i
         Qr(k)=real(alm(1,i,j))
         Qi(k)=aimag(alm(1,i,j))
         k = k+1
      end do
   end do


   call CalcBipoSH(Qr,Qi,LMAX,llmax,ALMll,ALMlli,Clebs)


   l1 =0
   do i=0,MyLMax
     do j=0,i
       do kk=0,i
         do k=0,llmax-3
           Clo(k,1) = ALMll(i,j,k,kk)
           Clo(k,2) = ALMlli(i,j,k,kk)
           write(*,*)i,j,k,kk,ALMll(i,j,k,kk),ALMlli(i,j,k,kk)
         end do
         l1 = l1+1
         write(8154+l1,*)Clo(:,1)
         write(9168+l1,*)Clo(:,2)
       end do
     end do
   end do

   l1 =0
   do i=0,MyLMax
     do j=0,i
       do kk=0,i
          l1 = l1+1
          close(unit=8154+l1)
          close(unit=9168+l1)
       end do
     end do
   end do

end program !subroutine generate_derivative

