#include "alias.inc"
subroutine read_input(PINPT, PINPT_DOS, PINPT_BERRY, PKPTS, PGEOM, PWGHT, EDFT, NN_TABLE, PKAIA, PRPLT)
  use parameters
  use read_incar
  use berry_phase
  use mpi_setup
  implicit none
! integer*4, parameter :: max_dummy = 9999999
  integer*4     mpierr
  integer*4     ii,iii,i_continue, nitems
  integer*4     i, i_orb, linecount
  integer*4     i_dummy
  integer*4, allocatable :: zak_erange_(:)
  integer*4, allocatable :: proj_atom_dummy(:,:), proj_natom_dummy(:)
  integer*4                 size_zak_erange
  character*132 inputline !, inputline_dummy
  character*40  desc_str,dummy
  character*40  str2lowcase
  character*132 strip_zak_range
  real*8        enorm
  real*8        param_const(5,max_nparam), param_const_nrl(5,4,max_nparam)
  character(*), parameter :: func = 'read_input'
  character*40  fname
  logical       flag_kfile_exist, flag_gfile_exist, flag_read_energy, flag_number
  logical       flag_efile_exist, flag_efileu_exist, flag_efiled_exist
  logical       flag_kfile_ribbon
  external      nitems, enorm, flag_number, str2lowcase
  type(incar)   :: PINPT
  type(dos)     :: PINPT_DOS
  type(berry)   :: PINPT_BERRY
  type(poscar)  :: PGEOM
  type(kpoints) :: PKPTS
  type(energy)  :: EDFT
  type(energy)  :: EDFT_all
  type(weight)  :: PWGHT 
  type(hopping) :: NN_TABLE
  type(gainp)   :: PKAIA
  type(replot)  :: PRPLT

  if(.not. PINPT%flag_inputcard_fname_parse) then 
    fname   = 'INCAR-TB'
  elseif(PINPT%flag_inputcard_fname_parse) then
    fname   = PINPT%ifilenm
  endif
  i_dummy = 9999
  PINPT%flag_get_band=.true.
  PINPT%flag_erange=.false.
  if(.not. PINPT%flag_parse .and. .not. PINPT%flag_pfile) PINPT%flag_pfile=.false.
  PINPT%flag_pincar=.false.
  PINPT%flag_tbfit=.false.
  PINPT%flag_plot_fit=.false.
  PINPT%flag_print_energy_diff = .false.
  PINPT%filenm_gnuplot = 'gnuBAND-TB.gpi' ! default
  PINPT%flag_print_only_target=.false.
  PINPT%flag_print_param=.false.
  PINPT%flag_plot_stm_image = .false.
  PINPT%flag_plot_eigen_state=.false.
  PINPT%flag_plot_wavefunction = .true.
  PINPT%flag_default_ngrid = .true.
  PINPT%flag_default_stm_ngrid = .true.
  PINPT%flag_default_rorigin= .true.
  PINPT%flag_print_orbital=.false.
  PINPT%flag_print_single=.false. 
  if(.not. PINPT%flag_lorbit_parse) PINPT%flag_get_orbital=.false.
  if(.not. PINPT%flag_lorbit_parse) PINPT%flag_print_mag=.false.
  if(.not. PINPT%flag_proj_parse)   PINPT%flag_print_proj=.false.
  PINPT%itarget_e_start = 1 ! default
  PINPT%nproj_sum = 0
  PINPT%flag_pfile_index=.false.
  PINPT%flag_use_overlap=.false.
  PINPT%flag_set_param_const=.false.
  PINPT%flag_get_dos=.false.
  PINPT%flag_get_z2=.false.
  PINPT%flag_get_zak_phase=.false.
  PINPT%flag_zak_separate=.false.
  PINPT%flag_get_parity=.false.
  PINPT%flag_get_symmetry=.false.
  PINPT%flag_berryc_separate=.false.
  PINPT%flag_zak_kfile_read = .false.
  PINPT%flag_get_berry_curvature = .false.
  PINPT%flag_berry = .false.
  PINPT%flag_collinear=.false.
  PINPT%flag_noncollinear=.false.
  PINPT%flag_local_charge=.false.
  PINPT%flag_plus_U=.false.
  PINPT%flag_set_ribbon=.false.
  PINPT%flag_print_only_ribbon_geom=.false.
  PINPT%flag_slater_koster = .true. 
  PINPT%slater_koster_type = 1 ! default scaling method
  PINPT%param_nsub_max = 1 ! default if SK_SCALE_TYPE <= 10
  PINPT%l_broaden = 0.15 ! angstrong unit, default for cutoff-function broadening
  PINPT%flag_scissor = .false.
  PINPT%flag_efield = .false.
  PINPT%flag_efield_frac = .false.
  PINPT%flag_efield_cart = .false.
  PINPT%flag_load_nntable= .false.
  PINPT%flag_sparse = .false.
  PINPT%flag_get_effective_ham=.false.
  PINPT%flag_write_unformatted=.false.
  PINPT%efile_type = 'user'
  PINPT%efile_ef   = 0d0
#ifdef SPGLIB
  PINPT%flag_spglib = .true.
