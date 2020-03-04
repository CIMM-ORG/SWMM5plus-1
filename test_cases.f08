! module test_cases
!
! Calling routines for custom test cases, e.g. calls the case_simple_channel
! functions to setup a single channel reach.
!
!==========================================================================
!
 module test_cases
!
    use array_index
    use bc
    use case_simple_channel
    use case_simple_weir
    use case_y_channel
    use data_keys
    use globals
    use setting_definition
    use utility

    implicit none

    private

    public :: test_case_initiation

    integer :: debuglevel = 0

 contains
!
!==========================================================================
!==========================================================================
!
 subroutine test_case_initiation &
    (linkR, nodeR, linkI, nodeI, linkYN, nodeYN, linkName, nodeName, &
     bcdataDn, bcdataUp)

 character(64) :: subroutine_name = 'test_case_initiation'

 integer,      dimension(:,:), allocatable, intent(out) :: linkI
 integer,      dimension(:,:), allocatable, intent(out) :: nodeI
 real,         dimension(:,:), allocatable, intent(out) :: linkR
 real,         dimension(:,:), allocatable, intent(out) :: nodeR
 logical,      dimension(:,:), allocatable, intent(out) :: linkYN
 logical,      dimension(:,:), allocatable, intent(out) :: nodeYN
 type(string), dimension(:),   allocatable, intent(out) :: linkName
 type(string), dimension(:),   allocatable, intent(out) :: nodeName
 type(bcType), dimension(:),   allocatable, intent(out) :: bcdataUp, bcdataDn

 real, dimension(:), allocatable :: depth_dnstream, depth_upstream, head
 real, dimension(:), allocatable :: subdivide_length, channel_length, channel_breadth
 real, dimension(:), allocatable :: lowerZ, upperZ, flowrate
 real, dimension(:), allocatable :: area, velocity,  Froude, ManningsN
 real, dimension(:), allocatable :: left_slope, right_slope, inlet_offset 
 real, dimension(:), allocatable :: discharge_coefficient, full_depth

 integer, dimension(:), allocatable :: idepth_type

 real :: CFL

 integer :: first_step, last_step, display_interval, mm

 real :: climit, cvel, uz, lz


