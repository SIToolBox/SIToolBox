! Package : SI Toolkit
! Version : Beta / V1.0
! Date    : 01.04.2017   (UW Madison)
! Code    : Example

! Date    : 03.07.2017   (Example Code, written in UW Madison)

 
   integer :: recno,i
   real*8 :: cleb
   real*8 :: Clebs(1:35000000)

   open(1,file='../data/Clebs_Lmax_2_lmax_01024.dat', action='read',status="OLD")

   do i=1,14681090
      read(1,*)recno,cleb
      Clebs(recno)=cleb
  !    write(*,*)recno,cleb
   end do     
   close(1)
   
   write(*,*)'OK HERE'

   call Clebsch2OneD(2,0,1000,1002,50,1024,recno)
   
    write(*,*)recno
write(*,*)Clebs(recno)

end program