#endif
  PINPT_BERRY%flag_wcc_phase = .false.
  PINPT_BERRY%flag_bc_phase  = .false.
  PINPT_BERRY%flag_z2_phase  = .false.
  PINPT_BERRY%flag_zak_phase = .false.
  PINPT_BERRY%noccupied      = 0
  PINPT_BERRY%flag_print_hamiltonian_parity = .false.
  PINPT_BERRY%flag_print_hamiltonian_symmetry = .false.
  PINPT_BERRY%flag_parity_phase = .false.
  PINPT_BERRY%flag_symmetry_phase = .false.

  flag_read_energy=.false.
  flag_kfile_ribbon=.false.
  PINPT%gfilenm='POSCAR-TB' !default
  if(.not. PINPT%flag_kfile_parse) PINPT%kfilenm='KPOINTS_BAND' !default
  if(.not. PINPT%flag_parse .and. .not. PINPT%flag_pfile) PINPT%pfilenm='PARAM_FIT.dat' !default
  PINPT%pfileoutnm='PARAM_FIT.new.dat' !default
  PINPT%efilenmu=' '
  PINPT%efilenmd=' '
  if(.not. PINPT%flag_miter_parse) PINPT%miter = 30      ! default 
  if(.not. PINPT%flag_mxfit_parse) PINPT%mxfit = 1       ! default 
  PINPT%ftol  = 0.00001 ! default 
  PINPT%ptol  = 0.00001 ! default 
  PINPT%fdiff = 0.001   ! default
  PINPT%ispin = 1 ! default (1 : nonmag, 2: collinear & noncollinear)
  PINPT%ispinor = 1 ! default (1 : nonmag, collinear 2: noncollinear)
  PINPT%nspin = 1 ! default (1 : nonmag, 2: collinear, 1: noncollinear)
  PINPT%read_energy_column_index = 2 ! default, read 2nd column as target energy (NM or spin_up)
  PINPT%read_energy_column_index_dn = 2 ! default, read 2nd column as target energy (spin_dn)
  PINPT%efield_origin(1:3) = 0d0 ! default
  PINPT%rcut_orb_plot = 5 ! default (unit = angstrom)
! PINPT%init_erange = -1 ! default
  PINPT%nn_max(1:3) = 3 ! default

  PWGHT%flag_weight_default = .true.
  PWGHT%flag_weight_default_orb = .true.
  PWGHT%iband = 1
  PWGHT%fband = -9999
  PWGHT%nweight = 0
  PINPT%nweight = 0
  PKPTS%kunit = 'A' !default 'A' : angstrom or 'R' : reciprocal unit is available

  PINPT%flag_report_geom = .true.

  NN_TABLE%onsite_tolerance = onsite_tolerance ! default defined in parameters.f90

  PINPT%flag_ga_with_lmdif=.false.
  PKAIA%mgen    = 500
  PKAIA%npop    = 100
  PKAIA%ngene   = 6
  PKAIA%pcross  = 0.85d0
  PKAIA%pmutmn  = 0.0005d0
  PKAIA%pmutmx  = 0.25d0
  PKAIA%pmut    = 0.005d0
  PKAIA%imut    = 2
  PKAIA%fdif    = 1.0d0
  PKAIA%irep    = 3
  PKAIA%ielite  = 0
  PKAIA%ivrb    = 0
  PKAIA%convtol = 0.0001d0
  PKAIA%convwin = 20.0d0
  PKAIA%iguessf = 0.1d0
  PKAIA%iseed   = 999

  PRPLT%flag_replot_dos   = .false.
  PRPLT%flag_replot_ldos  = .false.
  PRPLT%flag_replot_sldos = .false.
  PRPLT%flag_replot_didv  = .false.
  PRPLT%flag_replot_proj_band  = .false.
! PRPLT%flag_replot_only  = .true.
  PRPLT%replot_nproj_sum  = 0
  PRPLT%replot_nldos_sum  = 0
  PRPLT%replot_nband      = 0
  PRPLT%replot_sldos_fname= 'SLDOS.replot.dat'
  PRPLT%replot_didv_fname = 'DIDV.replot.dat'

  if(myid .eq. 0) write(6,*)' '
  if(myid .eq. 0) write(6,*)'---- READING INPUT FILE: ',trim(fname)
  open (pid_incar, FILE=fname,iostat=i_continue)
  linecount = 0; PINPT%nparam= 0; PINPT%nparam_const = 0

 line: do
        read(pid_incar,'(A)',iostat=i_continue) inputline
        if(i_continue<0) exit               ! end of file reached
        if(i_continue>0) then 
         if(myid .eq. 0) write(6,*)'Unknown error reading file:',trim(fname),func
        endif
        linecount = linecount + 1
        ! check INPUT tag
        read(inputline,*,iostat=i_continue) desc_str
        if(i_continue .ne. 0) cycle              ! skip empty line
        if (desc_str(1:1).eq.'#') cycle  ! skip comment

        ! head
        select case (desc_str)

          !set TBFIT or not, and releated parameters
          case('GET_BAND', 'BAND')
            call set_get_band(PINPT,inputline, desc_str)

          case('TBFIT','LSTYPE','PTOL','FTOL','MITER','MXFIT', 'FDIFF')
            call set_tbfit(PINPT, inputline, desc_str)

          case('EWINDOW')
            call set_energy_window(PINPT, inputline, desc_str)
         
          case('ERANGE')
            call set_energy_range(PINPT, inputline, desc_str)

          !read KPOINT info file from KFILE
          case('KFILE')
            if(.not. PINPT%flag_kfile_parse) then
              call set_kpoint_file(PINPT, flag_kfile_ribbon, inputline)
            endif
          !load hopping file?
          case('LOAD_HOP', 'LOAD_TIJ', 'LOAD_NNTABLE')
            call set_load_nntable(PINPT, inputline, desc_str)

          !read GEOMETRY info file from GFILE
          case('GFILE')
            call set_geom_file(PINPT, inputline, 1)

          !report GEOMETRY info read from GFILE
          case('PRINT_GEOM')
            call set_geom_file(PINPT, inputline, 2)

          !read TB-parameter file from PFILE
          case('PFILE')
           call set_tbparam_file(PINPT, param_const, param_const_nrl, inputline)

          !hopping type: is it 'Slater-Koster;sk' type (.true.)? or is it explicitly defined (.false.) ?
          case('IS_SK', 'SLATER_KOSTER')
           call set_hopping_type(PINPT, inputline)

          !how many times the unit cell is repeated in finding nearest neighbor pair?
          case('NN_MAX')
           call set_nn_max(PINPT,inputline,desc_str)

          !if(myid .eq. 0) write fitted TB-parameter to POFILE
          case('POFILE')
           call set_tbparam_out_file(PINPT, inputline)

