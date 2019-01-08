! Package : SI Toolkit
! Version : Beta / V1.0
! Date    : 01.04.2017   (UW Madison)
! Code    : Example Code for using function lm2n

! Date    : 21.06.2017   (UW Madison)

integer :: n,l,m 

l=20
m=14     ! m must be positive
call lm2n(l,m,n)

write(*,*) n

end program