!--------------------------------------------------------------------------
 if ((debuglevel > 0) .or. (debuglevelall > 0)) print *, '*** enter ',subroutine_name

 select case (setting%TestCase%TestName)

    !% Write a new case statement for each unique test case
    case ('simple_channel_001')

        N_link = 1
        N_node = 1
        N_BCupstream = 1
        N_BCdnstream = 1

        !% create the local variables that must be populated to set up the test case
        call control_variable_allocation &
            (depth_dnstream, depth_upstream, lowerZ, upperZ, channel_length, &
             channel_breadth, subdivide_length, left_slope, flowrate,        &
             right_slope, inlet_offset, discharge_coefficient, full_depth,   &
             area, velocity,  Froude, ManningsN, idepth_type)

        ! step controls
        display_interval = 1000
        first_step = 1
        last_step  =  10000 ! note 1000 is good enough to show blow up or not, 10000 is smooth

        ! set up flow and time step for differen subcases
        ! tests that ran:  Fr = 0.25, 0.5
        Froude       = 0.25   ! determines flowrate and slope to get Froude
        CFL          = 0.25  ! determines dt from subdivide_length

        ! keep these physics fixed
        channel_breadth = 3.0
        depth_upstream  = 1.0
        depth_dnstream  = 1.0
        idepth_type     = 1  !1 = uniform, 2=linear, 3=exponential decay
        ManningsN       = 0.03
        channel_length    = 10000.0
        lowerZ          = 1.0
        subdivide_length = 5000.0

        left_slope   = nullValueR
        right_slope  = nullValueR
        inlet_offset = nullValueR
        discharge_coefficient = nullValueR
        full_depth   = nullValueR

        call froude_driven_setup &
            (upperZ(1), area(1), flowrate(1), velocity(1),  &
             Froude(1),  channel_breadth(1), ManningsN(1), channel_length(1), &
             lowerZ(1),  depth_upstream(1) )

        call this_setting_for_time_and_steps &
            (CFL, velocity, depth_upstream, subdivide_length, &
             first_step, last_step, display_interval,2)

        call case_simple_channel_initialize &
            (channel_length(1), channel_breadth(1), subdivide_length(1), &
             lowerZ(1), upperZ(1), flowrate(1), depth_upstream(1), depth_dnstream(1), &
             ManningsN(1), lManningsN, idepth_type(1),                                   &
             linkR, nodeR, linkI, nodeI, linkYN, nodeYN, linkName, nodeName,    &
             bcdataDn, bcdataUp)

        if (.not. setting%Debugout%SuppressAllFiles) then
            call write_testcase_setup_file &
                (Froude, CFL, flowrate, velocity, depth_upstream,   &
                 depth_dnstream, channel_breadth, area, &
                 channel_length, subdivide_length, &
                 lowerZ, upperZ, ManningsN)
        endif

        !print *, flowrate, depth_dnstream
        !stop

    case ('y_channel_002')

        N_link = 3
        N_node = 4
        N_BCupstream = 2
        N_BCdnstream = 1

        call control_variable_allocation &
            (depth_dnstream, depth_upstream, lowerZ, upperZ, channel_length, &
             channel_breadth, subdivide_length, left_slope, flowrate,        &
             right_slope, inlet_offset, discharge_coefficient, full_depth,   &
             area, velocity,  Froude, ManningsN, idepth_type)

        ! step controls
        display_interval = 1000
        first_step = 1
        last_step  = 10000! note 1000 is good enough to show blow up or not, 10000 is smooth

        ! set up flow and time step for differen subcases
        ! tests that ran:  Fr = 0.25, 0.5
        Froude(1)       = 0.8   ! determines flowrate and slope to get Froude
        Froude(2)       = 0.8  ! determines flowrate and slope to get Froude
        Froude(3)       = 0.8   ! determines flowrate and slope to get Froude

        CFL          = 0.6  ! determines dt from subdivide_length

        depth_dnstream(1)  = 1.0
        depth_upstream(1)  = 1.0 ! junction

        depth_dnstream(2:3) = depth_upstream(1) ! junction should be consistent

        depth_upstream(2)  = 1.0 ! upstream bc right
        depth_upstream(3)  = 1.0 ! upstream bc left
        idepth_type     = 1  !1 = uniform, 2=linear, 3=exponential decay
        ManningsN       = 0.03

        channel_breadth(1)   = 3.0
        channel_breadth(2)   = 3.0
        channel_breadth(3)   = 3.0

        channel_length(1)    = 1000.0
        channel_length(2)    = 1000.0
        channel_length(3)    = 1000.0

        lowerZ(1)           = 1.0
        subdivide_length(1) = 100.0
        subdivide_length(2) = 100.0
        subdivide_length(3) = 100.0


        left_slope   = nullValueR
        right_slope  = nullValueR
        inlet_offset = nullValueR
        discharge_coefficient = nullValueR
        full_depth   = nullValueR

        ! get consistent bottom Z values for the desired Froude number in each link
        do mm=1,N_link
            if (mm==1) then
                ! start with the Z for the inflow link
                lz = lowerZ(1)
            end if
            call froude_driven_setup &
                (uz, area(mm), flowrate(mm), velocity(mm),                               &
                 Froude(mm), channel_breadth(mm), ManningsN(mm), channel_length(mm), &
                 lz, depth_upstream(mm) )
            select case (mm)
                case (1)
                    ! the upstream z of the downstream link becomes the lower z of the upstream links
                    lz = uz
                    upperZ(1) = uz
                case (2,3)
                    lowerZ(mm) = upperZ(1)
                    upperZ(mm) = uz
                    lz = upperZ(1)
            end select
        end do

        call this_setting_for_time_and_steps &
            (CFL, velocity, depth_upstream, subdivide_length, first_step, last_step, &
             display_interval, 2)

        call case_y_channel_initialize &
            (channel_length, channel_breadth, subdivide_length, lowerZ, upperZ, &
             flowrate, depth_upstream, depth_dnstream,                  &
             ManningsN, lManningsN, idepth_type,                            &
             linkR, nodeR, linkI, nodeI, linkYN, nodeYN, linkName, nodeName,    &
             bcdataDn, bcdataUp)

        if (.not. setting%Debugout%SuppressAllFiles) then
            call write_testcase_setup_file &
                (Froude, CFL, flowrate, velocity, depth_upstream,   &
                 depth_dnstream, channel_breadth, area, channel_length, subdivide_length, &
                 lowerZ, upperZ, ManningsN)
        endif


        !print *, flowrate
        !print *, linkR(:,lr_InitialFlowrate)
        !print *, trim(subroutine_name)
        !stop
    case ('simple_weir_003')

        N_link = 3
        N_node = 4
        N_BCupstream = 1
        N_BCdnstream = 1

        !% create the local variables that must be populated to set up the test case
        call control_variable_allocation &
            (depth_dnstream, depth_upstream, lowerZ, upperZ, channel_length, &
             channel_breadth, subdivide_length, left_slope, flowrate,        &
             right_slope, inlet_offset, discharge_coefficient, full_depth,   &
             area, velocity,  Froude, ManningsN, idepth_type)

        ! step controls
        display_interval = 100
        first_step = 1
        last_step  =  30000

        ! set up flow and time step for differen subcases
        ! tests that ran:  Fr = 0.25, 0.5

        ! This is from case_y_channel
        Froude(1)       = 0.25   ! determines flowrate and slope to get Froude
        Froude(2)       = 0.25   ! determines flowrate and slope to get Froude
        Froude(3)       = 0.25   ! determines flowrate and slope to get Froude


        CFL          = 0.25  ! determines dt from subdivide_length

        ! keep these physics fixed
        idepth_type        = 1  !1 = uniform, 2=linear, 3=exponential decay
        ManningsN          = 0.03
        
        lowerZ(1)          = 1.0 
        depth_dnstream(1)  = 1.0e-2 
        depth_upstream(1)  = 1.0e-2

        depth_dnstream(2)  = 1.0e-2         !This is the depth in weir 
        depth_upstream(2)  = 1.0e-2         !This is the depth in weir

        depth_dnstream(3)  = 0.25
        depth_upstream(3)  = 0.25

        channel_breadth(1)   = 3.0
        channel_breadth(2)   = 3.0
        channel_breadth(3)   = 3.0

        channel_length(1)    = 1000.0
        channel_length(2)    = 1        !This is Weir Length
        channel_length(3)    = 1000.0

        subdivide_length(1) = 500.0
        subdivide_length(2) = 1         !We are not subdividing weir element. So this value is same as weir length
        subdivide_length(3) = 500.0

        left_slope   = 1.0
        right_slope  = 1.0
        inlet_offset = 1.0
        discharge_coefficient = 1.40
        full_depth   = 1.5 

        ! get consistent bottom Z values for the desired Froude number in each link
        do mm=1,N_link
            if (mm==1) then
                ! start with the Z for the inflow link
                lz = lowerZ(1)
            end if
            select case (mm)
                case (1)
                    call froude_driven_setup &
                         (uz, area(mm), flowrate(mm), velocity(mm),                          &
                         Froude(mm), channel_breadth(mm), ManningsN(mm), channel_length(mm), &
                         lz, depth_upstream(mm) )
                    ! the upstream z of the downstream link becomes the lower z of the upstream links
                    lz = uz
                    upperZ(1) = uz
                case (2)
                    call weir_setup &
                         (uz, area(mm), flowrate(mm), velocity(mm), left_slope(mm), Froude(mm), &
                          channel_breadth(mm), ManningsN(mm), channel_length(mm), lz,           &
                          depth_upstream(mm) )
                    lowerZ(mm) = upperZ(1)
                    upperZ(mm) = uz
                    lz = uz
                case (3)
                    call froude_driven_setup &
                         (uz, area(mm), flowrate(mm), velocity(mm),                          &
                         Froude(mm), channel_breadth(mm), ManningsN(mm), channel_length(mm), &
                         lz, depth_upstream(mm) )
                    lowerZ(mm) = upperZ(2)
                    upperZ(mm) = uz     
            end select
        end do 

        call this_setting_for_time_and_steps &
            (CFL, velocity, depth_upstream, subdivide_length, &
             first_step, last_step, display_interval,2)

        call case_simple_weir_initialize &
            (channel_length, channel_breadth, subdivide_length, lowerZ, upperZ,  &
             flowrate, depth_upstream, depth_dnstream, left_slope, right_slope,  &
             inlet_offset, discharge_coefficient, ManningsN, full_depth,         &
             lManningsN, idepth_type, linkR, nodeR, linkI, nodeI,linkYN, nodeYN, &
             linkName, nodeName, bcdataDn, bcdataUp)

        if (.not. setting%Debugout%SuppressAllFiles) then
            call write_testcase_setup_file &
                (Froude, CFL, flowrate, velocity, depth_upstream,   &
                 depth_dnstream, channel_breadth, area, channel_length, subdivide_length, &
                 lowerZ, upperZ, ManningsN)
        endif

    case default
        print *, setting%TestCase%TestName
        print *, 'error: no valid test case of ',&
            trim(setting%TestCase%TestName),' in ',subroutine_name
        stop
 end select

 if ((debuglevel > 0) .or. (debuglevelall > 0))  print *, '*** leave ',subroutine_name
 end subroutine test_case_initiation
