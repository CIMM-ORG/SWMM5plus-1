module parabolic_channel

    use define_settings, only: setting
    use define_globals
    use define_indexes
    use define_keys

    implicit none

    !%----------------------------------------------------------------------------- 
    !% Description:
    !% parabolic channel geometry
    !%

    private

    public :: parabolic_depth_from_volume
    public :: parabolic_area_from_depth
    public :: parabolic_area_from_depth_singular
    public :: parabolic_topwidth_from_depth
    public :: parabolic_topwidth_from_depth_singular 
    public :: parabolic_perimeter_from_depth
    public :: parabolic_perimeter_from_depth_singular
    public :: parabolic_hyddepth_from_depth
    public :: parabolic_hyddepth_from_depth_singular
    public :: parabolic_hydradius_from_depth_singular

    contains

!%==========================================================================
!% PUBLIC
!%==========================================================================
!%
    subroutine parabolic_depth_from_volume (elemPGx, Npack, thisCol)
        !%-----------------------------------------------------------------------------
        !% Description:
        !% Only applies on open channels (or non-surcharged parabolic conduits)
        !% Input elemPGx is pointer (already assigned) for elemPGalltm, elemPGetm or elemPGac
        !% Assumes that volume > 0 is enforced in volume computations.
        !% NOTE: this does NOT limit the depth by surcharge height at this point
        !% This will be done after the head is computed.
        !%-----------------------------------------------------------------------------
        integer, target, intent(in) :: elemPGx(:,:), Npack, thisCol
        integer, pointer :: thisP(:)
        real(8), pointer :: depth(:), volume(:), length(:), breadth(:), fulldepth(:), rbot(:)
        !%-----------------------------------------------------------------------------
        thisP   => elemPGx(1:Npack,thisCol) 
        depth   => elemR(:,er_Depth)
        volume  => elemR(:,er_Volume)
        length  => elemR(:,er_Length)
        fulldepth => elemR(:,er_FullDepth)
        breadth => elemSGR(:,esgr_Parabolic_Breadth)
        rbot => elemSGR(:, esgr_Parabolic_Radius)
        !%-----------------------------------------------------------------------------  

        depth(thisP) = ( threeR/fourR * (volume(thisP)/length(thisP)) / rbot(thisP) ) ** twothirdR
    end subroutine parabolic_depth_from_volume
    !%  
!%==========================================================================
!%==========================================================================
!%
    elemental real(8) function parabolic_area_from_depth (indx) result (outvalue)
        !%-----------------------------------------------------------------------------
        !% Description:
        !% Computes area from known depth for parabolic cross section
        !%-----------------------------------------------------------------------------
        integer, intent(in) :: indx  ! may be a packed array of indexes
        !%-----------------------------------------------------------------------------
        
        outvalue = (fourR / threeR) * elemSGR(indx, esgr_Parabolic_Radius) * elemR(indx, er_Depth) *  sqrt(elemR(indx, er_Depth))
        
    end function parabolic_area_from_depth
!%
!%==========================================================================
!%==========================================================================
!%
    real(8) function parabolic_area_from_depth_singular (indx, depth) result (outvalue)
        !%-----------------------------------------------------------------------------
        !% Description:
        !% Computes area from known depth for parabolic cross section of a single element
        !% The input indx is the row index in full data 2D array.
        !%-----------------------------------------------------------------------------
        integer, intent(in) :: indx
        real(8), intent(in) :: depth
        real(8), pointer ::  breadth(:), fulldepth(:), rbot(:)
        !%-----------------------------------------------------------------------------
        breadth => elemSGR(:,esgr_Parabolic_Breadth)
        fulldepth => elemR(:, er_FullDepth)
        rbot => elemSGR(:, esgr_Parabolic_Radius)
        !%-----------------------------------------------------------------------------
       ! print *, 'in parabolic_area_from_depth_singular'
       ! print *, indx, breadth(indx), depth
        outvalue = (fourR / threeR) * rbot(indx) * depth *  sqrt(depth)

    end function parabolic_area_from_depth_singular
