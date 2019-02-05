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

subroutine anisotropicnoise(llmax,LMAX,clebschl1MAX,clebschlmax,nside, &
samplenumber,input_map_path,shape_factor_path,clebschpath,out_dir_path,maskpath, &
noisevar_path,Cl_path,mymask,pixelwindow)
 
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
   integer :: mymask

   real(dp) :: cleb,tempas

   real(dp), allocatable, dimension(:) :: Qr,Qi,Dr,Di,SMapr,SMapi        !
   real(dp), allocatable, dimension(:) :: RSMapr,RSMapi                  !
   real(dp), allocatable, dimension(:) :: Palmrdot,Palmidot              !  Map specific vaariables
   real(dp), allocatable, dimension(:) :: Qalmrdot,Qalmidot              !  
   real(dp), allocatable, dimension(:) :: Palmr,Malmr,Palmi,Malmi        !

   real(sp), allocatable, dimension(:) :: NoiseMap
   real(sp), allocatable, dimension(:) :: MaskMap


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


   integer :: samplenumber,ll,lloopmax,frstep
   complex(spc), allocatable, dimension(:,:,:) :: alm, dfalm
   integer :: repeat1,repl
   integer :: Npix
 
   real(dp) :: ProxyAl,fs(1:1050),beta(0:1),betai(0:1),betac(0:1),pbetadot(0:1)   !  Beta coeffifient specific variables
   real(dp) :: pbetaidot(0:1),pbetai(0:1),pbeta(0:1)                   !  

   real(dp) :: c_t1,c_t2,c_tf,c_ti

   real(sp), allocatable, dimension(:,:) :: cl,mcl
   real(dp),allocatable,dimension(:) :: Nl,pixwin
   real(dp),allocatable,dimension(:) :: Clebs  
   character :: fileinput*500, input_map_path*500, out_dir_path*500
   character :: shape_factor_path*500,clebschpath*500,maskpath*500
   character :: noisevar_path*500,Cl_path*500,pixelwindow*500
   real(dp), allocatable, dimension(:) :: dfQr,dfQi


   real(dp) :: Mbeta

   real(dp) :: theta,thetax 
   real :: tempx

   nside = 512

   allocate(Clebs(0:35000000))
   allocate(cl(0:llmax,1:3))
   allocate(mcl(0:llmax,1:3))
   allocate(Nl(0:llmax))
   allocate(pixwin(0:llmax))


   allocate(alm(1:3, 0:llmax, 0:llmax))
   allocate(dfalm(1:3, 0:llmax, 0:llmax))
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
   allocate(NoiseMap(0:12*nside*nside-1))
   allocate(MaskMap(0:12*nside*nside-1))

   allocate(dfQr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(dfQi(0:(llmax+1)*(llmax+2)/2-1))


   allocate(PALMlldot(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(PALMllidot(0:LMAX,0:LMAX,0:llMAX,0:llMAX))

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !!             Initiallize stepsize                    !!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

write(*,*)'#############################################'
print *, "Enter full path to input map"
write(*,*)"input_map_name = ", trim(adjustl(input_map_path))

print *, "Enter full path to shape factor file"
write(*,*)"shape_factor_path: ", trim(adjustl(shape_factor_path))
 
print *, "Enter path to directory to store output."
write(*,*)"out_dir_path: ", trim(adjustl(out_dir_path))

print *,'Enter the path of Cl'
write(*,*)"Cl path: ",trim(adjustl(Cl_path))

print *,'Enter the mask path'
write(*,*)"mask path: ",trim(adjustl(maskpath))

print *,'Enter the noise standard deviation path'
write(*,*)"Noise standard deviation path: ",trim(adjustl(noisevar_path))

write(*,*)'######################################'
   write(*,*)'input_map_path :',input_map_path


   epsilon1 = 0.01
   Npix = 12*nside*nside

   !   Read the map     
   open(unit=141,file=input_map_path)
   do i=0,Npix-1
      read(141,*)Map(i)
   end do
   close(unit=141)
   write(*,*)'input_map_path :',input_map_path
write(*,*)'Done'   
   !  Read the fs file
   open(unit=1441,file=shape_factor_path)
   do i=0,llmax
      read(1441,*)k,fs(i)
      fs(i)= 0.01*fs(i)
   end do
   close(1441)
   write(*,*)'shape factor used :',shape_factor_path

   open(unit=1451,file=Cl_path)
   do i=2,llmax
     read(1451,*)temp,mcl(i,1),temp,temp,temp
   end do 

   write(*,*)'Here 179'

   open(unit=144,file=noisevar_path)
   do i=0,Npix-1
     read(144,*)NoiseMap(i)
   end do
   close(unit=144)
   
   write(*,*)'Here 187',pixelwindow

   open(unit=145,file=pixelwindow)
   do i=0,llmax
     read(145,*)pixwin(i)
   end do
   close(unit=145)

    write(*,*)'Here 193'

   if(mymask .eq. 1) then
     open(unit=146,file=maskpath)
     do i=0,Npix-1
       read(146,*)MaskMap(i)
     end do
     close(146)


     do i=0,Npix-1
       NoiseMap(i) = NoiseMap(i) + 9999999.9*(1.0-MaskMap(i))
     end do
   end if

   write(*,*)'Here' 

   open(unit=232,file='Testcl.d')
   

   dw8 = 1.0_dp
   z = (0.d0,0.d0)
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

   write(*,*)'The value of Beta is in :',trim(adjustl(out_dir_path))
   open(unit=9169,file=trim(adjustl(out_dir_path))//'/betaVal.d')

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !!             Initiallize the masses                  !!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   call initM(Malmr,Malmi,llmax,cl,Nl)

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
     Mbeta = 0
     do l1=2,llmax-2
       beta(j)  = beta(j)  + (ALMll(1,j,l1,l1+1)*fs(l1))/(cl(l1,1)*cl(l1,1))
       betai(j) = betai(j) + (ALMlli(1,j,l1,l1+1)*fs(l1))/(cl(l1,1)*cl(l1,1))
       betac(j)  = betac(j)+ fs(l1)*fs(l1)/(cl(l1,1)*cl(l1,1))

       Mbeta = Mbeta + 1.0*sqrt((2.0*l1+3.0)*(2.0*l1+1.0)) &
             /ALMll(0,0,l1,l1)/ALMll(0,0,l1+1,l1+1)/2.0*fs(l1)*fs(l1+1)
     end do

     beta(j)=beta(j)/betac(j)
     betai(j)=betai(j)/betac(j)


     write(*,*)'Value of BETA : ',beta,betai

     do l1=2,llmax-1
       ALMll(1,j,l1,l1+1)   = beta(j)*fs(l1)
       ALMll(1,j,l1+1,l1)   = beta(j)*fs(l1)
       ALMlli(1,j,l1,l1+1)  = betai(j)*fs(l1)
       ALMlli(1,j,l1+1,l1)  = betai(j)*fs(l1)
     end do
   end do
    
   Mbeta = abs(Mbeta)*2

   call srand(seed)
   do samplenumber=0,5000                                             ! Number of samples                           

     call initPM(Palmr,Palmi,Malmr,Malmi,llmax,int(10000.0*rand()))   ! Initiallizing momentum 
     call initbeta(pbeta,int(10000.0*rand()))                         !   
     call initbeta(pbetai,int(10000.0*rand()))                        !

     pbeta  = sqrt(Mbeta)*pbeta
     pbetai = sqrt(Mbeta)*pbetai


     write(*,*)'Sample number :',samplenumber
     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     !!      The next part is the Hamiltonion dynamics               !!
     !!      This part should be repeted                             !!     
     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

     repl=2+int(10.0*rand(seed))
     do repeat1 = 0,repl      !! Number of steps in a single Hamiltonion is taken as random to avoid resonance 

        write(*,*)'This is :',repeat1,repl
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

do frstep=1,3


   if(frstep .eq. 1) then 
     theta = thetax
   else if(frstep .eq. 2) then
     theta = 1.0 - 2.0*thetax
   else
     theta = thetax
   end if  



!$omp parallel do &
!$omp shared ( Qalmrdot, Palmr, Malmr, Qr, Qalmidot, &
!$omp Palmi, Malmi, Qi, epsilon1,theta) &
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



!   k=0
!   do i = 0,llmax
!     do j = 0,i
!       alm(1,i,j) = cmplx(Qr(k),Qi(k))
!       k = k + 1
!     end do
!  end do
!
!   call alm2cl(llmax, llmax, alm, cl)
   
!   write(232,"(9999(E20.5))")cl(:,1)

         do j=0,1
           beta(j)  = beta(j)  + pbeta(j)*epsilon1*theta/2.0/Mbeta
           betai(j) = betai(j) + pbetai(j)*epsilon1*theta/2.0/Mbeta
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
          dfalm(1,l,m) = pixwin(l)*cmplx(Dr(i)-Qr(i), Di(i)-Qi(i))
!         if(m.ne.0) then 
!            Palmrdot(i)  = - 2.0*(Dr(i) - Qr(i))/Nl(l) + 2.0*RSMapr(i) 
!            Palmidot(i)  = - 2.0*(Di(i) - Qi(i))/Nl(l) + 2.0*RSmapi(i) 
!          else 
!            Palmrdot(i)  = - 1.0*(Dr(i) - Qr(i))/Nl(l) + 1.0*RSmapr(i) 
!            Palmidot(i)  = 0.0
!          end if
        end do
!$omp end parallel do



     call alm2map(nside, llmax, llmax, dfalm, map2 )


!$omp   parallel do &
!$omp   shared ( NoiseMap, Map2 ) &
!$omp   private ( i, l, m, noipix )
     do i = 0,12*nside*nside-1
       noipix = NoiseMap(i)
       Map2(i,1)=Map2(i,1)/noipix/noipix*(Npix*Npix*3/3.1416)  !250329.0 !/0.000004
       if(noipix > 1000) then
          Map2(i,1)=0.0
       end if
     end do
!$omp end parallel do

     call map2alm(nside, llmax, llmax, map2, dfalm, z, dw8 )


!$omp   parallel do &
!$omp   shared ( dfQr, dfQi, dfalm ) &
!$omp   private ( i, l, m )
     do i = 0,lloopmax
       call n2lm(i,l,m)
       dfQr(i)=real(dfalm(1,l,m))
       dfQi(i)=aimag(dfalm(1,l,m))
     end do
!$omp end parallel do



!$omp   parallel do &
!$omp   shared ( Palmrdot, Palmidot, SMapr, SMapi, dfQr, dfQi ) &
!$omp   private ( i, l, m )


       do i=0,lloopmax
         call n2lm(i,l,m)
         if(m.ne.0) then
           Palmrdot(i)  = 2.0*dfQr(i) -2.0*RSMapr(i) !+ 2.0*dfQr(i) !(Dr(i)  - Qr(i))/Nl(l) 
           Palmidot(i)  = 2.0*dfQi(i) - 2.0*RSMapi(i) !+ 2.0*dfQi(i) !(Di(i) - Qi(i))/Nl(l) 

         else
           Palmrdot(i)  =  1.0*dfQr(i) - 1.0*RSMapr(i) !+ 1.0*dfQr(i) !(Dr(i) - Qr(i))/Nl(l)
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
          j = 1
          pbetadot(j) = pbetadot(j) - 4.0*(-((1.0)**j)*PALMlldot(1,j,l1,l1+1)+ &  
            sqrt((2.0*l1+3.0)*(2.0*l1+1.0))*int((-1)**(l1+l2)) &
            *ALMll(1,j,l1,l1+1)/ALMll(0,0,l1,l1)/ALMll(0,0,l2,l2)/2.0)*fs(l1)
          pbetaidot(j) = pbetaidot(j) - 4.0*(-((1.0)**j)*PALMllidot(1,j,l1,l1+1)+ &
            sqrt((2.0*l1+3.0)*(2.0*l1+1.0))*int((-1)**(l1+l2)) &
            *ALMlli(1,j,l1,l1+1)/ALMll(0,0,l1,l1)/ALMll(0,0,l2,l2)/2.0)*fs(l1)

          j = 0
          pbetadot(j) = pbetadot(j) - 2.0*(-((1.0)**j)*PALMlldot(1,j,l1,l1+1)+ &    
            sqrt((2.0*l1+3.0)*(2.0*l1+1.0))*int((-1)**(l1+l2)) &
            *ALMll(1,j,l1,l1+1)/ALMll(0,0,l1,l1)/ALMll(0,0,l2,l2)/2.0)*fs(l1)
          pbetaidot(j) = 0

       end do

!$omp parallel do &
!$omp shared ( Palmr, Palmi, Palmrdot, Palmidot, Qi, epsilon1, theta) &
!$omp private ( i, l, m ) 
      do i=0,lloopmax
           Palmr(i) = Palmr(i) + Palmrdot(i)*epsilon1*theta
           Palmi(i) = Palmi(i) + Palmidot(i)*epsilon1*theta 
 
           call n2lm(i,l,m)
           if(m.eq.0) then
             Qi(i) = 0.0
           end if
      end do
!$omp end parallel do

      do j=0,1
         pbeta(j)  = pbeta(j)  + pbetadot(j)*epsilon1*theta
         pbetai(j) = pbetai(j) + pbetaidot(j)*epsilon1*theta
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
         beta(j)  = beta(j)  + pbeta(j)*epsilon1*theta/2.0/Mbeta
         betai(j) = betai(j) + pbetai(j)*epsilon1*theta/2.0/Mbeta
      end do
end do




   k=0
   do i = 0,llmax
     do j = 0,i
       alm(1,i,j) = cmplx(Qr(k),Qi(k))
       k = k + 1
     end do
  end do

   call alm2cl(llmax, llmax, alm, cl)

   write(232,"(9999(E20.5))")cl(:,1)




      betai(0) = 0.0                  ! betai(0) can not be nonzero 

      do l1=40,llmax
       if(abs(ALMll(0,0,l1,l1)) .lt. 0.001) then
           ALMll(0,0,l1,l1) = 0.001*ALMll(0,0,l1,l1)/abs(ALMll(0,0,l1,l1))
           write(*,*)'Error 3'
       end if
      end do

     end do

write(9169,*)beta,betai(1)

   end do

end subroutine anisotropicnoise


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!subroutine Smat1(ALMll,il,im,jl,jm,LMAX,llMAX,Smat,Clebs)
!
!  use healpix_types 
!  integer :: il,im,jl,jm
!  integer :: L,M,recno
!  integer :: LMAX,llMAX
!  real(dp) :: Sum1,Smat,cleb,clebi
!  real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
!  real(dp) :: Clebs(0:35000000)
!
!  Sum1 =0.0
!
!  do L=0,LMAX
!       M= jm-im
!       if(abs(il-jl).gt.L) then 
!         cleb = 0.0
!       else if(L.gt.(il+jl)) then
!         cleb = 0.0
!       else
!         if(M.lt.0) then 
!           call Sii(L,abs(M),il,jl,-im,llmax,recno)
!           cleb = int((-1)**(il+jl-L))*Clebs(recno)
!         else
!           call Sii(L,abs(M),il,jl,-im,llmax,recno)
!          cleb = Clebs(recno)
!         end if
!
!         if(L.eq.0) then
!           Sum1 = Sum1 + ALMll(L,M,il,jl)*cleb*int((-1)**im)
!         else
!           Sum1 = Sum1 + ALMll(L,M,il,jl)*cleb*int((-1)**im)
!        endif
!       end if
!  end do
!  Smat = Sum1
!  return
!
!end subroutine Smat1

