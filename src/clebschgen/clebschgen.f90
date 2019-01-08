! Package : SI Toolkit
! Version : Beta / V1.0
! Date    : 01.04.2017   (UW Madison)
! Code    : Clebschgen

! Date    : 03.07.2017   (Example Code, written in UW Madison)

 
   integer :: LMAX 
   integer :: llMAX                     ! We take lmax as llmax to differenciate it from LMAX 
   integer :: i,j,k                     ! Variables used in loops etc
   integer :: llmain                    ! l_max (1024) and L_max (2)   of A^{L,M}_{l,l+d}
   integer :: l2min,l2max               ! l2 can Vary within l-L to l+L in A^{L,M}_{l1,l2}
   integer :: recno,r,h,l1,l2,m1  
   integer :: itr

   real*8,allocatable,dimension(:) :: cleb
   real*8 rl,rl1,rl2,rm,m1min,m1max

   character(2) :: ci
   character(5) :: cj
   character :: filename*100
   
   write(*,*)'   '
   write(*,*)'Program : clebschgen'
   write(*,*)'It will calculate Clebsch Gordon coefficients C^{L M}_{l1 m1 l2 m2}'
   write(*,*)'Please input L_max and l1_max'

   read(*,*)LMAX,llmax

   NDIM = 2*(llmax+L)+50
   allocate(cleb(1:NDIM))

   write(ci,"(I1)")LMAX
   write(cj,"(I5.5)")llmax
   write(*,*)'   '

   filename  = 'Clebs_Lmax_'//trim(ci)//'_lmax_'//trim(cj)//'.dat'
   write(*,*)'Output Clebsch filename :',filename

   open(1,file=filename, action='write',status="NEW")
   do i=0,LMAX
     do k=0,llmax
       l1=k           ! k --> l1  
       l2min=l1
       IF (Abs(i-k).ge.k) l2min=Abs(k-i)
       l2max=llmax
       IF ((i+k).lt.llmax) l2max=(i+k)
       do h=l2min,l2max
         do j=0,i
          rl = i
          rm = j
          rl1 = k
          rl2 = h
          CALL clebsch(rl, rl1, rl2, rm, m1min, m1max, cleb, NDIM, IER)
           do r=1,int(m1max-m1min)+1 
             m1=int(m1min+float(r-1)) 
             call Sii(i,j,k,h,m1,llmax,recno)
             write(1,*)recno,cleb(r)
           enddo 
         enddo
       enddo
     enddo
   enddo
   close(1)

end program 