!%
!%==========================================================================
!%==========================================================================
!%
    subroutine parabolic_topwidth_from_depth (elemPGx, Npack, thisCol)
        !%  
        !%-----------------------------------------------------------------------------
        !% Description:
        !% Computes the topwidth from a known depth in a parabolic channel
        !%-----------------------------------------------------------------------------
        integer, target, intent(in) :: elemPGx(:,:)
        integer, intent(in) ::  Npack, thisCol
        integer, pointer :: thisP(:), GeomType(:)
        real(8), pointer :: breadth(:), topwidth(:), depth(:), fullDepth(:), rbot(:)
        !%-----------------------------------------------------------------------------
        thisP     => elemPGx(1:Npack,thisCol) 
        GeomType  => elemI(:,ei_geometryType)
        topwidth  => elemR(:,er_Topwidth)
        depth     => elemR(:,er_Depth)
        fullDepth => elemR(:,er_FullDepth)
        breadth   => elemSGR(:,esgr_parabolic_Breadth)
        rbot => elemSGR(:, esgr_Parabolic_Radius)
        !%-----------------------------------------------------------------------------

        topwidth(thisP) = twoR * rbot(thisP) * sqrt(depth(thisP))
        
        ! rbot = (breadth(thisP) / twoR / sqrt(fulldepth(thisP)))

        ! return 2.0 * xsect->rBot * sqrt(y);

    end subroutine parabolic_topwidth_from_depth
!%    
!%==========================================================================
!%==========================================================================
!%
    real(8) function parabolic_topwidth_from_depth_singular (indx, depth) result (outvalue)
        !%-----------------------------------------------------------------------------
        !% Description:
        !% Computes the topwidth for a parabolic cross section of a single element
        !%-----------------------------------------------------------------------------
        integer, intent(in) :: indx 
        real(8), intent(in) :: depth
        real(8), pointer ::  breadth(:), fulldepth(:), rbot(:)
        !%-----------------------------------------------------------------------------
        breadth => elemSGR(:,esgr_parabolic_Breadth)
        fulldepth => elemR(:, er_FullDepth)
        rbot => elemSGR(:, esgr_Parabolic_Radius)
        !%-----------------------------------------------------------------------------
        !%  
        outvalue = twoR * rbot(indx) * sqrt(depth)

        ! outvalue = twoR * sqrt(((elemSGR(indx, esgr_Parabolic_Breadth) * elemSGR(indx, esgr_Parabolic_Breadth)) / fourR * elemR(indx, er_FullDepth) ) * depth)

    end function parabolic_topwidth_from_depth_singular
!%
!%==========================================================================
!%==========================================================================
!%
    subroutine parabolic_perimeter_from_depth (elemPGx, Npack, thisCol)
        !%  
        !%-----------------------------------------------------------------------------
        !% Description:
        !% Computes the perimeter from a known depth in a parabolic channel
        !%-----------------------------------------------------------------------------
        integer, target, intent(in) :: elemPGx(:,:)
        integer, intent(in) ::  Npack, thisCol
        integer, pointer :: thisP(:)
        real(8), pointer :: breadth(:), depth(:), perimeter(:), fulldepth(:), rbot(:), temp02(:), temp03(:)
        !%-----------------------------------------------------------------------------
        thisP     => elemPGx(1:Npack,thisCol) 
        breadth   => elemSGR(:,esgr_parabolic_Breadth)
        depth     => elemR(:,er_Depth)
        perimeter => elemR(:,er_Perimeter)
        fulldepth => elemR(:,er_FullDepth)
        rbot    => elemSGR(:,esgr_Parabolic_Radius)
        temp02    => elemR(:, er_Temp02)
        temp03    => elemr(:, er_Temp03)
        !%-----------------------------------------------------------------------------
        ! rbot = (breadth / twoR / sqrt(fulldepth))temp01
        temp02(thisP) = (twoR * sqrt(depth(thisP)) / (breadth(thisP) / twoR / sqrt(fulldepth(thisP))))
        temp03(thisP) = (oneR + temp02(thisP) * temp02(thisP))

        ! t = sqrt(oneR + (twoR * sqrt(depth(:)) / (breadth(:) / twoR / sqrt(fulldepth(:)))) * (twoR * sqrt(depth(:)) / (breadth(:) / twoR / sqrt(fulldepth(:)))))
        ! t = sqrt(oneR + x * x)
        !%-----------------------------------------------------------------------------

        perimeter(thisP) = onehalfR * rbot(thisP) * rbot(thisP) * (temp02(thisP) * temp03(thisP) + log(temp02(thisP) + temp03(thisP)))

        ! perimeter(thisP) = onehalfR * (breadth(thisP) / twoR / sqrt(fulldepth(thisP))) * (breadth(thisP) / twoR / sqrt(fulldepth(thisP))) * &
        ! ((twoR * sqrt(depth(thisP)) / (breadth(thisP) / twoR / sqrt(fulldepth(thisP)))) * &
        ! sqrt(oneR + (twoR * sqrt(depth(thisP)) / (breadth(thisP) / twoR / sqrt(fulldepth(thisP)))) * (twoR * sqrt(depth(thisP)) / (breadth(thisP) / twoR / sqrt(fulldepth(thisP))))) + &
        ! log((twoR * sqrt(depth(thisP)) / (breadth(thisP) / twoR / sqrt(fulldepth(thisP)))) + &
        ! sqrt(oneR + (twoR * sqrt(depth(thisP)) / (breadth(thisP) / twoR / sqrt(fulldepth(thisP)))) * (twoR * sqrt(depth(thisP)) / (breadth(thisP) / twoR / sqrt(fulldepth(thisP)))))))

        ! rbot = (breadth(thisP) / twoR / sqrt(fulldepth(thisP)))
        ! x = (twoR * sqrt(depth(thisP)) / (breadth(thisP) / twoR / sqrt(fulldepth(thisP))))
        ! t = sqrt(oneR + (twoR * sqrt(depth(thisP)) / (breadth(thisP) / twoR / sqrt(fulldepth(thisP)))) * (twoR * sqrt(depth(thisP)) / (breadth(thisP) / twoR / sqrt(fulldepth(thisP)))))
    end subroutine parabolic_perimeter_from_depth
