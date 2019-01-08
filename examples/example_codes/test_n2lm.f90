! Package : SI Toolkit
! Version : Beta / V1.0
! Date    : 01.04.2017   (UW Madison)
! Code    : Example Code for using function lm2n

! Date    : 21.06.2017   (UW Madison)

integer :: n,l,m 

n=224
call n2lm(n,l,m)

write(*,*) l,m

end program