!
!==========================================================================
!
! PRIVATE BELOW HERE
!
!==========================================================================
!
 subroutine control_variable_allocation &
    (depth_dnstream, depth_upstream, lowerZ, upperZ, channel_length, &
     channel_breadth, subdivide_length, left_slope, flowrate,        &
     right_slope, inlet_offset, discharge_coefficient, full_depth,   &
     area, velocity,  Froude, ManningsN, idepth_type)

 character(64) :: subroutine_name = 'control_variable_allocation'

 real, dimension(:), allocatable, intent(out) :: depth_dnstream, depth_upstream
 real, dimension(:), allocatable, intent(out) :: subdivide_length, channel_length, channel_breadth
 real, dimension(:), allocatable, intent(out) :: lowerZ, upperZ, flowrate
 real, dimension(:), allocatable, intent(out) :: area, velocity, Froude, ManningsN
 real, dimension(:), allocatable, intent(out) :: left_slope, right_slope, inlet_offset
 real, dimension(:), allocatable, intent(out) :: discharge_coefficient, full_depth

 integer, dimension(:), allocatable, intent(out) :: idepth_type

!--------------------------------------------------------------------------
 if ((debuglevel > 0) .or. (debuglevelall > 0)) print *, '*** enter ',subroutine_name

    allocate(depth_dnstream(N_link))
    allocate(depth_upstream(N_link))
    allocate(lowerZ(N_link))
    allocate(upperZ(N_link))
    allocate(channel_length(N_link))
    allocate(channel_breadth(N_link))
    allocate(subdivide_length(N_link))
    !allocate(initial_flowrate(N_link))
    allocate(area(N_link))
    allocate(velocity(N_link))
    allocate(flowrate(N_link))
    allocate(Froude(N_link))
    allocate(ManningsN(N_link))
    allocate(left_slope(N_link))
    allocate(right_slope(N_link))
    allocate(inlet_offset(N_link))
    allocate(discharge_coefficient(N_link))
    allocate(full_depth(N_link))
    allocate(idepth_type(N_link))

 if ((debuglevel > 0) .or. (debuglevelall > 0))  print *, '*** leave ',subroutine_name
 end subroutine control_variable_allocation
