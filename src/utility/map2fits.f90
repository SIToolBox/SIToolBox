  PROGRAM map2fits

  !=======================================================================
  !     version beta
  !=======================================================================
  USE healpix_types 
  USE fitstools, ONLY : getsize_fits, write_bintab, input_map
  USE pix_tools, ONLY : nside2npix, npix2nside
  USE utilities, ONLY : die_alloc
  USE head_fits, ONLY : add_card, get_card
  USE extension, ONLY : getArgument, nArguments
  USE paramfile_io
  IMPLICIT none
  INTEGER(I4B) :: nside_map_in1,nside_map_in2,nside_map_in3, nside_map_in4, nside_out

  !---------------------------------------------------------------------------
  !Arrays corresponding to 8 differnt input files
  REAL(SP),     DIMENSION(:,:),   ALLOCATABLE :: map1,map_2
  REAL(SP),     DIMENSION(:,:),   ALLOCATABLE :: map_3,map_4

  !----------------------------------------------------------------------------
  REAL(SP),     DIMENSION(:,:),   ALLOCATABLE :: map_out
  INTEGER(I4B)  status

  !==========================================================================
  INTEGER(I4B) npix_map_in1, npix_map_in2,npix_map_in3,npix_map_in4, npix_out, nmaps, type
  INTEGER(I4B) j, polar_fits,ncl

  CHARACTER(LEN=filenamelen)          ::  outfile, infilemap1,infilemap2,infilemap4,infilemap3,outasciifile
  CHARACTER(LEN=filenamelen)          ::  parafile
  CHARACTER(LEN=80), DIMENSION(1:120) :: header, header_in
  CHARACTER(LEN=80) :: char
  INTEGER :: SAN
  INTEGER(I4B) :: nlheader
  INTEGER(I4B) :: ordering, order_type
  REAL(SP) :: fmissval = -1.6375e-30,temp
  CHARACTER(700) :: INFILE1
  CHARACTER(LEN=*), PARAMETER :: code = 'SIToolBox'
  CHARACTER(LEN=*), PARAMETER :: version = 'beta'
  CHARACTER :: ord*10
  type(paramfile_handle) :: handle

  !-----------------------------------------------------------------------
  !                    get input parameters and create arrays
  !-----------------------------------------------------------------------

  !     --- read parameters interactively if no command-line arguments
  !     --- are given, otherwise interpret first command-line argument
  !     --- as parameter file name and read parameters from it:
  if (nArguments() == 0) then
     parafile=''
  else
     if (nArguments() /= 1) then
        print '(" Usage: coadd [parameter file name]")'
        stop 1
     end if
     call getArgument(1,parafile)
  end if

  handle=parse_init(parafile)
  !     --- announces program, default banner ***
  PRINT *, ''
  PRINT *,'   '//code//' '//version
  PRINT *,'  *** Convert ascii format to fits format ***    '
  PRINT *, ''
  print *,'Enter Nside for the map'
  read(*,*)SAN

   ncl=12*SAN*SAN
   nside_out=SAN

  allocate(map1(0:ncl,1))
  PRINT*, "Enter  input file names of the mask file"
  READ(*,'(A)') INFILE1
  OPEN(UNIT = 12, FILE = INFILE1, STATUS = "OLD")
  do j= 0,ncl-1  
      READ(12,*) map1(j,1)	
      if(j.ge.12*SAN*SAN)write(*,*)'Error : pixel number becomes ',j,'. More &
