! Package : SI Toolkit
! Version : Beta / V1.0
! Date    : 01.04.2017   (UW Madison)
! Code    : Example Code for using function lm2n

! Date    : 21.06.2017   (UW Madison)

integer :: L,M,l1,l2,m1,lmax   ! These are inputs
integer :: ClbIndex                   ! Output index

L=2
M=1     ! m must be positive

l1 = 1000
l2 = 1001
m1 = 578   

lmax = 1024

call Clebsch2OneD(L,M,l1,l2,m1,lmax,ClbIndex)

write(*,*) ClbIndex

end program


