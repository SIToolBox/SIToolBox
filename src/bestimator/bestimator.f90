

!! This file will read the parameter file and decide which code to run

program bestimator

   use omp_lib
  implicit none
  integer, parameter    :: strlen = 100
  logical               :: needspeeling = .false., seedsremoved =.false.
  character(len=strlen) :: mask = "", noise = "", fst, snd
  character(len=500)    :: clebschpath="",maskpath =""
  character(len=500)    :: noisevariancepath,mappath,chainpath
  character(len=500)    :: pixelwindowfunction
  character(len=strlen), allocatable :: otherfamily(:), tmp(:)
  character(len=1000)   :: line
  integer               :: stat,  j, j0, j1, ii = 1, z
  integer, parameter    :: state_begin=1, state_in_fst=2, state_in_sep=3
  integer               :: clebschlmax, clebschl1max 
  integer               :: chainlmax,chainl1max,samplenumber
  integer               :: nside
  real*8                :: noisevariance 

  do

    read(*, "(a)", iostat=stat) line
    if (stat<0) exit
    if ((line(1:1) == "#") .or. &
        (line(1:1) == ";") .or. &
        (len_trim(line)==0)) then
      cycle
    end if
    z = state_begin
    do j = 1, len_trim(line)
      if (z == state_begin) then
        if (line(j:j)/=" ") then
          j0 = j
          z = state_in_fst
        end if
      elseif (z == state_in_fst) then
        if (index("= ",line(j:j))>0) then
          fst = lower(line(j0:j-1))
          z = state_in_sep
        end if
      elseif (z == state_in_sep) then
        if (index(" =",line(j:j)) == 0) then
          snd = line(j:)
          exit
        end if
      else
         stop "not possible to be here"
      end if
    end do
    if (z == state_in_fst) then
      fst = lower(line(j0:))
    elseif (z == state_begin) then
      cycle
    end if

    if (fst=="noise") then
      read(snd,"(a)") noise
    elseif (fst=="mask") then
      read(snd,"(a)") mask
    elseif (fst=="clebsch_path") then
      read(snd,"(a)") clebschpath
    elseif (fst=="clebsch_lmax") then
      read(snd,"(I2)") clebschlmax
    elseif (fst=="clebsch_l1max") then
      read(snd,"(I4)") clebschl1max                
    elseif (fst=="mask_path") then
      read(snd,"(a)") maskpath
    elseif (fst=="noise_sd_path") then
      read(snd,"(a)") noisevariancepath
    elseif (fst=="noise_sd") then
      read(snd,*) noisevariance
    elseif (fst=="map_path") then
      read(snd,"(a)") mappath
    elseif (fst=="pixel_window_function") then
      read(snd,"(a)") pixelwindowfunction       
    elseif (fst=="chain_path") then
      read(snd,"(a)") chainpath
    elseif (fst=="chain_lmax") then
      read(snd,"(I4)") chainlmax
    elseif (fst=="chain_l1max") then
      read(snd,"(I4)") chainl1max
    elseif (fst=="sample_number") then
      read(snd,*) samplenumber
    elseif (fst=="map_nside") then
      read(snd,"(I4)") nside
    elseif (fst=="seedsremoved") then
      seedsremoved = .true.
    elseif (fst=="needspeeling") then
      needspeeling = .true.
    elseif (fst=="otherfamily") then
      j = 1; ii = 1
      do while (len_trim(snd(j:)) >0)
        j1  = index(snd(j:),",")
        if (j1==0) then
          j1 = len_trim(snd)
        else
          j1 = j + j1 - 2
        end if
        do 
          if (j>len_trim(snd)) exit
          if (snd(j:j) /= " ") exit
          j = j +1
        end do
        allocate(tmp(ii)) 
        tmp(1:ii-1) = otherfamily
        call move_alloc(tmp, otherfamily)
        read(snd(j:j1),"(a)"), otherfamily(ii)
        j = j1 + 2 
        ii = ii + 1
      end do
    else 
      print *, "unknown option '"//trim(fst)//"'"; stop
    end if
  end do
  print "(a,a)","noise = ",       trim(noise)
  print "(a,a)","mask = ", trim(mask)
  print "(a,a)","clebschpath  = ", trim(clebschpath)
  print "(a,I2)","clebschlmax  = ", clebschlmax
  print "(a,I4)","clebschl1max = ", clebschl1max
  print "(a,a)","mask_path = ", trim(maskpath)
  print "(a,a)","noise_sd_path = ", trim(noisevariancepath)
  print "(a,G3.2)","noise_sd = ", noisevariance
  print "(a,a)","map_path = ", trim(mappath)
  print "(a,a)","pixel_window_path",trim(pixelwindowfunction)
  print "(a,a)","Map nside = ", nside
  print "(a,a)","chain_path = ", trim(chainpath)
  print "(a,I2)","chain_lmax = ", chainlmax
  print "(a,I4)","chain_l1max = ", chainl1max
  print *,"sample_number = ", samplenumber


  if(trim(noise) == "isotropic") then
      if(trim(mask) == "yes") then
         call anisotropic(chainl1max,chainlmax,clebschl1MAX,clebschlmax,nside,samplenumber,   & 
         noisevariance,mappath,pixelwindowfunction,noisevariancepath,clebschpath,maskpath,chainpath,1,1)
         print *,"yes"  
      else if(trim(mask) == "no") then
         call isotropicnoise(chainl1max,chainlmax,clebschl1MAX,clebschlmax,nside,samplenumber, &
         noisevariance,mappath,clebschpath,chainpath) 
         print *,"no"
      else
         print *,"Mask parameter should be either yes  or no. Check the parameter file"
      end if
  elseif(trim(noise) == "anisotropic") then
      if(trim(mask) == "yes") then
         call anisotropic(chainl1max,chainlmax,clebschl1MAX,clebschlmax,nside,samplenumber   & 
       ,noisevariance,mappath,pixelwindowfunction,noisevariancepath,clebschpath,maskpath,chainpath,1,0)
         print *,"yes"
      else if(trim(mask) == "no") then
         call anisotropic(chainl1max,chainlmax,clebschl1MAX,clebschlmax,nside,samplenumber  & 
       ,noisevariance,mappath,pixelwindowfunction,noisevariancepath,clebschpath,maskpath,chainpath,0,0)
         print *,"no"
      else 
         print *,"Mask parameter should be either yes  or no. Check the parameter file"
      end if
  else
     print *,"Noise should be either isotropic or anisotropic. Something wrong in the parameter file" 
  end if 
 
contains
 
pure function lower (str) result (string)
    implicit none
    character(*), intent(In) :: str
    character(len(str))      :: string
    Integer :: ic, i
 
    character(26), parameter :: cap = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    character(26), parameter :: low = 'abcdefghijklmnopqrstuvwxyz'
 
    string = str
    do i = 1, len_trim(str)
        ic = index(cap, str(i:i))
        if (ic > 0) string(i:i) = low(ic:ic)
    end do
end function 
 
end program
 

