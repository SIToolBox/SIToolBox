! Clebsch file must be generated by the code provided with this package.
! Otherwise it should be written in the exactly same format and the file should
! be a direct access file. 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!           Generate Derivatives  (HM)              !!     
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine nonoise(llmax,LMAX,clebschl1MAX,clebschlmax, &
samplenumber,nside,fileinput,filefs,fileclebsch,chainpath)
 
   use healpix_types
   use alm_tools
   use pix_tools
   include 'mpif.h'

   ! Importent parameters 
   integer :: llmax,LMAX                      ! 1024, 2  
   integer :: nside                           ! 512

   ! Required for Reading Clebsch
   integer :: i,j,k                           ! Required for Reading Clebsch 
   integer :: l2min,l2max
   integer :: m1max,m1min
   integer :: recno,r,h,l1,l2,m1,m2 
   real(dp) :: cleb                           
   real(dp),allocatable,dimension(:) :: Clebs  

   ! Map quantities
   real(dp), allocatable, dimension(:) :: Qr,Qi    ! Real and img part of alm of a  Map
   real(sp), allocatable, dimension(:,:) :: Map2
   real(dp), allocatable, dimension(:,:) :: dw8    ! Required for map2alm 
   real(sp), allocatable, dimension(:) :: Map
   real(dp), dimension(2) :: z                     ! Required for map2alm
   complex(spc), allocatable, dimension(:,:,:) :: alm

   ! BipoSH Coefficients 
   real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)          ! BipoSH coefficients calculated in different steps 
   real(dp), allocatable, dimension(:,:,:,:) :: ALMll_old    ! BipoSH Cofficientss from Map
   real(dp) :: ALMlli(0:LMAX,0:LMAX,0:llMAX,0:llMAX)         ! BipoSH coefficients calculated in different steps   
   real(dp), allocatable, dimension(:,:,:,:) :: ALMlli_old   ! BipoSH Coefficients from Map 

   ! Code specific variables 
   real(dp) :: Sum1,ProxyAl
   real(dp) :: epsilon1
   real(dp) :: theta,thetax
   integer :: samplenumber,maxsample
   integer :: Almin,Almax
   integer :: repeat1,repl,frindex
   integer :: Npix                                           ! 12*nside^2. Number of pixels in the map
 
   ! Beta and its momentum, force etc. 
   real(dp) :: fs(1:2050),beta(0:1),betai(0:1),pbetadot(0:1),llval(1:2050)   !fs() is the shape factor. Must be stored in HS format 
   real(dp) :: pbetaidot(0:1),pbetai(0:1),pbeta(0:1),betac(0:1),betaci(0:1)
   real(dp) :: pbetadot1(0:1),pbetaidot1(0:1)
   real(dp) :: pbetadot2(0:1),pbetaidot2(0:1)

   ! Variables for calculaing CPU time
   real(dp) :: c_t1,c_t2
   real(sp), allocatable, dimension(:,:) :: cl
   character :: fileinput*500
   character :: filefs*500   
   character :: fileclebsch*500
   character :: chainpath*500,chainfile*500

   ! Allocate different Arrays
   allocate(Clebs(0:35000000))
   allocate(cl(0:llmax,1:3))
   allocate(alm(1:3, 0:llmax, 0:llmax))
   allocate(Qr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Qi(0:(llmax+1)*(llmax+2)/2-1))
   allocate(ALMll_old(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(Map2(0:12*nside*nside-1,1:3))
   allocate(Map(0:12*nside*nside-1))  
   allocate(dw8(1:2*nside, 1:3))
   allocate(ALMlli_old(0:LMAX,0:LMAX,0:llMAX,0:llMAX))

   Npix = 12*nside*nside

   ! @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@!

   ! Read the map     
   open(unit=141,file=fileinput)
   do i=0,Npix-1
      read(141,*)Map(i)
   end do
   close(unit=141)
   write(*,*)'Map filename :',fileinput
   
   !  Read the fs file
   Sum1 = 1.0
   open(unit=1441,file=filefs)
   do i=0,llmax
      Sum1 = -Sum1
      read(1441,*)llval(i),fs(i)
      fs(i)= 0.01*fs(i)
   end do
   close(1441)
   write(*,*)'fs filename :',filefs

   !  Read the Clebschs. This must be a direct access file generated thrugh the Clebsch ganeeration package
   open(1,file=fileclebsch,access='direct',recl=64,action='read',status="OLD")
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
             read(1,rec=recno)cleb
             Clebs(recno)=cleb
           enddo
         enddo
       enddo
     enddo
   enddo
   close(1)
   write(*,*)'Clebsch Gordon coefficients filename :',fileclebsch 



   dw8 = 1.0_dp
   z = (-1.d0,1.d0)
   Map2(:,1)=Map

   call map2alm(nside, llmax, llmax, map2, alm, z, dw8)
   alm(1,0,0) = 50.0
   alm(1,1,0) = 50.0
   alm(1,1,1) = 50.0

   call alm2cl(llmax, llmax, alm, cl)

   chainfile = trim(chainpath)//'/beta.d'
   open(unit=9171,file=chainfile)



   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !!  Initiallize Data. Also initiallise alm to Data for faster convergence  !!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   k = 0
   do i = 0,llmax
      do j = 0,i
         Qr(k)=real(alm(1,i,j))
         Qi(k)=aimag(alm(1,i,j))
         k = k+1
      end do
   end do


   call calculateALM(Qr,Qi,LMAX,llmax,ALMll,ALMlli,Clebs)


   do i=0,LMAX
     do k=0,llmax
       l1=k               ! k --> l1  

       l2min=l1
       IF (Abs(i-k).ge.k) l2min=Abs(k-i)
       l2max=llmax
       IF ((i+k).lt.llmax) l2max=(i+k)
       do h=l2min,l2max
         l2=h         ! h --> l2
         do j=0,i
            
            if(i.eq.0) then
               ALMll_old(i,j,k,h)  = ALMll(i,j,k,h)
               ALMlli_old(i,j,k,h) = ALMlli(i,j,k,h)
            else
               ALMll_old(i,j,k,h)  = ALMll(i,j,k,h)
               ALMlli_old(i,j,k,h) = ALMlli(i,j,k,h)
            end if    
         end do
       end do
     end do
   end do


   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !!        Starting the random number generator             !!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   call srand(time())                   !! Starting random number generator
   epsilon1 =  0.1 !025 !0.005
   theta = 1.35120719195966
   maxsample =  samplenumber
   write(*,*)' .. Hi ... '

   ! @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ !

   ! Initiallizing beta using a Minimum Variance estimtor. At this point one can
   ! note that Minimum Variance estimator of beta is a point where the Chi^2 is
   ! minimum. The formula for minimum variance estimator can be calculaated
   ! by setting the derivative of Chi^2 with respoect to beta to 0
  
   do j=0,1

     beta(j) = 0.0
     betai(j) = 0.0
     betac(j)  = 0.0

     do l1=2,llmax-2
       beta(j)  = beta(j)  + (ALMll(1,j,l1,l1+1)*fs(l1))/(cl(l1,1)*cl(l1,1))     
       betai(j) = betai(j) + (ALMlli(1,j,l1,l1+1)*fs(l1))/(cl(l1,1)*cl(l1,1))
       betac(j)  = betac(j)+ fs(l1)*fs(l1)/(cl(l1,1)*cl(l1,1))
     end do

     beta(j)=beta(j)/betac(j)
     betai(j)=betai(j)/betac(j)

     do l1=2,llmax
       ALMll(1,j,l1,l1+1)   = beta(j)*fs(l1)
       ALMll(1,j,l1,l1-1)   = beta(j)*fs(l1)
       ALMlli(1,j,l1,l1+1)  = betai(j)*fs(l1)
       ALMlli(1,j,l1,l1-1)  = betai(j)*fs(l1)
     end do
   end do

   betai(0) =0.0     ! Betai should be set to 0. Otherwise small error will
                     ! increase to provide it some random distribution which is
                     ! not real 

   write(9171,*)'Beta_r0     ','Beta_r1    ','Beta_i1'
   write(9171,*)beta,betai(1),maxsample


   do samplenumber=0,maxsample 
     write(*,*) samplenumber
     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     !!            Initiallize random momentum                  !!
     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 

      call initbeta(pbeta,int(10000.0*rand()))
      call initbeta(pbetai,int(10000.0*rand()))

     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     !!      The next part is the Hamiltonion dynamics               !!
     !!      This part should be repeted                             !!     
     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

     c_t2 = c_t1 
     call cpu_time(c_t1)


     repl=int(8.0*rand())
     do repeat1 = 0,8+repl     !! Number of steps in a single Hamiltonion is taken as random to avoid resonance 


       !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
       !!!             Just for precosion A_LM should not be more then 25% of C_l                      !!
       !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 

       !! Block  start

         do i=1,MyLMax
           do j=0,i
             do l1=2,llmax
               l2min=l1
               IF (Abs(i-l1).ge.l1) l2min=Abs(l1-i)
               l2max=llmax
               IF ((i+l1).lt.llmax) l2max=(i+l1)
               do l2=l2min,l2max
                 if( abs(ALMll(i,j,l1,l2)) .gt. 0.75*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))) then
                   write(*,*)'Wrong',abs(ALMll(i,j,l1,l2)),0.75*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))
                   if(ALMll(i,j,l1,l2).ge.0) then
                      flag = 1
                   else
                      flag = -1
                   end if  

                   ALMll(i,j,l1,l2) = 0.5*flag*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))
                 end if 
                 if( abs(ALMlli(i,j,l1,l2)) .gt. 0.75*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))) then
                   write(*,*)'Wrong',abs(ALMlli(i,j,l1,l2)),0.75*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))

                   if(ALMlli(i,j,l1,l2).ge.0) then
                      flag = 1
                   else
                      flag = -1
                   end if
                   ALMlli(i,j,l1,l2) = 0.75*flag*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))
                 end if 
               end do
             end do
           end do
         end do

       !! Pricosionary block ends

      do frindex=1,3

      if(frindex .eq. 1) then
        theta = thetax
      else if(frindex .eq. 2) then
        theta = 1.0-2.0*thetax
      else 
        theta = thetax
      end if

       !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
       !!!             The FR integration part starts                                         !!
       !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  
       !! Integration block starts  


          do j=0,1
             beta(j)  = beta(j)  + pbeta(j)*epsilon1*theta/2.0
             betai(j) = betai(j) + pbetai(j)*epsilon1*theta/2.0
          end do


      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      !!           Update the ALMs                             !!
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        do j =0,1
        do l1=2,llmax
          ALMll(1,j,l1,l1+1)   = beta(j)*fs(l1)
          ALMll(1,j,l1,l1-1)   = beta(j)*fs(l1)
          ALMlli(1,j,l1,l1+1)  = betai(j)*fs(l1)
          ALMlli(1,j,l1,l1-1)  = betai(j)*fs(l1)
        end do 
        end do



      !! Second integration step over p


        do j=0,1
          pbetadot(j) = 0
          pbetaidot(j)= 0
        end do
 
       do l1=2,llmax-2
          l2 = l1+1
          do j=0,1
             pbetadot(j) = pbetadot(j) + (sqrt((2.0*l1+1.0)*(2.0*l1-1.0))*int((-1)**(l1+l2)) &
*(ALMll(1,j,l1,l1+1)-ALMll_old(1,j,l1,l1+1))/ALMll(0,0,l1,l1)/ALMll(0,0,l2,l2)/2.0)*fs(l1)
             pbetaidot(j) = pbetaidot(j) + (sqrt((2.0*l1+1.0)*(2.0*l1-1.0))*int((-1)**(l1+l2)) &
*(ALMlli(1,j,l1,l1+1)-ALMlli_old(1,j,l1,l1+1))/ALMll(0,0,l1,l1)/ALMll(0,0,l2,l2)/2.0)*fs(l1)
          end do
       end do

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!       Integrate Pdot and Qdot                         !!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 
       do j=0,1
         pbeta(j)  = pbeta(j)  - pbetadot(j)*epsilon1*theta
         pbetai(j) = pbetai(j) - pbetaidot(j)*epsilon1*theta
       end do


       do j=0,1
          beta(j)  = beta(j)  + pbeta(j)*epsilon1*theta/2.0
          betai(j) = betai(j) + pbetai(j)*epsilon1*theta/2.0
       end do