!
!==========================================================================
!==========================================================================
!
 subroutine this_setting_for_time_and_steps &
    (CFL, velocity, depth, subdivide_length, first_step, last_step, &
     display_interval, dt_significant_digits)

 character(64) :: subroutine_name = 'this_setting_for_time_and_steps'

 real,  intent(in) :: CFL, velocity(:), depth(:), subdivide_length(:)

 integer, intent(in) :: first_step, last_step, display_interval, dt_significant_digits

 real,  dimension(size(velocity)) :: dtSet, CFLset

 real       :: dtmin
 integer    :: dtscale

!--------------------------------------------------------------------------
 if ((debuglevel > 0) .or. (debuglevelall > 0)) print *, '*** enter ',subroutine_name

! use the same CFL in every link
 CFLset = CFL
! get the set of time step (dt) base on every branch
 dtSet = get_dt_from_CFL (CFL, velocity, depth, subdivide_length)
! get the minimum dt value
 dtmin  = minval(dtSet)
! get the largest n for 10^n relative to the dtmin
 dtscale = utility_scale_of_number(dtmin)


 setting%Time%dt = utility_round_to_significant_digits(dtmin,dt_significant_digits)

 setting%Step%Current = 1

 setting%Step%First = first_step
 setting%Step%Final = last_step

 setting%Debugout%DisplayInterval = display_interval
 setting%OutputThreadedLink%DisplayInterval = display_interval

 setting%Time%StartTime = 0.0
 setting%Time%EndTime = setting%Time%StartTime  &
    + setting%Time%dt * (setting%Step%Final - setting%Step%First + 1)

 if ((debuglevel > 0) .or. (debuglevelall > 0))  print *, '*** leave ',subroutine_name
 end subroutine this_setting_for_time_and_steps