#ifdef SPGLIB
          !if(myid .eq. 0) write fitted TB-parameter to POFILE
          case('SPGLIB', 'SPG_LIB')
           call set_spglib_write(PINPT, inputline,desc_str)
#endif

          ! LSPIN tag. 1:non-collinear or NM, 2:collinear
          case('TYPMAG')
            call set_magnetism_tag(PINPT, inputline)

          ! LSORB tag. .true.:spin-orbit .false.: no-soc but collinear only
          case('LSORB')
            call set_spin_orbit_tag(PINPT, inputline)

          ! LOCCHG. tag  true.:read local charge density for the onsite modification
          case('LOCCHG')
            call set_local_charge(PINPT, inputline)

          ! PLUS+U. tag  true.: perform +U approach U*Sigma_i n_i,u * n_i,d
          case('PLUS+U')
            call set_plus_U_scheme(PINPT, inputline)

          !read target (DFT) energy file from EFILE
          case('EFILE','EFILEU','EFILED')
            call set_target_file(PINPT, flag_read_energy, inputline, desc_str)
          case('EFILE_EF')
            read(inputline,*,iostat=i_continue) desc_str, PINPT%efile_ef
            if_main write(6,'(A,F12.5)')'  EDFT_EF:  ', PINPT%efile_ef

          case('PLOTFIT')
            if(nitems(inputline) -1 .eq. 1) then
              read(inputline,*,iostat=i_continue) desc_str, PINPT%flag_plot_fit
            else
              read(inputline,*,iostat=i_continue) desc_str, PINPT%flag_plot_fit, PINPT%filenm_gnuplot
            endif
          case('PRTDIFF')
            read(inputline,*,iostat=i_continue) desc_str, PINPT%flag_print_energy_diff

          !initial energy of the target band
          case('IBAND','FBAND')
            call set_target_band_init_fina(PWGHT, inputline, desc_str)

          !if true, target data with weight information is printed and quit the program
          case('PRINT_ONLY')
            call set_print_only_target(PINPT,inputline)

          !if true, scissor operator for the target data will be applied for the energy levels specified
          case('SCISSOR')
            call set_target_scissor(PINPT, inputline)

          !set orbital decomposed output or not
          case('LORBIT')
            if(.not. PINPT%flag_lorbit_parse) then
              call set_local_orbital_print(PINPT, inputline)
            endif
          !set orbital decomposed output onto each atomic site
          case('LDOS', 'LDOS_SUM', 'PROJ', 'PROJ_SUM', 'PROJ_BAND')
            if(.not. PINPT%flag_proj_parse) then
              call set_ldos_project_print(PINPT,inputline)
            endif

          ! kpoint unit : RECIPROCAL (fractional) or ANGSTROM (1/A)
          case('K_UNIT')
            call set_kpoint_unit(PKPTS, inputline)

          !read TBFIT settings: TB-parameters, weight, ... etc. And also, Zak phase, DOS etc, can be set here.
          case('SET')
            read(inputline,*,iostat=i_continue) desc_str, desc_str
           
            !set TB-parameter ! deprecated... 
           !if(trim(desc_str) .eq. 'TBPARAM') then
           !  call set_tbparam(PINPT, param_const, desc_str)
           
            !set constraint for parameters
            if(trim(desc_str) .eq. 'CONSTRAINT') then
              call set_constraint(PINPT, desc_str)
           
            !set weight for the fitting
            elseif(trim(desc_str) .eq. 'WEIGHT') then
              call set_weight_factor(PINPT, PWGHT, desc_str)
           
            !set onsite_tolerance : distance within this range will be regared as onsite
            elseif(trim(desc_str) .eq. 'ONSITETOL') then
              call set_onsite_tol(NN_TABLE, inputline)
           
            !set NN_CLASS with given atom pair of ditance
            elseif(trim(desc_str) .eq. 'NN_CLASS') then
              call set_nn_class(PGEOM, desc_str)
           
            !set eigenstate charge density plot
            elseif(trim(desc_str) .eq. 'EIGPLOT' .or. trim(desc_str) .eq. 'STMPLOT') then
              call set_eigplot(PINPT,desc_str)
           
            !set density of state (DOS) plot
            elseif(trim(desc_str) .eq. 'DOS') then
              call set_density_of_states(PINPT, PINPT_DOS, desc_str)
           
            !set ribbon geometry
            elseif(trim(desc_str) .eq. 'RIBBON') then
              call set_ribbon(PINPT, flag_kfile_ribbon, desc_str)

            !set Z2 topological index calculation based on WCC method (see Ref. [PRB 83, 235401])
            elseif(trim(desc_str) .eq. 'Z2' .or. trim(desc_str) .eq. 'Z2_INDEX') then
              call set_z2(PINPT, PINPT_BERRY, desc_str)

            !set Wannier charge center calculation (see Ref. [PRB 83, 235401])
            elseif(trim(desc_str) .eq. 'WCC') then
              call set_wcc(PINPT, PINPT_BERRY, desc_str)

            !set Zak phase
            elseif(trim(desc_str) .eq. 'ZAK_PHASE') then
              call set_zak_phase(PINPT, PINPT_BERRY, desc_str)
 
            !set Parity eigenvalue calculation          
            elseif(trim(desc_str) .eq. 'PARITY' .or. trim(desc_str) .eq. 'PARITY_CHECK') then
              call set_parity_check(PINPT, PINPT_BERRY, desc_str)

            elseif(trim(desc_str) .eq. 'SYMMETRY_EIG' .or.  trim(desc_str) .eq. 'SYMMETRY_INDICATOR') then
              call set_symmetry_check(PINPT, PINPT_BERRY, desc_str)

            !set Berry curvature
            elseif(trim(desc_str) .eq. 'BERRY_CURVATURE' .or. trim(desc_str) .eq. 'BERRYC') then
              call set_berry_curvature(PINPT, PINPT_BERRY, desc_str)

            !set E-field
            elseif(trim(desc_str) .eq. 'EFIELD') then
              call set_efield(PINPT, desc_str)

            !set parameters for the Genetic Algorithm of PIKAIA library
            elseif(trim(desc_str) .eq. 'GA') then
              call set_gainp(PKAIA, desc_str)    
 
            !set effective hamiltonian
            elseif(trim(desc_str) .eq. 'EFFECTIVE') then
              call set_effective(PINPT, desc_str)

            elseif(trim(desc_str) .eq. 'REPLOT') then
              call set_replot(PRPLT,desc_str)

            endif !SET
         
        end select
      enddo line

  if(PINPT%flag_tbfit_parse) then
    PINPT%flag_tbfit = PINPT%flag_tbfit_parse_
  endif

  if((PRPLT%flag_replot_dos .or. PRPLT%flag_replot_ldos .or. PRPLT%flag_replot_sldos .or. PRPLT%flag_replot_didv &
                            .or. PRPLT%flag_replot_proj_band)) then
    PINPT%flag_tbfit = .false.
  endif

  if( PINPT%flag_tbfit .and. (PINPT%flag_pfile .or. PINPT%flag_pincar) ) then
     if_main write(6,'(A,I8)')'  N_PARAM:',PINPT%nparam
     if(PINPT%slater_koster_type .gt. 10) then
       if_main write(6,'(A)') '         : NRL TB scheme is applied in parameterization'
       if_main write(6,'(A,F9.4)') '           => L_BROADEN (cutoff function) = ', PINPT%l_broaden
     endif
     do i=1,PINPT%nparam
       if(PINPT%slater_koster_type .gt. 10) then
         if_main write(6,'(A,2x,A14,1x,*(F10.5))')'  C_PARAM:',PINPT%param_name(i),PINPT%param_nrl(1:PINPT%param_nsub(i),i)
       else
         if_main write(6,'(A,2x,A14,1x,F10.5)')'  C_PARAM:',PINPT%param_name(i),PINPT%param(i)
       endif
     enddo
  elseif( PINPT%flag_tbfit .and. .not. (PINPT%flag_pfile .or. PINPT%flag_pincar) ) then
     if_main write(6,'(A,I8)')'  !WARN! TBFIT has set, however the TB-parameter is not provided. Check!!'
     kill_job
  elseif( .not. PINPT%flag_tbfit .and. (PINPT%flag_pfile .or. PINPT%flag_pincar) ) then
     if_main write(6,'(A,I8)')'  N_PARAM:',PINPT%nparam
     if(PINPT%slater_koster_type .gt. 10) then
       if_main write(6,'(A)') '         : NRL TB scheme is applied in parameterization'
       if_main write(6,'(A,F9.4)') '           => L_BROADEN (cutoff function) = ', PINPT%l_broaden
     endif
     do i=1,PINPT%nparam
       if(PINPT%slater_koster_type .gt. 10) then
         if_main write(6,'(A,2x,A14,1x,*(F10.5))')'  C_PARAM:',PINPT%param_name(i),PINPT%param_nrl(1:PINPT%param_nsub(i),i)
       else
         if_main write(6,'(A,2x,A14,1x,F10.5)')'  C_PARAM:',PINPT%param_name(i),PINPT%param(i)
       endif
     enddo
  endif

  if (linecount == 0) then
    if_main write(6,*)'Attention - empty input file: INCAR-TB ',func
  endif
  close(pid_incar)



  !read inputfiles defined in INCAR-TB: GEOMETRY, KPOINTS, TARGET_ENERGY...
  inquire(file=PINPT%gfilenm,exist=flag_gfile_exist)
  inquire(file=PINPT%kfilenm,exist=flag_kfile_exist)
  if(flag_read_energy .and. PINPT%flag_tbfit) then
    if(PINPT%flag_collinear .and. PINPT%efile_type .eq. 'user') then
      if(len_trim(PINPT%efilenmu) .eq. 0 .or. len_trim(PINPT%efilenmd) .eq. 0) then
        if(myid .eq. 0) write(6,'(A)')'  !WARN!  EFILE has not been set properly. Check EFILE or EFILEU, EFILED. Exit program.'
        kill_job
      endif
      inquire(file=PINPT%efilenmu,exist=flag_efileu_exist)
      inquire(file=PINPT%efilenmd,exist=flag_efiled_exist)
    else
      inquire(file=PINPT%efilenmu,exist=flag_efileu_exist)
    endif
  endif

  ! read info: geometry
  if(flag_gfile_exist) then
    if(PINPT%flag_set_ribbon) call set_ribbon_geom(PINPT)
    call read_poscar(PINPT, PGEOM, NN_TABLE)

    !set parameter constraint
    allocate( PINPT%param_const(5,PINPT%nparam) )

    !initialize
     PINPT%param_const(1,:) =param_const(1,1:PINPT%nparam)  ! if gt 0, param is same as i-th parameter 
     PINPT%param_const(2,:) =param_const(2,1:PINPT%nparam)  ! default upper bound 
     PINPT%param_const(3,:) =param_const(3,1:PINPT%nparam)  ! default lower bound
     PINPT%param_const(4,:) =param_const(4,1:PINPT%nparam)  ! if set to 1; fix 
     PINPT%param_const(5,:) =param_const(5,1:PINPT%nparam)  ! if set to 1; fix and save the parameter as constant

    if(PINPT%slater_koster_type .gt. 10) then
      allocate( PINPT%param_const_nrl(5,4,PINPT%nparam) )
      PINPT%param_const_nrl(1,:,:) =param_const_nrl(1,:,1:PINPT%nparam)  ! if gt 0, param is same as i-th parameter 
      PINPT%param_const_nrl(2,:,:) =param_const_nrl(2,:,1:PINPT%nparam)  ! default upper bound 
      PINPT%param_const_nrl(3,:,:) =param_const_nrl(3,:,1:PINPT%nparam)  ! default lower bound
      PINPT%param_const_nrl(4,:,:) =param_const_nrl(4,:,1:PINPT%nparam)  ! if set to 1; fix 
      PINPT%param_const_nrl(5,:,:) =param_const_nrl(5,:,1:PINPT%nparam)  ! if set to 1; fix and save the parameter as constant
    endif

    if(PINPT%flag_set_param_const) call set_param_const(PINPT,PGEOM)

    !get neighbor hopping index
    if(.not.(PRPLT%flag_replot_dos   .or. PRPLT%flag_replot_ldos .or. &
             PRPLT%flag_replot_sldos .or. PRPLT%flag_replot_proj_band .or. &
             PRPLT%flag_replot_didv  .or. PRPLT%flag_replot_band )) then
      call find_nn(PINPT,PGEOM, NN_TABLE)