!%    
!%==========================================================================    
!%==========================================================================
!%
    real(8) function parabolic_perimeter_from_depth_singular (indx, depth) result (outvalue)
        !%  
        !%-----------------------------------------------------------------------------
        !% Description:
        !% Computes wetted perimeter from known depth for a parabolic cross section of
        !% a single element 
        !%-----------------------------------------------------------------------------
        !%-----------------------------------------------------------------------------
        integer, intent(in) :: indx
        real(8), intent(in) :: depth
        real(8) :: x, t
        real(8), pointer ::  breadth(:), fulldepth(:), rbot(:)
        !%-----------------------------------------------------------------------------
        breadth => elemSGR(:,esgr_parabolic_Breadth)
        fulldepth => elemR(:, er_FullDepth)
        rbot => elemSGR(:, esgr_Parabolic_Radius)
        !%-----------------------------------------------------------------------------
        x = (twoR * sqrt(depth) / rbot(indx))
        ! t = sqrt(oneR + (twoR * sqrt(depth(:)) / (breadth(:) / twoR / sqrt(fulldepth(:)))) * (twoR * sqrt(depth(:)) / (breadth(:) / twoR / sqrt(fulldepth(:)))))
        t = sqrt(oneR + (x * x))
        !%-----------------------------------------------------------------------------

        outvalue = onehalfR * rbot(indx) * rbot(indx) * (x * t + log(x + t))


    end function parabolic_perimeter_from_depth_singular
!%    
!%==========================================================================
!%==========================================================================
!%
    subroutine parabolic_hyddepth_from_depth (elemPGx, Npack, thisCol)
        !%  
        !%-----------------------------------------------------------------------------
        !% Description:
        !% Computes the hydraulic (average) depth from a known depth in a parabolic channel
        !%-----------------------------------------------------------------------------
        integer, target, intent(in) :: elemPGx(:,:)
        integer, intent(in) ::  Npack, thisCol
        integer, pointer :: thisP(:)
        real(8), pointer :: hyddepth(:), depth(:)
        !%-----------------------------------------------------------------------------
        thisP     => elemPGx(1:Npack,thisCol) 
        depth     => elemR(:,er_Depth)
        hyddepth  => elemR(:,er_HydDepth)
        !%-----------------------------------------------------------------------------

        hyddepth(thisP) = (twoR/threeR) * depth(thisP)

    end subroutine parabolic_hyddepth_from_depth
!%    
!%==========================================================================  
!%==========================================================================
!%
    real(8) function parabolic_hyddepth_from_depth_singular (indx,depth) result (outvalue)
        !%  
        !%-----------------------------------------------------------------------------
        !% Description:
        !% Computes hydraulic depth from known depth for parabolic cross section of 
        !% a single element
        !%-----------------------------------------------------------------------------   
        integer, intent(in) :: indx   
        real(8), intent(in) :: depth  
        !%-----------------------------------------------------------------------------  

        outvalue = (twoR/threeR) * depth

    end function parabolic_hyddepth_from_depth_singular