end do

      betai(0) = 0.0

   end do

       !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
       !!       If accepted then store to the value            !!
       !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

       write(*,*)samplenumber,beta,betai
       write(9171,*)beta,betai(1)

   end do
   close(unit=154) 
   close(unit=9171) 

end subroutine nonoise 


   
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!      initbeta: Initiallize a random momentum to beta        !!     
!!      input : A random number ii                             !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine initbeta(beta,ii)

    use healpix_types
    use rngmod

    type(planck_rng) :: rng_handle

    integer :: ii
    real(dp) :: beta(0:1)

   call cpu_time(time)
   inttime = int(time)
   call rand_init(rng_handle,ii,inttime)


   beta(0) = rand_gauss(rng_handle)
   beta(1) = rand_gauss(rng_handle)

end subroutine



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!  In the code we are storing a_lm as qr_n and qi_n which    !!
!!  an one index quantity.                                    !!
!!  n2lm : n -> (l,m)   mapping                               !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine n2lm(n,l,m)

   use healpix_types
   integer :: n,l,m
   real(dp) :: lt

   lt = (sqrt(8.0*n+1)-1.0)/2.0
   l = int(lt)
   m = n-l*(l+1)/2

  return

end subroutine



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!  In the code we are storing a_lm as qr_n and qi_n which    !!
!!  an one index quantity.                                    !!
!!  lm2n : (l,m) -> n  mapping                                !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine lm2n(l,m,n)
    
   integer :: n,l,m 

   n = l*(l+1)/2 + m

  return