!     if(PINPT%slater_koster_type .le. 10) then ! note: we are not able to write "hopping.dat" file if SK_SCALE_TYPE >= 11 
        call print_nn_table(NN_TABLE,PINPT)     !       due to some technical problem which is not harm the results.
!     endif
      if(PINPT%flag_load_nntable .and. .not. PINPT%flag_tbfit .and. .not. PINPT%flag_use_overlap) then
       call load_nn_table(NN_TABLE, PINPT)
      elseif(PINPT%flag_load_nntable .and. (PINPT%flag_tbfit .or. PINPT%flag_use_overlap) ) then
       if_main write(6,'(A)')'  !WARN! Reading hopping file cannot be combined with parameter fitting procedure or '
       if_main write(6,'(A)')'         with overlap matrix constructions, i.e., using overlap integrals.'
       if_main write(6,'(A)')'         Please turn off LOAD_HOP or TBFIT option or do not use overlap integrals in'
       if_main write(6,'(A)')'         your PARAM_FIT.dat file. Exit..'
       kill_job
      endif
    endif

  elseif(.not. flag_gfile_exist) then
    if(myid .eq. 0) write(6,'(A,A,A)')'  !WARN! ',trim(PINPT%gfilenm),' does not exist!! Exit...'
    kill_job
  endif

  if(PINPT%flag_default_ngrid) then
    PINPT%ngrid(1) = nint(enorm(3, PGEOM%a_latt(:,1)) / 0.1d0)
    PINPT%ngrid(2) = nint(enorm(3, PGEOM%a_latt(:,2)) / 0.1d0)
    PINPT%ngrid(3) = nint(enorm(3, PGEOM%a_latt(:,3)) / 0.1d0)
    PINPT%ngrid(1) = PINPT%ngrid(1) + mod(PINPT%ngrid(1),2)
    PINPT%ngrid(2) = PINPT%ngrid(2) + mod(PINPT%ngrid(2),2)
    PINPT%ngrid(3) = PINPT%ngrid(3) + mod(PINPT%ngrid(3),2)
    if(myid .eq. 0) write(6,'(A,3(I6))')'   N_GRID: (for EIGPLOT) ',PINPT%ngrid(1:3)
  else
    if(myid .eq. 0) write(6,'(A,3(I6))')'   N_GRID: (for EIGPLOT) ',PINPT%ngrid(1:3)  
  endif
  if(PINPT%flag_default_stm_ngrid .and. PINPT%flag_plot_stm_image) then
    PINPT%stm_ngrid(1) = nint(enorm(3, PGEOM%a_latt(:,1)) / 0.1d0)
    PINPT%stm_ngrid(2) = nint(enorm(3, PGEOM%a_latt(:,2)) / 0.1d0)
    PINPT%stm_ngrid(3) = nint(enorm(3, PGEOM%a_latt(:,3)) / 0.1d0)
    PINPT%stm_ngrid(1) = PINPT%stm_ngrid(1) + mod(PINPT%stm_ngrid(1),2)
    PINPT%stm_ngrid(2) = PINPT%stm_ngrid(2) + mod(PINPT%stm_ngrid(2),2)
    PINPT%stm_ngrid(3) = PINPT%stm_ngrid(3) + mod(PINPT%stm_ngrid(3),2)
    if(myid .eq. 0) write(6,'(A,3(I6))')'   N_GRID: (for STMPLOT) ',PINPT%stm_ngrid(1:3)
  elseif(.not. PINPT%flag_default_stm_ngrid .and. PINPT%flag_plot_stm_image) then
    if(myid .eq. 0) write(6,'(A,3(I6))')'   N_GRID: (for STMPLOT) ',PINPT%stm_ngrid(1:3)
  endif

  if(PINPT%flag_default_rorigin) then
    PINPT%r_origin(1:3) = 0d0
  endif

  ! setup atom index for ldos if not allocated
  if(PINPT_DOS%dos_flag_print_ldos .and. PINPT_DOS%dos_ldos_natom .eq. 0) then 
    allocate(PINPT_DOS%dos_ldos_atom(PGEOM%n_atom))
    do i = 1, PGEOM%n_atom
      PINPT_DOS%dos_ldos_atom(i) = i
    enddo
    PINPT_DOS%dos_ldos_natom = PGEOM%n_atom
    if_main write(6,'(A,I0)')' DOS_LDOS: .TRUE. , Atom_index = 1:',PGEOM%n_atom
  endif
  ! setup atom index for projected band if not allocated
  if(PINPT%flag_print_proj_sum) then
    allocate(proj_natom_dummy(PINPT%nproj_sum))
    proj_natom_dummy = 0
    proj_natom_dummy(1:PINPT%nproj_sum) = PINPT%proj_natom(1:PINPT%nproj_sum)
    deallocate(PINPT%proj_natom); allocate(PINPT%proj_natom(PINPT%nproj_sum))
    PINPT%proj_natom = proj_natom_dummy
    
    allocate(proj_atom_dummy(maxval(PINPT%proj_natom(1:PINPT%nproj_sum)),PINPT%nproj_sum))
    proj_atom_dummy = 0
    do i = 1, PINPT%nproj_sum
      proj_atom_dummy(1:PINPT%proj_natom(i),i) = PINPT%proj_atom(1:PINPT%proj_natom(i),i)
    enddo
    deallocate(PINPT%proj_atom); 
    allocate(PINPT%proj_atom(maxval(PINPT%proj_natom(1:PINPT%nproj_sum)),PINPT%nproj_sum))
    do i = 1, PINPT%nproj_sum
      PINPT%proj_atom(1:PINPT%proj_natom(i),i) = proj_atom_dummy(1:PINPT%proj_natom(i),i)
    enddo

    deallocate(proj_natom_dummy)
    deallocate(proj_atom_dummy)
  endif

  ! read info: kpoint 
  if(flag_kfile_exist) then
    call read_kpoint(PINPT%kfilenm,PKPTS,PGEOM,PINPT)
  elseif( (.not. flag_kfile_exist .and. PINPT%flag_get_band) .or. &
          (.not. flag_kfile_exist .and. PINPT%flag_get_berry_curvature) ) then
    if_main write(6,'(A,A,A)')'  !WARN! ',trim(PINPT%kfilenm),' does not exist!! Exit...'
    kill_job
  endif

  ! read info: target energy to be fitted with
  if(PINPT%flag_collinear .and. flag_read_energy .and. PINPT%flag_tbfit) then 
    if(flag_efileu_exist .and. flag_efiled_exist .and. PINPT%efile_type .eq. 'user') then
      flag_efile_exist = .true.
    elseif(flag_efileu_exist .and. PINPT%efile_type .eq. 'vasp' ) then
      flag_efile_exist = .true. 
    else
      flag_efile_exist = .false.
    endif
  elseif(.not. PINPT%flag_collinear .and. flag_read_energy .and. PINPT%flag_tbfit) then
    if(flag_efileu_exist) then
      flag_efile_exist = .true.
    else
      flag_efile_exist = .false.
    endif
  endif

  if(PINPT%flag_tbfit .and. flag_efile_exist .and. flag_read_energy) then

    if(PWGHT%flag_weight_default) then
      allocate(PWGHT%WT(PGEOM%neig*PINPT%ispin, PKPTS%nkpoint))
      PWGHT%WT(:,:)=0.00001d0 !initialize

      if(PINPT%efile_type .eq. 'vasp') then
        call read_energy_vasp(PINPT,PGEOM,PKPTS,EDFT,EDFT_all,PWGHT)
      else
        call read_energy(PINPT,PGEOM,PKPTS,EDFT,EDFT_all,PWGHT)
      endif

      if(PINPT%flag_print_only_target ) then
        if_main call print_energy_weight( PKPTS%kpoint, PKPTS%nkpoint, EDFT, PWGHT, PGEOM%neig, PINPT, &
                                  'band_structure_DFT.dat')
        if_main  write(6,'(A,A,A)')'  !WARN! PRINT_ONLY_TARGET requested..'
        if_main  write(6,'(A,A,A)')'  !WARN! check band_structure_DFT.dat  Exit..'
        kill_job
      endif

    elseif(.not. PWGHT%flag_weight_default) then
      allocate(PWGHT%WT(PGEOM%neig*PINPT%ispin, PKPTS%nkpoint))

      if(PINPT%efile_type .eq. 'vasp') then
        call read_energy_vasp(PINPT,PGEOM,PKPTS,EDFT,EDFT_all,PWGHT)
      else
        call read_energy(PINPT,PGEOM,PKPTS,EDFT,EDFT_all,PWGHT)
      endif
      PWGHT%WT(:,:)=0.00001d0 !initialize

      do i=1, PWGHT%nweight
        call set_weight(PINPT, PGEOM, PKPTS, PWGHT, EDFT, EDFT_all, PINPT%strip_kp(i), PINPT%strip_tb(i), &
                        PINPT%strip_df(i), PINPT%strip_wt(i))
      enddo
      ! normalize weight so that their sum to be 1
      !PWGHT%WT = PWGHT%WT / sum(PWGHT%WT)

      if(PINPT%flag_print_only_target ) then
        if_main call print_energy_weight( PKPTS%kpoint, PKPTS%nkpoint, EDFT, PWGHT, PGEOM%neig, PINPT, &
                                         'band_structure_DFT.dat')

        if_main write(6,'(A,A,A)')'  !WARN! PRINT_ONLY_TARGET requested..'
        if_main write(6,'(A,A,A)')'  !WARN! check band_structure_DFT.dat  Exit..'
        kill_job
      endif

    endif

    if(PWGHT%flag_weight_default_orb) then
      allocate(PWGHT%PENALTY_ORB(PGEOM%neig*PINPT%ispin,PGEOM%neig*PINPT%ispin, PKPTS%nkpoint))
      PWGHT%PENALTY_ORB(:,:,:) = 0.d0 ! initialize & set default value (zeros for all)
    elseif(.not. PWGHT%flag_weight_default_orb) then
      allocate(PWGHT%PENALTY_ORB(PGEOM%neig*PINPT%ispin,PGEOM%neig*PINPT%ispin, PKPTS%nkpoint))
      PWGHT%PENALTY_ORB(:,:,:) = 0.d0 ! initialize
      do i = 1, PWGHT%npenalty_orb
