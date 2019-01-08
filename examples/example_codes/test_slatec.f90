integer ier,i,m2,tot
parameter (NDIM=500)
real*8 THRCOF(NDIM),l,l1,l2,m,m1min,m1max,m1,m21,l1min,l1max
real*8 cleb(NDIM)


l=1
l1=101
l2=100
m=1

CALL DRC3JM (l, l1, l2, -m, m1min, m1max, THRCOF, NDIM, IER)

tot = int(m1max-m1min)+1
write(*,*)tot
write(*,*)THRCOF(1:tot)


l1=101
l2=100
m1=50
m21=100

CALL DRC3JJ (l1, l2, m1, m21, l1min, l1max, THRCOF, NDIM, IER)

tot = int(l1max-l1min)+1
write(*,*)tot,l1min,l1max
write(*,*)THRCOF(1:tot)


l=1
l1=101
l2=100
m=1


CALL clebsch(l, l1, l2, m, m1min, m1max, cleb, NDIM, IER)

tot = int(m1max-m1min)+1
write(*,*)tot
write(*,*)cleb(1:tot)


end program