end subroutine



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!  calculateALM : A general subroutine for calculating BipoSH   !!
!!                 coefficients from map.                        !! 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine calculateALM(almr,almi,lmax,llmax,ALMll,ALMli,Clebs)

   use healpix_types
   integer :: il,im,jl,jm
   integer :: L,M,recno
   integer :: LMAX,llMAX
   integer :: m1min,m1max
   integer :: i,k,h,j,r
   integer :: l2min,l2max 

   real(dp) :: Clebs(0:35000000)
   real(dp) :: Sum1 !,Smat
   real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
   real(dp) :: ALMli(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
   real(dp) :: almr(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: almi(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: cleb
   real(dp) :: almllr,almlli,norm
   real(dp),dimension(2) :: talmr,talmi

   do i=0,LMAX
     do k=0,llmax
       l1=k               ! k --> l1  

       l2min=l1
       IF (Abs(i-k).ge.k) l2min=Abs(k-i)
       l2max=llmax
       IF ((i+k).lt.llmax) l2max=(i+k)
       do h=l2min,l2max
         l2=h         ! h --> l2
         do j=0,i
           m1max = min(l1,l2-j)
           m1min = max(-l1,-l2-j)
           almllr = 0.0
           almlli = 0.0 
           do r=1,int(m1max-m1min)+1   ! This is the sum over m1 and m2
             m1=int(m1min+float(r-1))
             m2=j-m1                  !(j --> m)

             if(m2 .gt. llmax) goto 109

             call lm2n(k,abs(m1),i1)
             call lm2n(h,abs(m2),i2)
             call Sii(i,j,k,h,(m1),llmax,recno)
             cleb = Clebs(recno)

             !  WMAP-7 normalisation.
             !-------------------------------------------------------------------                    
                          
             if (m1.ge.0) then
               talmr(1)=almr(i1)               !/pixwin(k,1)
               talmi(1)=almi(i1)               !/pixwin(k,1)
             elseif (m1.lt.0) then
               talmr(1)= int((-1)**m1)*almr(i1)      !/pixwin(k,1)
               talmi(1)= int((-1)**(m1+1))*almi(i1)  !/pixwin(k,1)
             endif

             if (m2.ge.0) then
               talmr(2)=almr(i2)                    !/pixwin(h,1)
               talmi(2)=almi(i2)                    !/pixwin(h,1)
             elseif (m2.lt.0) then
               talmr(2)= int((-1)**m2)*almr(i2)      !/pixwin(h,1)
               talmi(2)= int((-1)**(m2+1))*almi(i2)  !/pixwin(h,1)
             endif

             almllr=almllr+(talmr(1)*talmr(2)-talmi(1)*talmi(2))*cleb
             almlli=almlli+(talmr(1)*talmi(2)+talmr(2)*talmi(1))*cleb

109          continue
           end do ! Ends loop over r --> m1 & m2

           norm  = 1.0 
           
           almllr=almllr*norm
           almlli=almlli*norm
           ALMll(i,j,k,h) = almllr
           ALMli(i,j,k,h) = almlli
         end do
       end do  
     end do
   end do
end subroutine



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!   Clebschs are stored as one index quantity in the file.  !!
!!   Sii : this gives the 6 index to 1 index mapping for     !!
!!         storing Clebsch values                            !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine Sii(L,M,l1,l2,m1,lm,Si)

   integer L,M,lm
   integer l1,l2,m1,m11
   integer Si

   Si =(L*(L+1)/2+M)*(2*L+1)*((lm+1)*(lm+1)-0)
   Si = Si + (l2-(l1-L))*((lm+1)*(lm+1)-0) + l1*l1+m1+l1
   Si = Si+1

   return

end subroutine 