!write(6,*)"XXX ", i
        call set_penalty_orb(NN_TABLE, PINPT, PGEOM, PKPTS, PWGHT, PINPT%strip_kp_orb(i), PINPT%strip_tb_orb(i), &
                             PINPT%strip_orb(i), PINPT%strip_site(i), PINPT%strip_pen_orb(i) )
      enddo
    endif
!stop
  elseif(PINPT%flag_tbfit .and. .not. flag_efile_exist .and. flag_read_energy) then
    if(myid .eq. 0) write(6,'(A,A,A)')'  !WARN! ',trim(PINPT%efilenmu),' does not exist!! Exit...'
    kill_job

  elseif(PINPT%flag_tbfit .and. .not. flag_efile_exist .and. .not. flag_read_energy) then
    if(myid .eq. 0) write(6,'(A)')'  !WARN! TBFIT=.true. but the target data (EFILE) does not specified. Exit...'
    kill_job
  endif


  if(PINPT%flag_get_zak_phase) then
    call set_berry_erange(PINPT_BERRY, PGEOM, PINPT, 'zk')
    call set_berry_kpath (PINPT_BERRY, PGEOM, PINPT, 'zk')
  endif
  if(PINPT%flag_get_wcc) then
    call set_berry_erange(PINPT_BERRY, PGEOM, PINPT, 'wc')
    call set_berry_kpath (PINPT_BERRY, PGEOM, PINPT, 'wc')
  endif
  if(PINPT%flag_get_berry_curvature) then
    call set_berry_erange(PINPT_BERRY, PGEOM, PINPT, 'bc')
  endif
  if(PINPT%flag_get_z2) then
    call set_berry_erange(PINPT_BERRY, PGEOM, PINPT, 'z2')
  endif
  if(PINPT%flag_get_parity)  call get_kpoint(PINPT_BERRY%parity_kpoint, PINPT_BERRY%parity_kpoint_reci, PINPT_BERRY%parity_nkpoint, PGEOM)
  if(PINPT%flag_get_symmetry)call get_kpoint(PINPT_BERRY%symmetry_kpoint, PINPT_BERRY%symmetry_kpoint_reci, PINPT_BERRY%symmetry_nkpoint, PGEOM)

  if(.not.PINPT%flag_erange) then
    PINPT%init_erange = 1 ! default
    PINPT%fina_erange = PGEOM%neig*PINPT%ispinor ! default
    PINPT%nband = PGEOM%neig*PINPT%ispinor ! default
    if(PINPT%flag_sparse) then
      ! initial number of ncsr will not exeed n_neighbor. 
      ! Note that this will be adjusted later in the "get_eig" routine by 
      ! constructing the Hamiltonian with Compressed Sparse array format.
      if(PINPT%feast_nemax .le. 0) then
        PINPT%nband = PGEOM%neig*PINPT%ispinor ! default (do not save memory...)
        PINPT%init_erange = 1
        PINPT%fina_erange = PGEOM%neig*PINPT%ispinor
      elseif(PINPT%feast_nemax .ge. 1) then
        if(PINPT%feast_nemax .gt. PGEOM%neig * PINPT%ispinor) then
          if_main write(6,'(A,I0,A)')'    !WARN! The NE_MAX (',PINPT%feast_nemax,') of EWINDOW tag is larger than the eigenvalues (NEIG)'
          if_main write(6,'(A,I0,A)')'           of the system (',PGEOM%neig * PINPT%ispinor,'). Hence, we enforce NEMAX = NEIG.'
          if_main write(6,'(A,I0,A)')'           Otherwise, you can reduce the expected NE_MAX within the EWINDOW with a proper guess.'
          PINPT%nband = PGEOM%neig * PINPT%ispinor
          PINPT%feast_nemax = PINPT%nband
        else
          PINPT%nband = PINPT%feast_nemax
        endif
        PINPT%init_erange = 1
        PINPT%fina_erange = PINPT%nband
      endif
    endif
  endif


  if(PINPT%flag_sparse .and. PINPT%flag_get_effective_ham) then
    if_main write(6,'(A)')'    !WARN! The EWINDOW tag and LOWDIN cannot be used simulatneously in the current version.'
    if_main write(6,'(A)')'           Exit program...'
    kill_job
  elseif(.not. PINPT%flag_sparse .and. PINPT%flag_get_effective_ham) then
    if(.not. (PRPLT%flag_replot_dos .or. PRPLT%flag_replot_ldos .or. PRPLT%flag_replot_sldos .or. PRPLT%flag_replot_didv)) then
      call set_effective_orbital_index(PINPT, PGEOM, NN_TABLE)
    endif
  endif

