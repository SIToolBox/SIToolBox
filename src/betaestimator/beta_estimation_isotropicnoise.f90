! Package : SI Toolkit
! Version : Beta / V1.0
! Date    : 12.01.2017

! Clebsch file must be generated by the code provided with this package.
! Otherwise it should be written in the exactly same format and the file should
! be a direct access file. 

! Function lm2n() :: m must be positive
! Function Smat() :: m values should be actual value not absolute values


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!           Generate Derivatives  (HM)              !!     
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine isotropicnoise(llmax,LMAX,clebschl1MAX,clebschlmax,samplenumber,nside, &
input_map_path,shape_factor_path,clebschpath,out_dir_path)
 
   use healpix_types
   use alm_tools
   use pix_tools
   use omp_lib

   integer :: i,j,k 
   integer :: llmax,LMAX
   integer :: nside,seed
   integer :: l2min,l2max
   integer :: m1max,m1min
   integer :: recno,r,h,l1,l2,m1,m2,MyLMAX

   real(dp) :: cleb,tempas

   real(dp), allocatable, dimension(:) :: Qr,Qi,Dr,Di,SMapr,SMapi        !
   real(dp), allocatable, dimension(:) :: RSMapr,RSMapi                  !
   real(dp), allocatable, dimension(:) :: Palmrdot,Palmidot              !  Map specific variables
   real(dp), allocatable, dimension(:) :: Qalmrdot,Qalmidot              !  
   real(dp), allocatable, dimension(:) :: Palmr,Malmr,Palmi,Malmi        !

   real(dp) :: Sum1

   real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)                      !
   real(dp), allocatable, dimension(:,:,:,:) :: PALMlldot                !  BiPOSH coefficients
   real(dp) :: ALMlli(0:LMAX,0:LMAX,0:llMAX,0:llMAX)                     !    
   real(dp), allocatable, dimension(:,:,:,:) :: PALMllidot               !

   real(dp) :: epsilon1

   real(sp), allocatable, dimension(:,:) :: Map2
   real(dp), allocatable, dimension(:,:) :: dw8
   real(sp), allocatable, dimension(:) :: Map
   real(dp), dimension(2) :: z


   integer :: samplenumber,ll,lloopmax,frstep,samplenumber1
   complex(spc), allocatable, dimension(:,:,:) :: alm
   integer :: repeat1,repl
   integer :: Npix
 
   real(dp) :: ProxyAl,fs(1:1050),beta(0:1),betai(0:1),betac(0:1),pbetadot(0:1)   !  Beta coeffifient specific variables
   real(dp) :: pbetaidot(0:1),pbetai(0:1),pbeta(0:1)                              !  

   real(dp) :: c_t1,c_t2,c_tf,c_ti

   real(sp), allocatable, dimension(:,:) :: cl,mcl
   real(dp),allocatable,dimension(:) :: Nl
   real(dp),allocatable,dimension(:) :: Clebs  

   character :: input_map_path*500, out_dir_path*500
   character :: shape_factor_path*500, clebschpath*500
   character :: pixelwindow*500

   real(dp) :: theta,thetax 
   real :: tempx
   nside = 512

   allocate(Clebs(0:35000000))
   allocate(cl(0:llmax,1:3))
   allocate(mcl(0:llmax,1:3))
   allocate(Nl(0:llmax))

   allocate(alm(1:3, 0:llmax, 0:llmax))
   allocate(Qr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Qi(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Dr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Di(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Palmrdot(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Palmidot(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Qalmrdot(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Qalmidot(0:(llmax+1)*(llmax+2)/2-1))
   allocate(SMapr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(SMapi(0:(llmax+1)*(llmax+2)/2-1))
   allocate(RSMapr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(RSMapi(0:(llmax+1)*(llmax+2)/2-1))

   allocate(Palmr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Malmr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Palmi(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Malmi(0:(llmax+1)*(llmax+2)/2-1))

   allocate(Map2(0:12*nside*nside-1,1:3))
   allocate(Map(0:12*nside*nside-1))  
   allocate(dw8(1:2*nside, 1:3))

   allocate(PALMlldot(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(PALMllidot(0:LMAX,0:LMAX,0:llMAX,0:llMAX))

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !!             Initiallize stepsize                    !!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    
   write(*,*)"input_map_name = ", trim(adjustl(input_map_path))
   print *,'Hi1'
   write(*,*)"shape_factor_path: ", trim(adjustl(shape_factor_path))
   write(*,*)'Hi2' 
   write(*,*)"out_dir_path: ", trim(adjustl(out_dir_path))
   write(*,*)'Hi3'
  
   input_map_path = trim(adjustl(input_map_path))
   shape_factor_path = trim(adjustl(shape_factor_path))
   epsilon1 = 0.01
   Npix = 12*nside*nside

   write(*,*)'Hihihihihi'
   write(*,*)input_map_path
   write(*,*)'hehehe'   

!   Read the map     
   open(unit=141,file=input_map_path)
   do i=0,Npix-1
      read(141,*)Map(i)
   end do
   close(unit=141)

  write(*,*)'HIiIIIIIIIIIIIII'   
  write(*,*)'input_map_path :',input_map_path
  write(*,*)'HIiIIIIIIIIIIIII'
 

   !  Read the fs file
   open(unit=1441,file= shape_factor_path)
   do i=0,llmax
      read(1441,*)k,fs(i)
      fs(i)= 0.01*fs(i)
   end do
   close(1441)
   write(*,*)'shape factor used :',shape_factor_path

   open(unit=1451,file='Planck2015TTlowP_totCls.dat')
   do i=2,llmax
     read(1451,*)temp,mcl(i,1),temp,temp,temp
   end do 

!   open(unit=145,file=pixelwindow)
!   do i=0,llmax
!     read(145,*)pixwin(i)
!   end do
!   close(unit=145)


   dw8 = 1.0_dp
   z = (-1.d0,1.d0)
   Map2(:,1)=map

   call map2alm(nside, llmax, llmax, map2, alm, z, dw8)
   alm(1,0,0) = 50.0
   alm(1,1,0) = 50.0
   alm(1,1,1) = 50.0

   call alm2cl(llmax, llmax, alm, cl)

   open(unit=144,file='Clh.d') 
   do i=0,llmax
      ALMll(0,0,i,i) = cl(i,1) 
      write(144,*)cl(i,1)
      Nl(i) = 0.0004   ! Initiallize noise matrix
   end do
   close(unit=144) 

   open(1,file=clebschpath, action='read',status="OLD")
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

   MyLMAX = 2


   open(unit=9169,file=trim(adjustl(out_dir_path))//'/betaVal.d') !trim(adjustl(out_dir_path))//'betaVal.d')

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !!             Initiallize the masses                  !!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   call initM(Malmr,Malmi,llmax,cl,Nl)
write(*,*)"Hi"
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !!  Initiallize Data. Also initiallise alm to Data for faster convergence  !!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   k = 0
   do i = 0,llmax
      do j = 0,i
         Qr(k)=real(alm(1,i,j))
         Qi(k)=aimag(alm(1,i,j))
         Dr(k) = Qr(k)
         Di(k) = Qi(k)
         k = k+1
      end do
   end do

   call calculateALM(Qr,Qi,LMAX,llmax,ALMll,ALMlli,Clebs)
write(*,*)'Hi 3'
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !!        Initial Potential energy (EVEN BEFORE LOOP STARTS)          !! 
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   call srand(time())                   !! Starting random number generator

   lloopmax =(llmax+1)*(llmax+2)/2-1

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !!              H. M. C. loop Begin                          !!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   epsilon1 =  0.1 !025 !0.005
   theta = 1.35120719195966
   MyLMAX = 2

   do j=0,1

     beta(j) = 0.0
     betai(j) = 0.0
     betac(j)  = 0.0

     do l1=2,llmax-2
       beta(j)  = beta(j)  + (ALMll(1,j,l1,l1+1)*fs(l1))/(cl(l1,1)*cl(l1,1))
       betai(j) = betai(j) + (ALMlli(1,j,l1,l1+1)*fs(l1))/(cl(l1,1)*cl(l1,1))
       betac(j)  = betac(j)+ fs(l1)*fs(l1)/(cl(l1,1)*cl(l1,1))
     end do
write(*,*)"Hi4"
     beta(j)=beta(j)/betac(j)
     betai(j)=betai(j)/betac(j)


     do l1=2,llmax-1
       ALMll(1,j,l1,l1+1)   = beta(j)*fs(l1)
       ALMll(1,j,l1+1,l1)   = beta(j)*fs(l1)
       ALMlli(1,j,l1,l1+1)  = betai(j)*fs(l1)
       ALMlli(1,j,l1+1,l1)  = betai(j)*fs(l1)
     end do
write(*,*)"Hi5"
   end do
   

   call srand(seed)
write(*,*)'Hi -- 2a -- this process'
   do samplenumber1=0,5000                                             ! Number of samples                           

!write(*,*)'Hi..1..'


     call initPM(Palmr,Palmi,Malmr,Malmi,llmax,int(10000.0*rand()))   ! Initiallizing momentum 
     call initbeta(pbeta,int(10000.0*rand()))                         !   
     call initbeta(pbetai,int(10000.0*rand()))                        !

     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     !!      The next part is the Hamiltonion dynamics               !!
     !!      This part should be repeted                             !!     
     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

     write(*,*)'Now Here'

     repl=4+int(10.0*rand(seed))
     do repeat1 = 0,repl      !! Number of steps in a single Hamiltonion is taken as random to avoid resonance 


       !! Just for precosion A_LM should not be more then 25% of C_l                      
       !! `` `` `` `` `` `` `` `` `` `` `` `` `` `` `` `` `` `` `` `` `` `` ``

         do i=1,MyLMax                                                                                      !
           do j=0,i                                                                                         !  
             do l1=2,llmax                                                                                  !
               l2min=l1                                                                                     ! 
               IF (Abs(i-l1).ge.l1) l2min=Abs(l1-i)                                                         !
               l2max=llmax                                                                                  !
               IF ((i+l1).lt.llmax) l2max=(i+l1)                                                            !
               do l2=l2min,l2max                                                                            !
                 if( abs(ALMll(i,j,l1,l2)) .gt. 0.25*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))) then     !
                   if(ALMll(i,j,l1,l2).ge.0) then                                                           !
                      flag = 1                                                                              !
                   else                                                                                     !
                      flag = -1                                                                             !
                   end if                                                                                   !
                   write(*,*) 'Err 1',i,j,l1,l2,ALMll(i,j,l1,l2)                                            !
                   ALMll(i,j,l1,l2) = 0.25*flag*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))                !
                 end if                                                                                     !
                 if( abs(ALMlli(i,j,l1,l2)) .gt. 0.25*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))) then    !
                   if(ALMlli(i,j,l1,l2).ge.0) then                                                          !
                      flag = 1                                                                              !
                   else                                                                                     !
                      flag = -1                                                                             !
                   end if
                   write(*,*)'Err 2',i,j,l1,l2,ALMll(i,j,l1,l2)
                   ALMlli(i,j,l1,l2) = 0.25*flag*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))
                 end if 
               end do
             end do
           end do
         end do

     thetax = theta

     write(*,*) 'Coming here'

do frstep=1,3


   if(frstep .eq. 1) then 
     theta = thetax
   else if(frstep .eq. 2) then
     theta = 1.0 - 2.0*thetax
   else
     theta = thetax
   end if  

!write(*,*)"Hi"

!$omp parallel do &
!$omp shared ( Qalmrdot, Palmr, Malmr, Qr, Qalmidot, &
!$omp  Palmi, Malmi, Qi, epsilon1,theta) &
!$omp private ( i, l, m )
         do i=0,lloopmax

           Qalmrdot(i) = Palmr(i)/Malmr(i)
           Qalmidot(i) = Palmi(i)/Malmi(i)

           Qr(i) = Qr(i) + Qalmrdot(i)*epsilon1*theta/2
           Qi(i) = Qi(i) + Qalmidot(i)*epsilon1*theta/2

           call n2lm(i,l,m)
           if(m.eq.0) then
             Qi(i) = 0.0
           end if
         end do
!$omp end parallel do

         do j=0,1
           beta(j)  = beta(j)  + pbeta(j)*epsilon1*theta/2.0
           betai(j) = betai(j) + pbetai(j)*epsilon1*theta/2.0
         end do

        do l1=2,llmax-1
        do j =0,1
          ALMll(1,j,l1,l1+1)   = beta(j)*fs(l1)
          ALMll(1,j,l1+1,l1)   = beta(j)*fs(l1)
          ALMlli(1,j,l1,l1+1)  = betai(j)*fs(l1)
          ALMlli(1,j,l1+1,l1)  = betai(j)*fs(l1)
        end do 
        end do

      call gauss_seidel(ALMll,ALMlli,Qr,Qi,SMapr,SMapi,RSMapr,RSMapi,llmax,LMAX,Clebs)  

!$omp parallel do &
!$omp shared ( Palmr, Palmi, Palmrdot, Palmidot, epsilon1, theta) &
!$omp private ( i, l, m )
        do i=0,lloopmax
          call n2lm(i,l,m)
          if(m.ne.0) then 
            Palmrdot(i)  = - 2.0*(Dr(i) - Qr(i))/Nl(l) + 2.0*RSMapr(i) 
            Palmidot(i)  = - 2.0*(Di(i) - Qi(i))/Nl(l) + 2.0*RSmapi(i) 
          else 
            Palmrdot(i)  = - 1.0*(Dr(i) - Qr(i))/Nl(l) + 1.0*RSmapr(i) 
            Palmidot(i)  = 0.0
          end if
        end do
!$omp end parallel do

      call calculateALM(Smapr,Smapi,lmax,llmax,PALMlldot,PALMllidot,Clebs)
 
        do l1=2,llmax-1
          if(abs(ALMll(0,0,l1,l1)).lt.1.0d-20) ALMll(0,0,l1,l1) = 1.0d-20
          ProxyAl = ALMll(0,0,l1,l1)

          PALMlldot(0,0,l1,l1) = PALMlldot(0,0,l1,l1)/2.0
          PALMllidot(0,0,l1,l1) = PALMllidot(0,0,l1,l1)/2.0
          do j=0,1
             PALMlldot(1,j,l1,l1+1) = PALMlldot(1,j,l1,l1+1)/2.0
             PALMllidot(1,j,l1,l1+1) = PALMllidot(1,j,l1,l1+1)/2.0
          end do
        end do   

        do j=0,1
          pbetadot(j) = 0
          pbetaidot(j)= 0
        end do
 
        do l1=2,llmax-2              
          PALMlldot(0,0,l1,l1) = (2.0*l1+1.0)/ProxyAl/2.0 + PALMlldot(0,0,l1,l1)
          l2 = l1+1
          do j=0,1
  pbetadot(j) = pbetadot(j) + 2.0*(-PALMlldot(1,j,l1,l1+1)+ &    ! 2* because we need to calculate PALMlldot(l1,l1+1) and (l1,l1-1) 
sqrt((2.0*l1+3.0)*(2.0*l1+1.0))*int((-1)**(l1+l2)) &
*ALMll(1,j,l1,l1+1)/ALMll(0,0,l1,l1)/ALMll(0,0,l2,l2)/2.0)*fs(l1)
  pbetaidot(j) = pbetaidot(j) + 2.0*(-PALMllidot(1,j,l1,l1+1)+ &
sqrt((2.0*l1+3.0)*(2.0*l1+1.0))*int((-1)**(l1+l2)) &
*ALMlli(1,j,l1,l1+1)/ALMll(0,0,l1,l1)/ALMll(0,0,l2,l2)/2.0)*fs(l1)
          end do
       end do                                                                 ! (-1)^j is ignored     


!$omp parallel do &
!$omp shared ( Palmr, Palmi, Palmrdot, Palmidot, Qi, epsilon1, theta) &
!$omp private ( i, l, m ) 
      do i=0,lloopmax
           Palmr(i) = Palmr(i) - Palmrdot(i)*epsilon1*theta
           Palmi(i) = Palmi(i) - Palmidot(i)*epsilon1*theta 
 
           call n2lm(i,l,m)
           if(m.eq.0) then
             Qi(i) = 0.0
           end if
      end do
!$omp end parallel do

      do j=0,1
         pbeta(j)  = pbeta(j)  - pbetadot(j)*epsilon1*theta
         pbetai(j) = pbetai(j) - pbetaidot(j)*epsilon1*theta
      end do



!$omp parallel do &
!$omp shared ( Qalmrdot, Palmr, Malmr, Qr, Qalmidot, Palmi, Malmi, Qi, &
!$omp epsilon1,theta) &
!$omp private ( i, l, m )

      do i=0,lloopmax
         Qalmrdot(i) = Palmr(i)/Malmr(i)
         Qalmidot(i) = Palmi(i)/Malmi(i)

         Qr(i) = Qr(i) + Qalmrdot(i)*epsilon1*theta/2.0
         Qi(i) = Qi(i) + Qalmidot(i)*epsilon1*theta/2.0

         call n2lm(i,l,m)

         if(m.eq.0) then
           Qi(i) = 0.0
         end if
      end do

!$omp end parallel do

      do j=0,1
         beta(j)  = beta(j)  + pbeta(j)*epsilon1*theta/2.0
         betai(j) = betai(j) + pbetai(j)*epsilon1*theta/2.0
      end do

      write(*,*)'This :',beta,betai
!      write(9169,*)beta(0),beta(1),betai(1)

end do
      write(9169,*)beta(0),beta(1),betai(1)

     betai(0) = 0.0                  ! betai(0) can not be nonzero 

      do l1=40,llmax
       if(abs(ALMll(0,0,l1,l1)) .lt. 0.001) then
           ALMll(0,0,l1,l1) = 0.001*ALMll(0,0,l1,l1)/abs(ALMll(0,0,l1,l1))
           write(*,*)'Error 3'
       end if
      end do

     write(*,*)'This is me'  
     end do

   write(*,*) 'I am Here'
   end do

end subroutine isotropicnoise


!!
!! Initiallize mass  for alm
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

subroutine initM(Malmr,Malmi,llmax,cl,Nl)

   use healpix_types

   integer :: llmax,i,l,m
   real(dp) :: Malmr(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: Malmi(0:(llmax+1)*(llmax+2)/2-1)
   real(sp) :: cl(0:llmax,1:3)
   real(dp) :: Nl(0:llmax)  

   do i=0,(llmax+1)*(llmax+2)/2-1
      call n2lm(i,l,m)
      if((abs(cl(l,1)-Nl(l))).gt.1.0d-5) then 
        Malmr(i) = 1.0/(abs(cl(l,1)-Nl(l)))+1.0/Nl(l)
        Malmi(i) = 1.0/(abs(cl(l,1)-Nl(l)))+1.0/Nl(l)
      else
        Malmr(i) = 1.0/(1.0d-5)+1.0/Nl(l)
        Malmi(i) = 1.0/(1.0d-5)+1.0/Nl(l)
      end if
   end do
   return
end subroutine


!!
!! Initiallize momentum for alm
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

subroutine initPM(Palmr,Palmi,Malmr,Malmi,llmax,j)

   use healpix_types
   use rngmod

   type(planck_rng) :: rng_handle
   real(dp) :: gauss,time

   integer :: llmax,i,j,inttime

   real(dp) :: Palmr(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: Palmi(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: Malmr(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: Malmi(0:(llmax+1)*(llmax+2)/2-1)

   call cpu_time(time)
   inttime = int(time)
   call rand_init(rng_handle,j,inttime)

   do i=0,(llmax+1)*(llmax+2)/2-1
      Palmr(i) = sqrt(Malmr(i))*rand_gauss(rng_handle)
      Palmi(i) = sqrt(Malmi(i))*rand_gauss(rng_handle)
   end do

end subroutine


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!          Gauss Scidel Method                      !!     
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine gauss_seidel(ALMll,ALMlli,bMap,bmapi,SMAP,SMAPi,RSMAP,RSMAPi,llmax,LMAX,Clebs) 

   use healpix_types
   use omp_lib

   integer :: i,j,Nmax,k
   integer :: il,im,jl,jm,recno
   integer :: iminMPI,imaxMPI,valperMPI
   integer :: myid,numprocs 
   integer :: endflag,MPItag
   integer :: flag
   integer :: lmin,locallmax
   integer :: localimmax,nthreads,iMaxThreads

   real(dp) :: test11,test11i
   real(dp) :: Sum1,Sum2,Smat,Smattot,Sum1i,Smati,Smatx
   real(dp) :: bMap(0:(llmax+1)*(llmax+2)/2-1),SMAP(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: bMapi(0:(llmax+1)*(llmax+2)/2-1),SMAPi(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: RSMAP(0:(llmax+1)*(llmax+2)/2-1), RSMAPi(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: SMAPold(0:(llmax+1)*(llmax+2)/2-1),SMAPiold(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
   real(dp) :: ALMlli(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
   real(dp) :: error,err(0:1000)
   real(dp) :: Clebs(0:35000000)

   flag = 0

   Nmax = (llmax+1)*(llmax+2)/2-1
   SMAPold = 0
   SMAPiold = 0


   iminMPI = 0 !myid*valperMPI
   imaxMPI = Nmax !(myid+1)*valperMPI-1
  
!$omp parallel do &
!$omp   shared ( bMap, ALMll, Clebs, Smap, bMapi, Smapi, llmax, iminMPI, imaxMPI ) &
!$omp   private ( i, il, im, recno, nthreads )

   do i=iminMPI,imaxMPI
     call n2lm(i,il,im)
     call Sii(0,0,il,il,im,llmax,recno)
     Smap(i) = bMap(i)/(ALMll(0,0,il,il)*Clebs(recno)*int((-1)**im))           !(-1)^im
     Smapi(i) = bMapi(i)/(ALMll(0,0,il,il)*Clebs(recno)*int((-1)**im))         !(-1)^im
   end do

!$omp end parallel do


!$omp parallel do &
!$omp shared ( iminMPI, imaxMPI, LMAX, llmax, ALMll, ALMlli, Clebs,bmap, &
!$omp bmapi, Smap, Smapi ) &
!$omp private ( i, Sum1, Sum1i, il, im, lmin, locallmax, jl, immin, &
!$omp localimmax, jm, j, SMat, SMati )

     do i=iminMPI,imaxMPI
       Sum1 = 0.0
       Sum1i= 0.0
       call n2lm(i,il,im)
       lmin = il - LMAX
       if(lmin<0) lmin = 0
       locallmax = il+LMAX
       if(locallmax.ge.llmax)locallmax = llmax-1
       do jl=lmin,locallmax
         immin =im-1       ! As for dopplar boost LMAX is just  LMAX = 1
         if(immin<-jl)immin = -jl
         localimmax = im+1   !As for dopplar boost LMAX =1  
         if(localimmax.ge.llmax)localimmax = llmax-1
         do jm=immin,localimmax
           call lm2n(jl,abs(jm),j)
           if(i.ne.j) then
            call Smat1(ALMll,il,im,jl,jm,LMAX,llMAX,SMat,Clebs)
            call Smat1i(ALMlli,il,im,jl,jm,LMAX,llMAX,SMati,Clebs)
            if(im .eq. jm) Smati = 0.0

            call Sii(0,0,jl,jl,jm,llmax,recno)
            SMatx = (ALMll(0,0,jl,jl)*Clebs(recno)*int((-1)**jm))   

            Sum1 = Sum1 + (bmap(j)*Smat - bmapi(j)*Smati)/Smatx
            Sum1i = Sum1i + (bmap(j)*Smati + bmapi(j)*Smat)/Smatx
           end if
          end do
       end do

!       call Smat1(ALMll,il,im,il,im,LMAX,llMAX,SMat,Clebs)

       call Sii(0,0,il,il,im,llmax,recno)
       SMat = (ALMll(0,0,il,il)*Clebs(recno)*int((-1)**im))

       Sum1  = Sum1/SMat   !**2         !! Need to check
       Sum1i = Sum1i/SMat  !**2

       if(il.lt.40) then
          Sum1  = 0.0
          Sum1i = 0.0
       end if

       RSMap(i) = (SMap(i)-Sum1)
       RSMapi(i)= (SMapi(i)-Sum1i)

     end do

!$omp end parallel do  

   return
end subroutine gauss_seidel


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine Smat1(ALMll,il,im,jl,jm,LMAX,llMAX,Smat,Clebs)

  use healpix_types
  integer :: il,im,jl,jm
  integer :: L,M,recno
  integer :: LMAX,llMAX
  real(dp) :: Sum1,Smat,cleb,clebi
  real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
  real(dp) :: Clebs(0:35000000)

  Sum1 =0.0

  do L=1,LMAX
       M= jm-im
       if(abs(il-jl).gt.L) then
         cleb = 0.0
       else if(L.gt.(il+jl)) then
         cleb = 0.0
       else
         if(M.lt.0) then
           call Sii(L,abs(M),il,jl,-im,llmax,recno)
           cleb = int((-1)**(il+jl-L))*Clebs(recno)
         else
           call Sii(L,abs(M),il,jl,-im,llmax,recno)
           cleb = Clebs(recno)
         end if

         if(L.eq.0) then
           Sum1 = Sum1 + ALMll(L,M,il,jl)*cleb*int((-1)**im)
         else
           Sum1 = Sum1 + ALMll(L,M,il,jl)*cleb*int((-1)**im)
         endif
       end if
  end do
  Smat = Sum1
  return

end subroutine Smat1



subroutine Smat1i(ALMll,il,im,jl,jm,LMAX,llMAX,Smat,Clebs) !,Clebsi)

  use healpix_types
  integer :: il,im,jl,jm
  integer :: L,M,recno
  integer :: LMAX,llMAX
  real(dp) :: Sum1,Smat,cleb,clebi
  real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
  real(dp) :: Clebs(0:35000000)

  Sum1 =0.0

  do L=1,LMAX
!    do M=1,L
!       if((im-jm).ne.M) then
!         cleb = 0.0
       M = jm-im
       if(abs(il-jl).gt.L) then
         cleb = 0.0
       else if(L.gt.(il+jl)) then
         cleb = 0.0
       else
!         call Sii(L,M,il,jl,-im,llmax,recno)
         if(M.gt.0) then
           call Sii(L,M,il,jl,-im,llmax,recno)
           cleb = Clebs(recno)
         else if(M.lt.0) then
           call Sii(L,abs(M),il,jl,-im,llmax,recno)
           cleb = int((-1)**(il+jl-L))*Clebs(recno)
         else 
           cleb = 0.0
         end if
 
         Sum1 = Sum1 + ALMll(L,M,il,jl)*cleb*int((-1)**im)
!         if((L.eq.0).and.(M.eq.0)) then
!         Sum1 = Sum1 + ALMll(L,M,il,jl)*(cleb - clebi*int((-1)**m))*int((-1)**im)
!         else
!           Sum1 = Sum1 + ALMll(L,M,il,jl)*(cleb - clebi*int((-1)**m))*int((-1)**im)
!         endif
       end if
!    end do
  end do
  Smat = Sum1

  return

end subroutine Smat1i