!
!==========================================================================
!==========================================================================
!
 subroutine froude_driven_setup &
    (upperZ, area, flowrate, velocity,  &
     Froude,  breadth, ManningsN, total_length, &
     lowerZ, depth)

 character(64) :: subroutine_name = 'froude_driven_setup'

 real,  intent(out)    :: area, flowrate, velocity, upperZ
 real,  intent(in)     :: Froude,  breadth, ManningsN, lowerZ, total_length
 real,  intent(in)     :: depth

 real :: perimeter, rh, slope


!--------------------------------------------------------------------------
 if ((debuglevel > 0) .or. (debuglevelall > 0)) print *, '*** enter ',subroutine_name

!This needed to be fixed for other geometry types
 area = depth * breadth
 perimeter = 2.0 * depth + breadth
 rh = area / perimeter
 velocity = Froude * sqrt(grav * depth)
 flowrate = area * velocity
 slope = (velocity * ManningsN / (rh**(2.0/3.0)) )**2
 upperZ = lowerZ + slope * total_length

 

! print *,'-----------------'
! print *, area, 'area'
! print *, perimeter, 'perimeter'
! print *, rh, 'rh'
! print *, velocity, 'velocity'
! print *, flowrate, 'flowrate'
! print *, slope, 'slope'
! print *, upperZ, 'upperZ', lowerZ, 'lowerZ'
! print *, total_length, 'total_length'
! print *, slope*total_length, 'slope*total_length'
! print *,'-----------------'
 
 if ((debuglevel > 0) .or. (debuglevelall > 0))  print *, '*** leave ',subroutine_name
 end subroutine froude_driven_setup
!
!==========================================================================
!==========================================================================
!
 subroutine weir_setup &
    (upperZ, area, flowrate, velocity, sideslope, Froude,  breadth, &
     ManningsN, total_length, lowerZ, depth)

 character(64) :: subroutine_name = 'weir_setup'

 real,  intent(out)    :: area, flowrate, velocity, upperZ
 real,  intent(in)     :: Froude,  breadth, ManningsN, lowerZ, total_length
 real,  intent(in)     :: depth, sideslope

 real :: perimeter, rh, slope

!--------------------------------------------------------------------------
 if ((debuglevel > 0) .or. (debuglevelall > 0)) print *, '*** enter ',subroutine_name


! These needed to be changed when the weir is surcharged
 area        = sideslope* depth ** twoR
 perimeter   = twoR * depth * sqrt(1 + sideslope ** 2)
 !rh          = area / perimeter
 !velocity    = (setting%Weir%WeirDischargeCoeff * setting%Weir%WeirSideSlope * depth ** 2.5) / area
 !flowrate    = area * velocity
 !Hard coading this to run the weir without any water
 rh          = 0.0
 velocity    = 0.0
 flowrate    = 0.0
 slope       = zeroR
 upperZ      = lowerZ

 

! print *,'-----------------'
! print *, area, 'area'
! print *, perimeter, 'perimeter'
! print *, rh, 'rh'
! print *, velocity, 'velocity'
! print *, flowrate, 'flowrate'
! print *, slope, 'slope'
! print *, upperZ, 'upperZ', lowerZ, 'lowerZ'
! print *, total_length, 'total_length'
! print *, slope*total_length, 'slope*total_length'
! print *,'-----------------'
 
 if ((debuglevel > 0) .or. (debuglevelall > 0))  print *, '*** leave ',subroutine_name
 end subroutine weir_setup
!
!==========================================================================
!==========================================================================
!
 subroutine write_testcase_setup_file &
    (Froude, CFL, flowrate, velocity, depth_upstream, depth_dnstream, breadth,  &
     area, total_length, subdivide_length, lowerZ, upperZ, ManningsN)

 character(64) :: subroutine_name = ' write_testcase_setup_file'

 real,  intent(in)  :: CFL
 real,  intent(in)  :: Froude(:),  flowrate(:), velocity(:),  breadth(:)
 real,  intent(in)  :: area(:), total_length(:), subdivide_length(:), lowerZ(:), upperZ(:)
 real,  intent(in)  :: ManningsN(:), depth_upstream(:), depth_dnstream(:)

 integer        :: UnitNumber

 character(64)  :: thisFilePath, thisFileStatus, thisFileName
 character(256) :: thisFileWriteName

 logical        :: thisFileisOpen = .false.

 integer                :: open_status
 character(len=512)     :: emsg