! if(PRPLT%flag_replot_dos .or. PRPLT%flag_replot_ldos) then
!  
!   ! setup ldos atom if not allocated
!   if(PRPLT%flag_replot_ldos .and. PRPLT%replot_ldos_natom .eq. 0) then
!     allocate(PRPLT%replot_ldos_atom(PGEOM%n_atom))
!     do i = 1, PGEOM%n_atom
!       PRPLT%replot_ldos_atom(i) = i
!     enddo
!     PRPLT%replot_ldos_natom = PGEOM%n_atom
!     if_main write(6,'(A,I0)')' REPLOT_LDOS: .TRUE. , Atom_index = 1:',PGEOM%n_atom
!   endif
! endif

  if(PINPT%flag_slater_koster .and. (PINPT%flag_plot_stm_image .or. PINPT%flag_plot_eigen_state) ) then
    call set_effective_nuclear_charge(PGEOM)
 !  call set_angular_momentum_quatnum_number(PGEOM)
  endif

  if(PINPT%flag_tbfit .and. PINPT%flag_print_energy_diff ) then 
    if(PINPT%flag_print_orbital) PINPT%flag_print_energy_diff = .false.
  else
    PINPT%flag_print_energy_diff = .false.
  endif

  if(.not. PINPT%flag_slater_koster .and. PINPT%flag_use_overlap) then
    if_main write(6,'(A)')'    !WARN! Construction of overlap matrix is only available within Slakter-Koster method turned on.'
    if_main write(6,'(A)')'           Set "USE_OVERLAP .FALSE." in your PARAM_FIT.dat file or set "IS_SK .TRUE." and prepare '
    if_main write(6,'(A)')'           proper parameter set for overlap integrals, for example, o_pps_1_CC, o_sps_1_CC, and etc., to proceed'
    if_main write(6,'(A)')'           Exit program...'
    kill_job
  endif

  if(myid .eq. 0) write(6,*)'---- END READING INPUT FILE ---------------------'
  if(myid .eq. 0) write(6,*)' '
return
endsubroutine