than 12*nside*nside'
     end do
   close(12)



  
  !     --- gets the output sky map filename ---
  outfile=parse_string(handle,'outfile',default='outmap.fits', &
  descr='Output map file name (eg. map_up.fits):', &
  filestatus='new') 
  PRINT *," "

 
  9000 FORMAT(A)


  !-----------------------------------------------------------------------
  !              allocate space for arrays
  !-----------------------------------------------------------------------

 
  nmaps=1
  npix_out=12*SAN*SAN
  

  ALLOCATE(map_out(0:npix_out-1,1:nmaps),stat = status)
  if (status /= 0) call die_alloc(code,'map_out')

  !-----------------------------------------------------------------------
  !                      reads the map
  !-----------------------------------------------------------------------
  PRINT *,'      '//code//'> Input original map '      
  
        do j=0,npix_out-1
	 map_out(j,1)=map1(j,1)
	end do

  close (13)

  !-----------------------------------------------------------------------
  !       deallocate memory for the input map and mask arrays

  PRINT*, "Please Choose pixel ordering scheme (1 / 2). Default : 1"
  PRINT*, "1 . Ring Format"
  PRINT*, "2 . Nest Format" 
  READ(*,'(a)') ord

  if (len_trim(ord)==0) then
    order_type = 1
  else
    read(ord, *) order_type
  end if
 
  !-----------------------------------------------------------------------
  !                        generates header
  !-----------------------------------------------------------------------

  PRINT *,'      '//code//'> Writing the coadded  map to FITS file '
  header = ' '
  call add_card(header,'COMMENT','-----------------------------------------------')
  call add_card(header,'COMMENT','     Sky Map Pixelisation Specific Keywords    ')
  call add_card(header,'COMMENT','-----------------------------------------------')
  call add_card(header,'PIXTYPE','HEALPIX','HEALPIX Pixelisation')
  if (order_type .eq. 1) then
     call add_card(header,'ORDERING','RING',  'Pixel ordering scheme, either RING or NESTED')
  else
     call add_card(header,'ORDERING','NESTED',  'Pixel ordering scheme, either RING or NESTED')
  endif
  call add_card(header,'NSIDE'   ,nside_out,   'Resolution parameter for HEALPIX')
  call add_card(header,'FIRSTPIX',0,'First pixel # (0 based)')
  call add_card(header,'LASTPIX',npix_out-1,'Last pixel # (0 based)')
  call add_card(header) ! blank line

  call add_card(header,'COMMENT','-----------------------------------------------')
  call add_card(header,'COMMENT','     Planck Simulation Specific Keywords      ')
  call add_card(header,'COMMENT','-----------------------------------------------')
  !if (nside_out .gt. nside_in) then
     call add_card(header,'EXTNAME','''COADDED  DATA''')
  !else
   !  call add_card(header,'EXTNAME','''DEGRADED DATA''')
  !endif
  call add_card(header,'CREATOR',code,        'Software creating the FITS file')
  call add_card(header,'VERSION',version,     'Version of the simulation software')
  call add_card(header) ! blank line
!  call add_card(header,'HISTORY','Input Map in '//TRIM(infilemapQ1))
  write(char,'(i6)') nside_map_in1
  call add_card(header,'HISTORY','Input Map resolution NSIDE =  '//TRIM(char))

  call add_card(header,'COMMENT','-----------------------------------------------')
  call add_card(header,'COMMENT','     Data Description Specific Keywords       ')
  call add_card(header,'COMMENT','-----------------------------------------------')
  call add_card(header,'INDXSCHM','IMPLICIT',' Indexing : IMPLICIT or EXPLICIT')
  call add_card(header,'GRAIN', 0, ' Grain of pixel indexing') ! full sky
  call add_card(header,'COMMENT','GRAIN=0 : no indexing of pixel data                         (IMPLICIT)')
  call add_card(header,'COMMENT','GRAIN=1 : 1 pixel index -> 1 pixel data                     (EXPLICIT)')
  call add_card(header,'COMMENT','GRAIN>1 : 1 pixel index -> data of GRAIN consecutive pixels (EXPLICIT)')
  call add_card(header) ! blank line
  

  call add_card(header) ! blank line
  nlheader = SIZE(header)
!================================================================================================
  !-----------------------------------------------------------------------
  !                      write the map to FITS file
  !-----------------------------------------------------------------------
  PRINT *,"H"             
  call write_bintab(map_out, npix_out, nmaps, header, nlheader, outfile)
  PRINT *, 'F'
  !-----------------------------------------------------------------------
  !                      deallocate memory for output map array
  !-----------------------------------------------------------------------
  DEALLOCATE(map_out)
 
  !-----------------------------------------------------------------------
  !                      output and report card
  !-----------------------------------------------------------------------
  PRINT *,' '
  PRINT *,' Report Card for '//code//' run'
  PRINT *,' -----------------------------'
  PRINT *," "
  PRINT *,'==============================================================================='
  PRINT *,' Number of pixels (IN)  : ', npix_map_in1
  PRINT *,'==============================================================================='
  if(order_type .eq. 1) then 
    PRINT *,' FORMAT                 : RING'
  else
    PRINT *,' FORMAT                 : NESTED'
  end if
  PRINT *,'==============================================================================='
  PRINT *,' Output map             : '//TRIM(outfile)
  PRINT *,'==============================================================================='
  PRINT *,' Number of pixels (OUT) : ', npix_out
  PRINT *,'==============================================================================='
  !-----------------------------------------------------------------------
  !                       end of routine
  !-----------------------------------------------------------------------
  PRINT *," "
  PRINT *,' '//code//'> normal completion'


  STOP
  END PROGRAM map2fits