!%    
!%==========================================================================
!%==========================================================================
!%
!%    
!%==========================================================================
!%==========================================================================
!%
    real(8) function parabolic_hydradius_from_depth_singular &
        (indx, depth) result (outvalue)
        !%------------------------------------------------------------------
        !% Description:
        !% Computes hydraulic radius from known depth for a parabolic cross section of
        !% a single element 
        !%------------------------------------------------------------------
            integer, intent(in) :: indx
            real(8), intent(in) :: depth
            real(8) :: x, t, area, perimeter
            real(8), pointer :: breadth(:), fulldepth(:), rbot(:)
        !%------------------------------------------------------------------
        breadth => elemSGR(:,esgr_parabolic_Breadth)
        fulldepth => elemR(:, er_FullDepth)
        rbot => elemSGR(:, esgr_Parabolic_Radius)
        !%------------------------------------------------------------------
        x = (twoR * sqrt(depth) / rbot(indx))
        t = sqrt(oneR + (x * x))
        area = (fourR / threeR) * rbot(indx) * depth *  sqrt(depth)
        perimeter = onehalfR * rbot(indx) * rbot(indx) * (x * t + log(x + t))
        
        outvalue = area / perimeter

    end function parabolic_hydradius_from_depth_singular
!%      

!%==========================================================================
!% PRIVATE
!%==========================================================================   
!%  
        !%-----------------------------------------------------------------------------
        !% Description:
        !% 
        !%-----------------------------------------------------------------------------

        !%-----------------------------------------------------------------------------
        !%  

       !%==========================================================================   
    ! !%
    ! subroutine parabolic_open_head_from_volume (elemPGx, Npack, thisCol)
    !     !%-----------------------------------------------------------------------------
    !     !% Description:
    !     !% Only applies on open channels (or non-surcharged parabolic conduits)
    !     !% Input elemPGx is pointer (already assigned) for elemPGalltm, elemPGetm or elemPGac
    !     !% Assumes that volume > 0 is enforced in volume computations.
    !     !%-----------------------------------------------------------------------------
    !     integer, target, intent(in) :: elemPGx(:,:), Npack, thisCol
    !     integer, pointer :: thisP(:)
    !     real(8), pointer :: head(:), volume(:), length(:), breadth(:), zbottom(:)
    !     !%-----------------------------------------------------------------------------
    !     thisP   => elemPGx(1:Npack,thisCol) 
    !     head    => elemR(:,er_Head)
    !     volume  => elemR(:,er_Volume)
    !     length  => elemR(:,er_Length)
    !     breadth => elemSGR(:,esgr_parabolic_Breadth)
    !     zbottom => elemR(:,er_Zbottom)
    !     !%-----------------------------------------------------------------------------   

    !     head(thisP) = zbottom(thisP) + volume(thisP) / (length(thisP) * breadth(thisP))
   
    ! end subroutine parabolic_open_head_from_volume
    !%  
    !%==========================================================================
    !%    !%==========================================================================
    !%
    ! subroutine parabolic_area_from_depth (elemPGx, Npack, thisCol)
    !     !%-----------------------------------------------------------------------------
    !     !% Description:
    !     !% Computes area of a parabolic open channel given its depth
    !     !% Note, does NOT consider any closed top!
    !     !%-----------------------------------------------------------------------------
    !     integer, target, intent(in) :: elemPGx(:,:)
    !     integer, intent(in) ::  Npack, thisCol
    !     integer, pointer :: thisP(:)
    !     real(8), pointer :: area(:), depth(:), breadth(:)
    !     !%-----------------------------------------------------------------------------
    !     thisP   => elemPGx(1:Npack,thisCol) 
    !     area    => elemR(:,er_Area)
    !     depth   => elemR(:,er_Depth)
    !     breadth => elemSGR(:,esgr_parabolic_Breadth)
    !     !%-----------------------------------------------------------------------------

    !     area(thisP) = depth(thisP) * breadth(thisP)

    ! end subroutine parabolic_area_from_depth
    ! !%
    ! !%==========================================================================
    !%==========================================================================
    !% END OF MODULE
    !%+=========================================================================
end module parabolic_channel