!--------------------------------------------------------------------------
 if ((debuglevel > 0) .or. (debuglevelall > 0)) print *, '*** enter ',subroutine_name

 open_status = 0

 UnitNumber = outputfile_next_unitnumber
 outputfile_next_unitnumber = outputfile_next_unitnumber+1

 thisFileName   = trim(setting%TestCase%TestName)
 thisFilePath   = trim(setting%DebugOut%FolderPath) &
                // trim(setting%Debugout%FolderName) // '/'
 thisFileStatus = 'new'
 thisFileIsOpen     = .true.

 thisFileWriteName  = trim(thisFilePath) // &
                      trim(thisFileName) // &
                      trim(setting%Time%DateTimeStamp) //&
                      '.txt'

! print *, trim(setting%TestCase%TestName)
! print *, trim(setting%DebugOut%FolderPath)
! print *, trim(setting%Debugout%FolderName)
!
! print *, trim(thisFileName)
! print *, trim(thisFilePath)
! print *, trim(thisFileWriteName)
! stop
!
 open(unit=UnitNumber, &
      file=trim(thisFileWriteName), &
      status = 'new', &
      access = 'sequential', &
      form   = 'formatted', &
      action = 'write', &
      iostat = open_status)

 emsg = 'file exists: file open failed in '//trim(subroutine_name) &
       // '; filename = '//trim(thisFileWriteName)
 call utility_check_fileopen (open_status, emsg)

 write(UnitNumber,*) trim(setting%TestCase%TestName)
 write(UnitNumber,*) trim(setting%Time%DateTimeStamp)
 write(UnitNumber,*)
 write(UnitNumber,*) Froude  ,'=Froude'
 write(UnitNumber,*) CFL     ,'=CFL combined'
 write(UnitNumber,*) velocity * setting%Time%Dt / subdivide_length,'=CFL advective'
 write(UnitNumber,*) sqrt(grav * depth_upstream) * setting%Time%DT / subdivide_length,'=CFL barotropic'
 write(UnitNumber,*)
 write(UnitNumber,*) flowrate, '=flowrate'
 write(UnitNumber,*) velocity, '=velocity'
 write(UnitNumber,*) setting%Time%Dt,' = dt'
 write(UnitNumber,*)
 write(UnitNumber,*) depth_upstream   ,'=depth upstream'
 write(UnitNumber,*) depth_dnstream   ,'=depth downstream'
 write(UnitNumber,*) breadth ,'=breadth'
 write(UnitNumber,*) area    ,'=area'
 write(UnitNumber,*) total_length ,'=total_length'
 write(UnitNumber,*) subdivide_length ,'=subdivide_length'
 write(UnitNumber,*) area * subdivide_length,'=element_volume'
 write(UnitNumber,*) lowerZ,'=lowerZ'
 write(UnitNumber,*) upperZ,'=upperZ'
 write(UnitNumber,*) (upperZ - lowerZ )/ total_length,'=slope'
 write(UnitNumber,*)
 write(UnitNumber,*) ManningsN,'=ManningsN'
 write(UnitNumber,*)
 write(UnitNumber,*) setting%Step%First,'=first step'
 write(UnitNumber,*) setting%Step%Final,'=last step'
 write(UnitNumber,*) setting%Time%StartTime,'=start time'
 write(UnitNumber,*) setting%Time%EndTime,'=end time'
 write(UnitNumber,*)

 close(UnitNumber)
 outputfile_next_unitnumber = outputfile_next_unitnumber-1

 if ((debuglevel > 0) .or. (debuglevelall > 0))  print *, '*** leave ',subroutine_name
 end subroutine  write_testcase_setup_file
!
!==========================================================================
!==========================================================================
!
 elemental function get_dt_from_CFL &
    (CFL, velocity, depth, element_length) &
    result (dt)

! character(64) :: subroutine_name = 'get_dt_from_CFL'

 real,  intent(in) :: CFL, velocity, depth, element_length
 real :: dt

!--------------------------------------------------------------------------

 dt = CFL * onehalfR * element_length / (velocity + sqrt(grav * depth))

 end function get_dt_from_CFL
!
!==========================================================================
! END OF MODULE test_cases
!==========================================================================
 end module test_cases