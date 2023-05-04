!
!% module pack_mask_arrays
!
!
!==========================================================================
!
!==========================================================================
!
module pack_mask_arrays

    use define_globals
    use define_indexes
    use define_keys
    use define_settings
    use utility_crash
    
    implicit none

    private

    public :: pack_mask_arrays_all
    public :: pack_dynamic_arrays
    public :: pack_nodes_BC
    public :: pack_data_BC
    public :: pack_element_outputML
    public :: pack_face_outputML
    public :: pack_small_or_zero_depth_elements
    public :: pack_CC_zeroDepth_interior_faces
    public :: pack_CC_zeroDepth_shared_faces
    public :: pack_JB_zeroDepth_interior_faces
    public :: pack_JB_zeroDepth_shared_faces

contains
!
!==========================================================================
! PUBLIC
!==========================================================================
!
    subroutine pack_mask_arrays_all()
        !--------------------------------------------------------------------------
        !% set all the static packs and masks
        !--------------------------------------------------------------------------
        integer :: ii
        character(64) :: subroutine_name = 'pack_mask_arrays_all'
        !--------------------------------------------------------------------------
        !if (crashYN) return
        if (setting%Debug%File%pack_mask_arrays) &
            write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        
        !call mask_faces_whole_array_static()
        
        !call pack_geometry_alltm_elements()
        
        call pack_geometry_etm_elements()  
        
        !call pack_geometry_ac_elements()
        
        call pack_nongeometry_static_elements()
        
        call pack_nongeometry_dynamic_elements()

        call pack_static_all_faces ()
        
        call pack_static_interior_faces()
        
        call pack_static_shared_faces()
        
        call pack_jump_interior_faces()
        
        call pack_jump_shared_faces()

        !call pack_small_and_zero_depth_elements(ALLtm, CC)
        !call pack_small_and_zero_depth_elements(ALLtm, JM)
        call pack_small_or_zero_depth_elements(CC,.true.)
        call pack_small_or_zero_depth_elements(JM,.true.)
        if (setting%SmallDepth%useMomentumCutoffYN) then
            call pack_small_or_zero_depth_elements(CC,.false.)
            call pack_small_or_zero_depth_elements(JM,.false.)
        end if

        call pack_CC_zeroDepth_interior_faces ()
        call pack_CC_zeroDepth_shared_faces ()


        if (setting%Debug%File%initial_condition) then
            !% only using the first processor to print results
            if (this_image() == 1) then

                do ii = 1,num_images()
                   print*, '----------------------------------------------------'
                   print*, 'image = ', ii
                   print*, '..........packed local element indexes of...........'
                  ! print*, elemP(:,ep_ALLtm)[ii], 'all ETM, AC elements'
                  ! print*, elemP(:,ep_ETM)[ii], 'all ETM elements'
                   print*, elemP(:,ep_CC)[ii], 'all CC elements'
                   print*, elemP(:,ep_Diag)[ii], 'all diagnostic elements'
                   print*, '.................face logicals......................'
                   print*, faceP(:,fp_noBC_IorS)[ii], 'all the interior faces'
                   print*, facePS(:,fp_noBC_IorS)[ii], 'all the shared faces'
                   ! call execute_command_line('')
                end do

            end if
        end if

        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_mask_arrays_all
!
!==========================================================================
!==========================================================================
!
    subroutine pack_dynamic_arrays()
        !--------------------------------------------------------------------------
        !% set all the dynamic packs and masks
        !--------------------------------------------------------------------------
        character(64) :: subroutine_name = 'pack_dynamic_arrays'
        !--------------------------------------------------------------------------
        !if (crashYN) return
        if (setting%Debug%File%pack_mask_arrays) &
            write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        !call pack_geometry_etm_elements() !% static until AC re-coded
        !call pack_geometry_ac_elements()
        call pack_nongeometry_dynamic_elements()
        call pack_jump_interior_faces()
        call pack_jump_shared_faces()

        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_dynamic_arrays
!    
!==========================================================================    
!==========================================================================
!
    subroutine pack_nodes_BC()
        !--------------------------------------------------------------------------
        !% This allocates and packs the node data in the arrays of node%P.
        !% With this approach using the P type, each of the arrays on the images
        !% are allocated to the size needed.
        !--------------------------------------------------------------------------
        character(64)    :: subroutine_name = 'pack_nodes'
        !--------------------------------------------------------------------------
        if (setting%Debug%File%pack_mask_arrays) &
            write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        N_flowBC = count(node%YN(:,nYN_has_inflow) .and. &
                        (node%I(:,ni_P_image) == this_image()))

        if (N_flowBC > 0) then
            allocate(node%P%have_flowBC(N_flowBC))
            node%P%have_flowBC = pack(node%I(:,ni_idx), &
                node%YN(:,nYN_has_inflow) .and. (node%I(:,ni_P_image) == this_image()))
        end if

        !% HACK -- this assumes that a head BC is always a downstream BC.
        N_headBC = count((node%I(:, ni_node_type) == nBCdn) .and. &
                        (node%I(:,ni_P_image) == this_image()))

        if (N_headBC > 0) then
            allocate(node%P%have_headBC(N_headBC))
            node%P%have_headBC = pack(node%I(:,ni_idx), &
            (node%I(:, ni_node_type) == nBCdn) .and. &
            (node%I(:,ni_P_image) == this_image()))
        end if
        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_nodes_BC
!
!==========================================================================
!==========================================================================
!
    subroutine pack_data_BC
        !--------------------------------------------------------------------------
        !% 
        !--------------------------------------------------------------------------
        integer :: psize
        character(64) :: subroutine_name = 'pack_data_BC'
        !--------------------------------------------------------------------------
        if (setting%Debug%File%pack_mask_arrays) &
            write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        !% BC packs
        !% zero out the number of upBC to get a new count of how many is in a given partition
        N_nBCup = 0
        if (N_flowBC > 0) then
            N_nBCup = count(BC%flowI(:, bi_category) == BCup)
            if (N_nBCup > 0) then
                allocate(BC%P%BCup(N_nBCup))
                BC%P%BCup = pack(BC%flowI(:, bi_idx), BC%flowI(:, bi_category) == BCup)
                !% Face packs
                npack_faceP(fp_BCup) = N_nBCup
                faceP(1:N_nBCup,fp_BCup) = BC%flowI(BC%P%BCup, bi_face_idx)
            end if

            N_nBClat = count(BC%flowI(:, bi_category) == BClat)
            if (N_nBClat > 0) then
                allocate(BC%P%BClat(N_nBClat))
                BC%P%BClat = pack(BC%flowI(:, bi_idx), BC%flowI(:, bi_category) == BClat)
                !% Elem Packs
                npack_elemP(ep_BClat) = N_nBClat
                elemP(1:N_nBClat,ep_BClat) = BC%flowI(BC%P%BClat, bi_elem_idx)
            end if
        end if

        !% BC packs
        !% zero out the number of dnBC to get a new count of how many is in a given partition
        N_nBCdn = 0
        if (N_headBC > 0) then
            N_nBCdn = count(BC%headI(:, bi_category) == BCdn)
            if (N_nBCdn > 0) then
                allocate(BC%P%BCdn(N_nBCdn))
                BC%P%BCdn = pack(BC%headI(:, bi_idx), BC%headI(:, bi_category) == BCdn)
                !% Face packs
                npack_faceP(fp_BCdn) = N_nBCdn
                faceP(1:N_nBCdn,fp_BCdn) = BC%headI(BC%P%BCdn, bi_face_idx)
            end if
        end if
        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_data_BC
!
!==========================================================================
!==========================================================================
!
    subroutine pack_element_outputML ()
        !%-----------------------------------------------------------------
        !% Description:
        !% creates a pack for elemR, elemI, elemYN for output elements
        !%-----------------------------------------------------------------
        !% Declarations:
            logical, pointer :: isElemOut(:), isDummy(:)
            integer, pointer :: eIdx(:), ptype, npack
            character(64) :: subroutine_name = 'pack_element_outputML'
        !%------------------------------------------------------------------
        !% Preliminaries
            if (setting%Output%Report%suppress_MultiLevel_Output) return
            !if (crashYN) return
        !%------------------------------------------------------------------
        !% Aliases
            eIdx => elemI(:,ei_Lidx)
            !% logical control on output for each element
            isElemOut => elemYN(:,eYN_isOutput)
            isDummy   => elemYN(:,eYN_isDummy)
            ptype => col_elemP(ep_Output_Elements)
            npack => npack_elemP(ptype)
        !%------------------------------------------------------------------
        !% count the output elements to be packed
        npack = count(isElemOut .and. (.not. isDummy))

        !% output the true element indexes into a pack
        if (npack > 0) then
            elemP(1:npack,ptype) = pack(eIdx,(isElemOut .and. (.not. isDummy)))
        else 
            !% continue     
        end if    

    end subroutine pack_element_outputML        
!
!==========================================================================
!==========================================================================
!    
    subroutine pack_face_outputML ()
        !%-----------------------------------------------------------------
        !% Description:
        !% packed arrays faceR, faceI, faceYN output elements
        !%-----------------------------------------------------------------
        !% Declarations:
            logical, pointer :: isFaceOut(:)
            integer, pointer :: fIdx(:), ptype, npack
            character(64) :: subroutine_name = 'pack_face_outputML'
        !%-----------------------------------------------------------------
        !% Preliminaries
            if (setting%Output%Report%suppress_MultiLevel_Output) return
            !if (crashYN) return
        !%-----------------------------------------------------------------
        !% Aliases:
            fIdx => faceI(:,fi_Lidx)
            !% logical control on output for each element
            isFaceOut => faceYN(:,fYN_isFaceOut)
            !% pointers for storage of type and npack storage
            ptype => col_faceP(fp_Output_Faces)
            npack => npack_faceP(ptype)
        !%-----------------------------------------------------------------
        !% count the output faces to be packed
        npack = count(isFaceOut)

        !% output the true element indexes into a pack
        if (npack > 0) then
            faceP(1:npack,ptype) = pack(fIdx,isFaceOut)
        else 
            !% continue    
        end if  

    end subroutine pack_face_outputML
!
!==========================================================================
! PRIVATE
!==========================================================================
!
    subroutine pack_geometry_alltm_elements()
        !--------------------------------------------------------------------------
        !% packed arrays for geometry types in elemPGalltm
        !% Note that these CANNOT include surcharging as they
        !% are static arrays
        !--------------------------------------------------------------------------
        integer, pointer :: ptype, npack, eIDx(:)
        character(64) :: subroutine_name = 'pack_geometry_alltm_elements'
        !--------------------------------------------------------------------------
        ! !if (crashYN) return
        ! if (setting%Debug%File%pack_mask_arrays) &
        !     write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        ! eIdx => elemI(:,ei_Lidx)

        ! !% --- rectangular channels 
        ! ptype => col_elemPGalltm(epg_CC_rectangular)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == rectangular) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == rectangular) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- rectangular conduits 
        ! ptype => col_elemPGalltm(epg_CC_rectangular_closed)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == rectangular_closed) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == rectangular_closed) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- trapezoidal channels 
        ! ptype => col_elemPGalltm(epg_CC_trapezoidal)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == trapezoidal) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == trapezoidal) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- triangular channels 
        ! ptype => col_elemPGalltm(epg_CC_triangular)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == triangular) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == triangular) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- rectangular triangular channels 
        ! ptype => col_elemPGalltm(epg_CC_rectangular_triangular)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == rect_triang) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == rect_triang) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- circular conduits 
        ! ptype => col_elemPGalltm(epg_CC_circular)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == circular) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == circular) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- filled circular conduits 
        ! ptype => col_elemPGalltm(epg_CC_filled_circular)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == filled_circular) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == filled_circular) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- irregular channels
        ! ptype => col_elemPGalltm(epg_CC_irregular)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == irregular) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == irregular) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- parabolic channels 
        ! ptype => col_elemPGalltm(epg_CC_parabolic)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == parabolic) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == parabolic) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Basket Handle conduits
        ! ptype => col_elemPGalltm(epg_CC_basket_handle)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == basket_handle) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == basket_handle) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Egg shaped conduits
        ! ptype => col_elemPGalltm(epg_CC_egg_shaped)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == eggshaped) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == eggshaped) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Horse Shoe conduits
        ! ptype => col_elemPGalltm(epg_CC_horse_shoe)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == horseshoe) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == horseshoe) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Catenary conduits
        ! ptype => col_elemPGalltm(epg_CC_catenary)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == Catenary) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == catenary) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if
        !% --- rectangular round channels 
        ! ptype => col_elemPGalltm(epg_CC_rectangular_round_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == rect_round) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == rect_round) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- circular conduits 
        ! ptype => col_elemPGalltm(epg_CC_circular_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == circular) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! !% --- Gothic conduits
        ! ptype => col_elemPGalltm(epg_CC_gothic)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == gothic) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == gothic) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Modified-basket conduits
        ! ptype => col_elemPGalltm(epg_CC_mod_basket)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == mod_basket) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == mod_basket) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Semi-Elliptical conduits
        ! ptype => col_elemPGalltm(epg_CC_semi_elliptical)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == semi_elliptical) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == semi_elliptical) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Semi-Circular conduits
        ! ptype => col_elemPGalltm(epg_CC_semi_circular)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == semi_circular) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == semi_circular) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- junction main with functional geometry relationship
        ! ptype => col_elemPGalltm(epg_JM_functionalStorage)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         (elemSI(:,esi_JunctionMain_Type) == FunctionalStorage) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         (elemSI(:,esi_JunctionMain_Type) == FunctionalStorage) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- junction main with tabular geometry relationship
        ! ptype => col_elemPGalltm(epg_JM_tabularStorage)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         (elemSI(:,esi_JunctionMain_Type) == TabularStorage) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         (elemSI(:,esi_JunctionMain_Type) == TabularStorage) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if
        !% --- parabolic channels 
        ! ptype => col_elemPGalltm(epg_CC_parabolic_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == parabolic) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == parabolic) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Basket Handle conduits
        ! ptype => col_elemPGalltm(epg_CC_basket_handle_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == basket_handle) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == basket_handle) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Horizontal Ellipse conduits
        ! ptype => col_elemPGalltm(epg_CC_horiz_ellipse_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == horiz_ellipse) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == horiz_ellipse) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Vertical Ellipse conduits
        ! ptype => col_elemPGalltm(epg_CC_vert_ellipse_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == vert_ellipse) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == vert_ellipse) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Egg shaped conduits
        ! ptype => col_elemPGalltm(epg_CC_egg_shaped_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == eggshaped) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == eggshaped) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Horse Shoe conduits
        ! ptype => col_elemPGalltm(epg_CC_horse_shoe_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == horseshoe) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == horseshoe) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Catenary conduits
        ! ptype => col_elemPGalltm(epg_CC_catenary_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == Catenary) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == catenary) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Gothic conduits
        ! ptype => col_elemPGalltm(epg_CC_gothic_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == gothic) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == gothic) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Arch conduits
        ! ptype => col_elemPGalltm(epg_CC_arch_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == arch) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == arch) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Modified-basket conduits
        ! ptype => col_elemPGalltm(epg_CC_mod_basket_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == mod_basket) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == mod_basket) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Semi-Elliptical conduits
        ! ptype => col_elemPGalltm(epg_CC_semi_elliptical_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == semi_elliptical) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == semi_elliptical) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- Semi-Circular conduits
        ! ptype => col_elemPGalltm(epg_CC_semi_circular_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == semi_circular) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == semi_circular) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- junction main with functional geometry relationship
        ! ptype => col_elemPGalltm(epg_JM_functionalStorage_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         (elemSI(:,esi_JunctionMain_Type) == FunctionalStorage) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         (elemSI(:,esi_JunctionMain_Type) == FunctionalStorage) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- junction main with tabular geometry relationship
        ! ptype => col_elemPGalltm(epg_JM_tabularStorage_nonsurcharged)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         (elemSI(:,esi_JunctionMain_Type) == TabularStorage) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         (elemSI(:,esi_JunctionMain_Type) == TabularStorage) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! !% --- junction main with artificial storage relationship -- for ALL tm
        ! ptype => col_elemPGalltm(epg_JM_impliedStorage)
        ! npack => npack_elemPGalltm(ptype)
        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         (elemSI(:,esi_JunctionMain_Type) == ImpliedStorage) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
      

        ! if (npack > 0) then
        !     elemPGalltm(1:npack, ptype) = pack(eIdx, &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         (elemSI(:,esi_JunctionMain_Type) == ImpliedStorage) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ))
        ! end if

        ! if (setting%Debug%File%pack_mask_arrays) &
        ! write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_geometry_alltm_elements
!
!==========================================================================
!==========================================================================
!
    subroutine pack_geometry_ac_elements()
        !--------------------------------------------------------------------------
        !% packed arrays for geometry types for AC elements
        !--------------------------------------------------------------------------
        integer, pointer :: ptype, npack, eIDx(:)
        character(64) :: subroutine_name = 'pack_geometry_alltm_elements'
        !--------------------------------------------------------------------------

        !% REQUIRES REVIEW BEFORE UNCOMMENTING

       
        !     if (setting%Debug%File%pack_mask_arrays) &
        !         write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        !     eIdx => elemI(:,ei_Lidx)

        !     !% rectangular channels 
        !     ptype => col_elemPGac(epg_CC_rectangular)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == rectangular) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == rectangular) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% rectangular conduits 
        !     ptype => col_elemPGac(epg_CC_rectangular_closed)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == rectangular_closed) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == rectangular_closed) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% trapezoidal channels 
        !     ptype => col_elemPGac(epg_CC_trapezoidal)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == trapezoidal) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == trapezoidal) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% triangular channels 
        !     ptype => col_elemPGac(epg_CC_triangular)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == triangular) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == triangular) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !    !% irregular channels 
        !     ptype => col_elemPGac(epg_CC_irregular)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == irregular) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == irregular) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% parabolic channels 
        !     ptype => col_elemPGac(epg_CC_parabolic)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == parabolic) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == parabolic) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

            
        !     !% Basket Handle conduits 
        !     ptype => col_elemPGac(epg_CC_basket_handle)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == basket_handle) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !% Horizontal Ellipse conduits 
        ! ptype => col_elemPGac(epg_CC_horiz_ellipse_nonsurcharged)
        ! npack => npack_elemPGac(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == horiz_ellipse) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         )

        ! if (npack > 0) then
        !     elemPGac(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == horiz_ellipse) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged))&
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         )
        ! end if

        ! !% Vertical Ellipse conduits 
        ! ptype => col_elemPGac(epg_CC_vert_ellipse_nonsurcharged)
        ! npack => npack_elemPGac(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == vert_ellipse) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         )

        ! if (npack > 0) then
        !     elemPGac(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == vert_ellipse) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged))&
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         )
        ! end if

        ! !% Egg shaped conduits 
        ! ptype => col_elemPGac(epg_CC_egg_shaped_nonsurcharged)
        ! npack => npack_elemPGac(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == eggshaped) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == basket_handle) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% Egg shaped conduits 
        !     ptype => col_elemPGac(epg_CC_egg_shaped)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == eggshaped) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == eggshaped) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% Egg shaped conduits 
        !     ptype => col_elemPGac(epg_CC_horse_shoe)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == horseshoe) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == horseshoe) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% Catenary shaped conduits 
        !     ptype => col_elemPGac(epg_CC_catenary_nonsurcharged)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == catenary) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == catenary) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% Gothic shaped conduits 
        !     ptype => col_elemPGac(epg_CC_gothic_nonsurcharged)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == gothic) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !% Arch shaped conduits 
        ! ptype => col_elemPGac(epg_CC_arch_nonsurcharged)
        ! npack => npack_elemPGac(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == arch) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         )

        ! if (npack > 0) then
        !     elemPGac(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == arch) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged))&
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         )
        ! end if

        ! !% Modified-basket shaped conduits 
        ! ptype => col_elemPGac(epg_CC_mod_basket_nonsurcharged)
        ! npack => npack_elemPGac(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_geometryType) == mod_basket) &
        !         ) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == gothic) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% Modified-basket shaped conduits 
        !     ptype => col_elemPGac(epg_CC_mod_basket_nonsurcharged)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == mod_basket) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == mod_basket) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% Semi-Elliptical shaped conduits 
        !     ptype => col_elemPGac(epg_CC_semi_elliptical_nonsurcharged)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == semi_elliptical) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == semi_elliptical) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% Semi-Circular shaped conduits 
        !     ptype => col_elemPGac(epg_CC_semi_circular_nonsurcharged)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == semi_circular) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             ( &
        !                 (elemI(:,ei_geometryType) == semi_circular) &
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% rectangular triangular channels 
        !     ptype => col_elemPGac(epg_CC_rectangular_triangular)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == rect_triang) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == rect_triang) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if
        !% rectangular round channels 
        ! ptype => col_elemPGac(epg_CC_rectangular_round_nonsurcharged)
        ! npack => npack_elemPGac(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == rect_round) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         )

        ! if (npack > 0) then
        !     elemPGac(1:npack, ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == rect_round) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged))&
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         )
        ! end if
        
        ! !% circular conduits 
        ! ptype => col_elemPGac(epg_CC_circular_nonsurcharged)
        ! npack => npack_elemPGac(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC)  &
        !         .and. &
        !         (elemI(:,ei_geometryType) == circular) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isSurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         )

        !     !% circular conduits 
        !     ptype => col_elemPGac(epg_CC_circular)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == circular) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == circular) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% filled circular conduits 
        !     ptype => col_elemPGac(epg_CC_filled_circular)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == filled_circular) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             (elemI(:,ei_elementType) == CC)  &
        !             .and. &
        !             (elemI(:,ei_geometryType) == filled_circular) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged))&
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% junction main with functional geometry relationship
        !     ptype => col_elemPGac(epg_JM_functionalStorage)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             ( &
        !                 (elemI(:,ei_elementType) == JM) &
        !             ) &
        !             .and. &
        !             (elemSI(:,esi_JunctionMain_Type) == FunctionalStorage) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             ( &
        !                 (elemI(:,ei_elementType) == JM) &
        !             ) &
        !             .and. &
        !             (elemSI(:,esi_JunctionMain_Type) == FunctionalStorage) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% junction main with functional geometry relationship
        !     ptype => col_elemPGac(epg_JM_tabularStorage)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             ( &
        !                 (elemI(:,ei_elementType) == JM) &
        !             ) &
        !             .and. &
        !             (elemSI(:,esi_JunctionMain_Type) == TabularStorage) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             ( &
        !                 (elemI(:,ei_elementType) == JM) &
        !             ) &
        !             .and. &
        !             (elemSI(:,esi_JunctionMain_Type) == TabularStorage) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             (elemI(:,ei_tmType) == AC) &
        !             )
        !     end if

        !     !% junction main with artificial storage relationship -- for AC
        !     ptype => col_elemPGac(epg_JM_impliedStorage)
        !     npack => npack_elemPGac(ptype)
        !     npack = count( &
        !             ( &
        !                 (elemI(:,ei_elementType) == JM) &
        !             ) &
        !             .and. &
        !             (elemSI(:,esi_JunctionMain_Type) == ImpliedStorage) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             ( elemI(:,ei_tmType) == AC) &
        !             )
        

        !     if (npack > 0) then
        !         elemPGac(1:npack, ptype) = pack(eIdx, &
        !             ( &
        !                 (elemI(:,ei_elementType) == JM) &
        !             ) &
        !             .and. &
        !             (elemSI(:,esi_JunctionMain_Type) == ImpliedStorage) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isACsurcharged)) &
        !             .and. &
        !             ( elemI(:,ei_tmType) == AC) &
        !             )
        !     end if       

        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_geometry_ac_elements
!
!==========================================================================
!==========================================================================
!
    subroutine pack_geometry_etm_elements()
        !%-----------------------------------------------------------------
        !% packed arrays for geometry types that are explicit time marching (ETM)
        !%-----------------------------------------------------------------
            integer, pointer :: ptype, npack, eIDx(:)
            character(64) :: subroutine_name = 'pack_geometry_etm_elements'
        !%------------------------------------------------------------------
        !if (crashYN) return
        if (setting%Debug%File%pack_mask_arrays) &
            write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        eIdx => elemI(:,ei_Lidx)

        !% -----------------
        !% OPEN CHANNELS
        !% -----------------

        !% --- rectangular channels ----------------------------------------
        ptype => col_elemPGetm(epg_CC_rectangular)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemI(:,ei_geometryType) == rectangular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                 (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == rectangular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- trapezoidal channels ------------------------------------------
        ptype => col_elemPGetm(epg_CC_trapezoidal)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == trapezoidal) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == trapezoidal) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- triangular channels --------------------------------------------
        ptype => col_elemPGetm(epg_CC_triangular)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == triangular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )

        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == triangular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- parabolic channels -----------------------------------------
        ptype => col_elemPGetm(epg_CC_parabolic)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemI(:,ei_geometryType) == parabolic) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                 (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == parabolic) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if


        !% --- power function channels -----------------------------------------
        ptype => col_elemPGetm(epg_CC_power_function)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemI(:,ei_geometryType) == power_function) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                 (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == power_function) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if


        !% --- irregular channels --------------------------------------------
        ptype => col_elemPGetm(epg_CC_irregular)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == irregular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == irregular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if


        !% -----------------
        !% CLOSED CONDUITS
        !% -----------------

        !% --- rectangular closed conduits -------------------------------------
        ptype => col_elemPGetm(epg_CC_rectangular_closed)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemI(:,ei_geometryType) == rectangular_closed) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                 (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == rectangular_closed) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% rectangular round conduits 
        ptype => col_elemPGetm(epg_CC_rectangular_round)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == rect_round) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == rect_round) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- rectangular triangular conduits -----------------------------
        ptype => col_elemPGetm(epg_CC_rectangular_triangular)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == rect_triang) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == rect_triang) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- circular conduits ------------------------------------
        ptype => col_elemPGetm(epg_CC_circular)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemI(:,ei_geometryType) == circular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == circular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- Semi-Circular conduits ---------------------------------------
        ptype => col_elemPGetm(epg_CC_semi_circular)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == semi_circular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == semi_circular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- filled circular conduits ---------------------
        ptype => col_elemPGetm(epg_CC_filled_circular)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemI(:,ei_geometryType) == filled_circular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == filled_circular) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- arch conduits ---------------------
        ptype => col_elemPGetm(epg_CC_arch)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemI(:,ei_geometryType) == arch) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == arch) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- Basket Handle conduits -------------------------------------
        ptype => col_elemPGetm(epg_CC_basket_handle)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == basket_handle) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == basket_handle) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- Catenary conduits ------------------------------------------
        ptype => col_elemPGetm(epg_CC_catenary)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == catenary) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == catenary) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- Egg shaped conduits ------------------------------------------
        ptype => col_elemPGetm(epg_CC_egg_shaped)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == eggshaped) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == eggshaped) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- Gothic conduits -----------------------------------------------
        ptype => col_elemPGetm(epg_CC_gothic)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == gothic) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == gothic) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- Horse Shoe conduits ------------------------------------
        ptype => col_elemPGetm(epg_CC_horse_shoe)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == horseshoe) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == horseshoe) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% Horizontal Ellipse conduits 
        ptype => col_elemPGetm(epg_CC_horiz_ellipse)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == horiz_ellipse) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == horiz_ellipse) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- Modified-basket conduits ---------------------------
        ptype => col_elemPGetm(epg_CC_mod_basket)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == mod_basket) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == mod_basket) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- Semi-Elliptical conduits -----------------------------------
        ptype => col_elemPGetm(epg_CC_semi_elliptical)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == semi_elliptical) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == semi_elliptical) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% Vertical Ellipse conduits 
        ptype => col_elemPGetm(epg_CC_vert_ellipse)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                (elemI(:,ei_geometryType) == vert_ellipse) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )

        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == CC)  &
                .and. &
                 (elemI(:,ei_geometryType) == vert_ellipse) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        end if
    

        !% --- JM with functional geometry relationship ------------------
        ptype => col_elemPGetm(epg_JM_functionalStorage)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == JM) &
                .and. &
                (elemSI(:,esi_JunctionMain_Type) == FunctionalStorage) &
                .and. &
                ( elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == JM) &
                .and. &
                (elemSI(:,esi_JunctionMain_Type) == FunctionalStorage) &
                .and. &
                ( elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- JM with tabular geometry relationship --------------------------
        ptype => col_elemPGetm(epg_JM_tabularStorage)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == JM) &
                .and. &
                (elemSI(:,esi_JunctionMain_Type) == TabularStorage) &
                .and. &
                (elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == JM) &
                .and. &
                (elemSI(:,esi_JunctionMain_Type) == TabularStorage) &
                .and. &  
                ( elemI(:,ei_tmType) == ETM) &
                )
        end if

        !% --- JM with implied storage
        ptype => col_elemPGetm(epg_JM_impliedStorage)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == JM) &
                .and. &
                (elemSI(:,esi_JunctionMain_Type) == ImpliedStorage) &
                .and. &
                ( elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == JM) &
                .and. &
                (elemSI(:,esi_JunctionMain_Type) == ImpliedStorage) &
                .and. &
                ( elemI(:,ei_tmType) == ETM) &
                )
        end if 


        !% --- JM with no storage
        ptype => col_elemPGetm(epg_JM_noStorage)
        npack => npack_elemPGetm(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == JM) &
                .and. &
                (elemSI(:,esi_JunctionMain_Type) == NoStorage) &
                .and. &
                ( elemI(:,ei_tmType) == ETM) &
                )
        if (npack > 0) then
            elemPGetm(1:npack, ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == JM) &
                .and. &
                (elemSI(:,esi_JunctionMain_Type) == NoStorage) &
                .and. &
                ( elemI(:,ei_tmType) == ETM) &
                )
        end if 

        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_geometry_etm_elements
!
!==========================================================================
!==========================================================================
!
    subroutine pack_nongeometry_static_elements()
        !--------------------------------------------------------------------------
        !
        !% packed arrays for non geometry static elements
        !%
        !% HACK: Note that in this approach, an element that is diagnostic in Q and
        !% time march in H would appear in both the ep_Diag and ep_ALLtm packed arrays.
        !% Is this something we want to allow? It seems like we might need to require
        !% that an element that is diagnostic in Q must be either diagnostic in H or
        !% doesnotexist. Similarly, an element that is time march in H must be time-march
        !% in Q or doesnotexist
        !
        !--------------------------------------------------------------------------
        integer, pointer :: ptype, npack, eIDx(:) !, fUp(:), fDn(:)
        integer :: ii
        character(64) :: subroutine_name = 'pack_nongeometry_static_elements'
        !--------------------------------------------------------------------------
        !if (crashYN) return
        if (setting%Debug%File%pack_mask_arrays) &
            write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        eIdx => elemI(:,ei_Lidx)

    !% ep_CC
        !% - all CC elements
        ptype => col_elemP(ep_CC)
        npack => npack_elemP(ptype)
        npack = count(elemI(:,ei_elementType) == CC) 
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                     (elemI(:,ei_elementType) == CC) )
        end if

    !% ep_CCJM
        !% - all CC or JM elements
        ptype => col_elemP(ep_CCJM)
        npack => npack_elemP(ptype)
        npack = count(                         &
            ( (elemI(:,ei_elementType) == CC)  &
            .or.                               &
              (elemI(:,ei_elementType) == JM)  &
            ))
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx,     &
                ( (elemI(:,ei_elementType) == CC)  &
                .or.                               &
                  (elemI(:,ei_elementType) == JM)  &
                ))
        end if
  
  
    !% ep_CCJB
        !% - all elements that are CC or JB
        ptype => col_elemP(ep_CCJB)
        npack => npack_elemP(ptype)
        npack = count(                                               &
                    (elemI(:,ei_elementType) == CC)                  &
                    .or.                                             &
                    (                                                &
                        (elemI(:,ei_elementType) == JB)              &
                        .and.                                        &
                        (elemSI(:,esi_JunctionBranch_Exists)== oneI) &
                    ))
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                    (elemI(:,ei_elementType) == CC)                  &
                    .or.                                             &
                    (                                                &
                        (elemI(:,ei_elementType) == JB)              &
                        .and.                                        &
                        (elemSI(:,esi_JunctionBranch_Exists)== oneI) &
                    ))
        end if

    !% ep_CCJBDiag
        !% - all elements that are CC or JB or Diag
        ptype => col_elemP(ep_CCJBDiag)
        npack => npack_elemP(ptype)
        npack = count( &
                    (elemI(:,ei_elementType) == CC)                   &                
                    .or.                                              &
                    (   (elemI(:,ei_elementType) == JB)               &
                        .and.                                         &
                        (elemSI(:,esi_JunctionBranch_Exists) == oneI) &
                    )                                                 &
                    .or.                                              &
                    (elemI(:,ei_QeqType)     == diagnostic)           &
                )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                    (elemI(:,ei_elementType) == CC)                   &                
                    .or.                                              &
                    (   (elemI(:,ei_elementType) == JB)               &
                        .and.                                         &
                        (elemSI(:,esi_JunctionBranch_Exists) == oneI) &
                    )                                                 &
                    .or.                                              &
                    (elemI(:,ei_QeqType)     == diagnostic)           &
                )
        end if

    !% ep_CCDiag
        !% - all elements that are CC or Diag
        ptype => col_elemP(ep_CCDiagJM)
        npack => npack_elemP(ptype)
        npack = count( &
                    (elemI(:,ei_elementType) == CC) &
                    .or. &
                    (elemI(:,ei_QeqType)     == diagnostic) &
                )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                    (elemI(:,ei_elementType) == CC) &
                    .or. &
                    (elemI(:,ei_QeqType)     == diagnostic) &
                )
        end if

    !% ep_CCDiagJM
        !% - all elements that are CC or JM or Diag
        ptype => col_elemP(ep_CCDiagJM)
        npack => npack_elemP(ptype)
        npack = count( &
                    (elemI(:,ei_elementType) == CC) &
                    .or. &
                    (elemI(:,ei_elementType) == JM) &
                    .or. &
                    (elemI(:,ei_QeqType)     == diagnostic) &
                )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                    (elemI(:,ei_elementType) == CC) &
                    .or. &
                    (elemI(:,ei_elementType) == JM) &
                    .or. &
                    (elemI(:,ei_QeqType)     == diagnostic) &
                )
        end if

    !% ep_Diag
        !% - all elements that are diagnostic
        ptype => col_elemP(ep_Diag)
        npack => npack_elemP(ptype)

        npack = count( &
                (elemI(:,ei_QeqType) == diagnostic ) &
                .or. &
                (elemI(:,ei_HeqType) == diagnostic ) &
                )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                (elemI(:,ei_QeqType) == diagnostic ) &
                .or. &
                (elemI(:,ei_HeqType) == diagnostic ) &
                )
        end if

    !% ep_Diag_notJBadjacent
        !% --- elements that are diagnostic and NOT adjacent to JB
        ptype => col_elemP(ep_Diag_notJBadjacent)
        npack => npack_elemP(ptype)

        npack = count ( &
                (   (elemI(:,ei_QeqType) == diagnostic)            &
                    .or.                                           &
                    (elemI(:,ei_HeqType) == diagnostic)            &
                )                                                  &
                .and.                                              &
                (   (.not. elemYN(:,eYN_isElementDownstreamOfJB))  &
                    .and.                                          &
                    (.not. elemYN(:,eYN_isElementUpstreamOfJB))    &
                ) )

        if (npack > 0) then 
            elemP(1:npack,ptype) = pack( eIdx,                         &
                    (   (elemI(:,ei_QeqType) == diagnostic)            &
                        .or.                                           &
                        (elemI(:,ei_HeqType) == diagnostic)            &
                    )                                                  &
                    .and.                                              &
                    (   (.not. elemYN(:,eYN_isElementDownstreamOfJB))  &
                        .and.                                          &
                        (.not. elemYN(:,eYN_isElementUpstreamOfJB))    &
                    ) )
        end if        

    !% ep_Diag_JBadjacent
        !% --- elements that are diagnostic and ARE adjacent to JB
        ptype => col_elemP(ep_Diag_JBadjacent)
        npack => npack_elemP(ptype)

        npack = count ( &
                (                                            &
                    (elemI(:,ei_QeqType) == diagnostic)      &
                    .or.                                     &
                    (elemI(:,ei_HeqType) == diagnostic)      &
                )                                            &
                .and.                                        &
                (                                            &
                    (elemYN(:,eYN_isElementDownstreamOfJB))  &
                    .or.                                     &
                    (elemYN(:,eYN_isElementUpstreamOfJB))    &
                ))

        if (npack > 0) then 
            elemP(1:npack,ptype) = pack( eIdx,               &
                (                                            &
                    (elemI(:,ei_QeqType) == diagnostic)      &
                    .or.                                     &
                    (elemI(:,ei_HeqType) == diagnostic)      &
                 )                                           &
                .and.                                        &
                (                                            &
                    (elemYN(:,eYN_isElementDownstreamOfJB))  &
                    .or.                                     &
                    (elemYN(:,eYN_isElementUpstreamOfJB))    &
                ))
        end if     



    !% ep_JM
        !% - all elements that are JM
        ptype => col_elemP(ep_JM)
        npack => npack_elemP(ptype)

        npack = count( &
                (elemI(:,ei_elementType) == JM))
        if (npack > 0) then
            elemP(1:npack,ptype) = pack(eIdx, &
                (elemI(:,ei_elementType) == JM))
        end if

       !print *, elemI(elemP(1:npack,ep_JM),ei_Lidx)

   
    !% ep_JB_Downstream
        !% - all downstream JB elements
        ptype => col_elemP(ep_JB_Downstream)
        npack => npack_elemP(ptype)

        npack = count( &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_IsUpstream) .ne. oneI) &
                )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_IsUpstream) .ne. oneI) &
                )
        endif

    !% ep_JB_Upstream
        !% - all upstream JB elements
        ptype => col_elemP(ep_JB_Upstream)
        npack => npack_elemP(ptype)

        npack = count( &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_IsUpstream) == oneI) &
                )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_IsUpstream) == oneI) &
                )
        endif

    !% ep_JB_Diag_Adjacent 
        !% -- all JB elements that are adjacent to a Diagnostic element
        ptype => col_elemP(ep_JB_Diag_Adjacent)
        npack => npack_elemP(ptype)
        
        npack = count( &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemYN(:,eYN_is_DiagAdjacent))                     &
                 )

        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemYN(:,eYN_is_DiagAdjacent))                     &
                )
        end if

    !% ep_JB_CC_Adjacent 
        !% -- all JB elements that are adjacent to a CC element
        ptype => col_elemP(ep_JB_CC_Adjacent)
        npack => npack_elemP(ptype)
        
        npack = count( &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemYN(:,eYN_is_CCadjacent_JBorDiag))                       &
                 )

        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemYN(:,eYN_is_CCadjacent_JBorDiag))                     &
                )
        end if


    !% ep_JB_Upstream_CC_Adjacent 
        !% -- all JB upstream_branch elements that are adjacent to a CC element
        ptype => col_elemP(ep_JB_Upstream_CC_Adjacent)
        npack => npack_elemP(ptype)
        
        npack = count( &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemYN(:,eYN_is_CCadjacent_JBorDiag))              &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_IsUpstream) == oneI)   &
                 )

        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemYN(:,eYN_is_CCadjacent_JBorDiag))              &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_IsUpstream) == oneI)   &
                )
        end if

    !% ep_JB_Downstream_CC_Adjacent 
        !% -- all JB downpstream_branch elements that are adjacent to a CC element
        ptype => col_elemP(ep_JB_Downstream_CC_Adjacent)
        npack => npack_elemP(ptype)
        
        npack = count( &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemYN(:,eYN_is_CCadjacent_JBorDiag))              &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_IsUpstream) .ne. oneI) &
                 )

        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                (elemI(:,ei_elementType) == JB)                     &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI)       &
                .and.                                               &
                (elemYN(:,eYN_is_CCadjacent_JBorDiag))              &
                .and.                                               &
                (elemSI(:,esi_JunctionBranch_IsUpstream) .ne. oneI) &
                )
        end if

    !% ep_CC_DownstreamOfJunction
        !% - all CC element downstream of a JB
        ptype => col_elemP(ep_CC_DownstreamOfJunction)
        npack => npack_elemP(ptype)

        npack = count( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemYN(:,eYN_isElementDownstreamOfJB)) &
                )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                ( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemYN(:,eYN_isElementDownstreamOfJB)) &
                ))
        endif

    !% ep_CC_UpstreamOfJunction
        !% - all CC element upstream of a JB
        ptype => col_elemP(ep_CC_UpstreamOfJunction)
        npack => npack_elemP(ptype)

        npack = count( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemYN(:,eYN_isElementUpstreamOfJB)) &
                )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                ( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemYN(:,eYN_isElementUpstreamOfJB)) &
                ))
        endif





    !% ep_Diag_DownstreamOfJunction
        !% - all Diag element downstream of a JB
        ptype => col_elemP(ep_Diag_DownstreamOfJunction)
        npack => npack_elemP(ptype)

        npack = count( &
                (elemI(:,ei_QeqType) == diagnostic) &
                .and. &
                (elemYN(:,eYN_isElementDownstreamOfJB)) &
                )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                ( &
                (elemI(:,ei_QeqType) == diagnostic) &
                .and. &
                (elemYN(:,eYN_isElementDownstreamOfJB)) &
                ))
        endif

    !% ep_Diag_UpstreamOfJunction
        !% - all CC element upstream of a JB
        ptype => col_elemP(ep_Diag_UpstreamOfJunction)
        npack => npack_elemP(ptype)

        npack = count( &
                (elemI(:,ei_QeqType) == diagnostic) &
                .and. &
                (elemYN(:,eYN_isElementUpstreamOfJB)) &
                )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack( eIdx, &
                ( &
                (elemI(:,ei_QeqType) == diagnostic) &
                .and. &
                (elemYN(:,eYN_isElementUpstreamOfJB)) &
                ))
        endif

        ! print *, ' '
        ! do ii=1,size(elemYN,1)
        !     print *, ii, elemI(ii,ei_elementType), elemYN(ii,eYN_isElementUpstreamOfJB), eIdx(ii)

        ! ! end do
        ! do ii=1,npack 
        !     print *, ii, elemP(ii,ep_CC_UpstreamOfJunction)
        ! end do
        ! stop 6669873
    

    !% ep_CC_Open_Elements
        !% --- all the open channel time-marching elements
        ptype => col_elemP(ep_CC_Open_Elements)
        npack => npack_elemP(ptype)
        npack = count( &
                ( &
                    (elemI(:,ei_elementType) == CC) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_HeqType) == time_march) &
                    .or. &
                    (elemI(:,ei_QeqType) == time_march) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_geometryType) == rectangular) &
                    .or. &
                    (elemI(:,ei_geometryType) == trapezoidal) &
                    .or. &
                    (elemI(:,ei_geometryType) == triangular) &
                    .or. &
                    (elemI(:,ei_geometryType) == parabolic) &
                    .or. &
                    (elemI(:,ei_geometryType) == power_function) &
                    .or. &
                    (elemI(:,ei_geometryType) == rect_triang) &
                    .or. &
                    (elemI(:,ei_geometryType) == rect_round) &
                    .or. &
                    (elemI(:,ei_geometryType) == irregular) &
                ) &
            )
        if (npack > 0) then 
            elemP(1:npack, ptype) = pack(eIdx, &
                ( &
                    (elemI(:,ei_elementType) == CC) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_HeqType) == time_march) &
                    .or. &
                    (elemI(:,ei_QeqType) == time_march) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_geometryType) == rectangular) &
                    .or. &
                    (elemI(:,ei_geometryType) == trapezoidal) &
                    .or. &
                    (elemI(:,ei_geometryType) == triangular) &
                    .or. &
                    (elemI(:,ei_geometryType) == parabolic) &
                    .or. &
                    (elemI(:,ei_geometryType) == power_function) &
                    .or. &
                    (elemI(:,ei_geometryType) == rect_triang) &
                    .or. &
                    (elemI(:,ei_geometryType) == rect_round) &
                    .or. &
                    (elemI(:,ei_geometryType) == irregular) &
                ) &
            )
        end if

    !% ep_JB_Open_Elements
        !% --- all the open channel junction branch
        ptype => col_elemP(ep_JB_Open_Elements)
        npack => npack_elemP(ptype)
        npack = count( &
                ( &
                    (elemI(:,ei_elementType) == JB) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_geometryType) == rectangular) &
                    .or. &
                    (elemI(:,ei_geometryType) == trapezoidal) &
                    .or. &
                    (elemI(:,ei_geometryType) == triangular) &
                    .or. &
                    (elemI(:,ei_geometryType) == parabolic) &
                    .or. &
                    (elemI(:,ei_geometryType) == power_function) &
                    .or. &
                    (elemI(:,ei_geometryType) == rect_triang) &
                    .or. &
                    (elemI(:,ei_geometryType) == rect_round) &
                    .or. &
                    (elemI(:,ei_geometryType) == irregular) &
                ) &
            )
        if (npack > 0) then 
            elemP(1:npack, ptype) = pack(eIdx, &
                ( &
                    (elemI(:,ei_elementType) == JB) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_geometryType) == rectangular) &
                    .or. &
                    (elemI(:,ei_geometryType) == trapezoidal) &
                    .or. &
                    (elemI(:,ei_geometryType) == triangular) &
                    .or. &
                    (elemI(:,ei_geometryType) == parabolic) &
                    .or. &
                    (elemI(:,ei_geometryType) == power_function) &
                    .or. &
                    (elemI(:,ei_geometryType) == rect_triang) &
                    .or. &
                    (elemI(:,ei_geometryType) == rect_round) &
                    .or. &
                    (elemI(:,ei_geometryType) == irregular) &
                ) &
            )
        end if

    !% ep_CC_Closed_Elements
        !% - all the closed time-marching elements
        ptype => col_elemP(ep_CC_Closed_Elements)
        npack => npack_elemP(ptype)
        npack = count( &
                ( &
                    (elemI(:,ei_elementType) == CC) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_HeqType) == time_march) &
                    .or. &
                    (elemI(:,ei_QeqType) == time_march) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_geometryType) == circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == filled_circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == rectangular_closed) &
                    .or. &
                    (elemI(:,ei_geometryType) == horiz_ellipse) &
                    .or. &
                    (elemI(:,ei_geometryType) == arch) &
                    .or. &
                    (elemI(:,ei_geometryType) == eggshaped) &
                    .or. &
                    (elemI(:,ei_geometryType) == horseshoe) &
                    .or. &
                    (elemI(:,ei_geometryType) == gothic) &
                    .or. &
                    (elemI(:,ei_geometryType) == catenary) &
                    .or. &
                    (elemI(:,ei_geometryType) == semi_elliptical) &
                    .or. &
                    (elemI(:,ei_geometryType) == basket_handle) &
                    .or. &
                    (elemI(:,ei_geometryType) == semi_circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == custom) &
                   !% .or. &
                   !% (elemI(:,ei_geometryType) == force_main) & !% 20220905brh removed as force_main is not a geometry type
                ) )

        if (npack > 0) then
            elemP(1:npack, ptype) = pack(eIdx, &
                ( &
                    (elemI(:,ei_elementType) == CC) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_HeqType) == time_march) &
                    .or. &
                    (elemI(:,ei_QeqType) == time_march) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_geometryType) == circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == filled_circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == rectangular_closed) &
                    .or. &
                    (elemI(:,ei_geometryType) == horiz_ellipse) &
                    .or. &
                    (elemI(:,ei_geometryType) == arch) &
                    .or. &
                    (elemI(:,ei_geometryType) == eggshaped) &
                    .or. &
                    (elemI(:,ei_geometryType) == horseshoe) &
                    .or. &
                    (elemI(:,ei_geometryType) == gothic) &
                    .or. &
                    (elemI(:,ei_geometryType) == catenary) &
                    .or. &
                    (elemI(:,ei_geometryType) == semi_elliptical) &
                    .or. &
                    (elemI(:,ei_geometryType) == basket_handle) &
                    .or. &
                    (elemI(:,ei_geometryType) == semi_circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == custom) &
                   ! .or. &
                   ! (elemI(:,ei_geometryType) == force_main) & !!% 20220905brh removed as force_main is not a geometry type in SWMM5+
                ) )
        end if

    ! !% ep_JM_Closed_Elements
        ! !% - all the closed JM elements
        ! ptype => col_elemP(ep_JM_Closed_Elements)
        ! npack => npack_elemP(ptype)
        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ) &
        !         .and. &
        !         ( &
        !             elemYN(:,eYN_canSurcharge) &
        !         ) )

        ! if (npack > 0) then
        !     elemP(1:npack, ptype) = pack(eIdx, &
        !         ( &
        !             (elemI(:,ei_elementType) == JM) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_HeqType) == time_march) &
        !             .or. &
        !             (elemI(:,ei_QeqType) == time_march) &
        !         ) &
        !         .and. &
        !         ( &
        !             elemYN(:,eYN_canSurcharge) &
        !         ) )
        ! end if

        !print *, npack ,' here packed elements'
        !stop 498734

    !% ep_JB_Closed_Elements
        !% - all the closed time-marching elements
        ptype => col_elemP(ep_JB_Closed_Elements)
        npack => npack_elemP(ptype)
        npack = count( &
                ( &
                    (elemI(:,ei_elementType) == JB) &
                ) &
                .and. &
                ( &
                    (elemSI(:,esi_JunctionBranch_Exists) == oneI) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_geometryType) == circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == filled_circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == rectangular_closed) &
                    .or. &
                    (elemI(:,ei_geometryType) == horiz_ellipse) &
                    .or. &
                    (elemI(:,ei_geometryType) == arch) &
                    .or. &
                    (elemI(:,ei_geometryType) == eggshaped) &
                    .or. &
                    (elemI(:,ei_geometryType) == horseshoe) &
                    .or. &
                    (elemI(:,ei_geometryType) == gothic) &
                    .or. &
                    (elemI(:,ei_geometryType) == catenary) &
                    .or. &
                    (elemI(:,ei_geometryType) == semi_elliptical) &
                    .or. &
                    (elemI(:,ei_geometryType) == basket_handle) &
                    .or. &
                    (elemI(:,ei_geometryType) == semi_circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == custom) &
                    !.or. &
                    !(elemI(:,ei_geometryType) == force_main) & !% 20220905brh removed as force_main is not a geometry type
                ) )

        if (npack > 0) then
            elemP(1:npack, ptype) = pack(eIdx, &
                ( &
                    (elemI(:,ei_elementType) == JB) &
                ) &
                .and. &
                ( &
                    (elemSI(:,esi_JunctionBranch_Exists) == oneI) &
                ) &
                .and. &
                ( &
                    (elemI(:,ei_geometryType) == circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == filled_circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == rectangular_closed) &
                    .or. &
                    (elemI(:,ei_geometryType) == horiz_ellipse) &
                    .or. &
                    (elemI(:,ei_geometryType) == arch) &
                    .or. &
                    (elemI(:,ei_geometryType) == eggshaped) &
                    .or. &
                    (elemI(:,ei_geometryType) == horseshoe) &
                    .or. &
                    (elemI(:,ei_geometryType) == gothic) &
                    .or. &
                    (elemI(:,ei_geometryType) == catenary) &
                    .or. &
                    (elemI(:,ei_geometryType) == semi_elliptical) &
                    .or. &
                    (elemI(:,ei_geometryType) == basket_handle) &
                    .or. &
                    (elemI(:,ei_geometryType) == semi_circular) &
                    .or. &
                    (elemI(:,ei_geometryType) == custom) &
                    !.or. &
                    !(elemI(:,ei_geometryType) == force_main) & !% 20220905brh removed as force_main is not a geometry type
                ) )
        end if

    !% ep_FM_HW_all
        !% --- all force main (CC) elements that HW roughness method
        if (setting%Solver%ForceMain%AllowForceMainTF) then
            !% print *, 'ForceMain Hazen-Williams ALL elements
            
            ptype => col_elemP(ep_FM_HW_all)
            npack => npack_elemP(ptype)

            npack = count(                                            &
                    (elemI(:,ei_elementType) == CC)                   &
                    .and.                                             &
                    (elemYN(:,eYN_isForceMain))                       &
                    .and.                                             &
                    (elemSI(:,esi_Conduit_Forcemain_Method) == HazenWilliams) )

            if (npack > 0) then
                elemP(1:npack,ptype) = pack(eIdx,                     &
                    (elemI(:,ei_elementType) == CC)                   &
                    .and.                                             &
                    (elemYN(:,eYN_isForceMain))                       &
                    .and.                                             &
                    (elemSI(:,esi_Conduit_Forcemain_Method) == HazenWilliams) )
            end if
        end if

    !% ep_culvert_inlet
        ptype => col_elemP(ep_Culvert_Inlet)
        npack => npack_elemP(Ptype)
        if (setting%Culvert%UseCulvertsTF) then
            npack = count(                                          &
                (elemYN(:,eYN_isCulvert))                           &
                .and.                                               &
                (                                                   &
                    (elemSI(:,esi_Conduit_Culvert_Part)  == Culvert_Inlet) &
                    .or.                                            &
                    (elemSI(:,esi_Conduit_Culvert_Part) == Culvert_InOut)  &
                ) )

            if (npack > 0) then 
                elemP(1:npack,ptype) = pack(eIdx, &
                (elemYN(:,eYN_isCulvert))                         &
                    .and.                                               &
                    (                                                   &
                        (elemSI(:,esi_Conduit_Culvert_Part)  == Culvert_Inlet) &
                        .or.                                            &
                        (elemSI(:,esi_Conduit_Culvert_Part) == Culvert_InOut)  &
                    ) )
            end if
        else
            !% --- set the npack to zero
            npack = 0
        end if

    ! !% ep_culvert_outlet
        ! ptype => col_elemP(ep_culvert_outlet)
        ! npack => npack_elemP(Ptype)
        ! if (setting%Culvert%UseCulvertsTF) then
        !     npack = count(                                           &
        !         (elemYN(:,eYN_isCulvert))                          &
        !         .and.                                                &
        !         (                                                    &
        !             (elemSI(:,esi_Conduit_Culvert_Part)  == Culvert_Outlet) &
        !             .or.                                             &
        !             (elemSI(:,esi_Conduit_Culvert_Part) == Culvert_InOut)   &
        !         ) )
        !     if (npack > 0) then 
        !         elemP(1:npack,ptype) = pack(eIdx,                        &
        !             (elemYN(:,eYN_isCulvert))                          &
        !             .and.                                                &
        !             (                                                    &
        !                 (elemSI(:,esi_Conduit_Culvert_Part)  == Culvert_Outlet) &
        !                 .or.                                             &
        !                 (elemSI(:,esi_Conduit_Culvert_Part) == Culvert_InOut)   &
        !             ) )
        !     end if
        ! else
        !     !% --- set the npack to zero
        !     npack = 0
        ! end if

        ! !% ep_culvert_inout
        ! ptype => col_elemP(ep_culvert_inout)
        ! npack => npack_elemP(Ptype)
        ! if ( (setting%Culvert%UseCulvertsTF) .and. (N_culvert(this_image()) > 0) ) then
        !     npack = count( &
        !         (elemSI(:,esi_Culvert_inout)  == Culvert_InOut) &
        !         )
        !     if (npack > 0) then 
        !         elemP(1:npack,ptype) = pack(eIdx, &
        !         (elemSI(:,esi_Culvert_inout)  == Culvert_InOut) &
        !         )
        !     end if
        ! else
        !     !% --- set the npack to zero
        !     npack = 0
        ! end if 

        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_nongeometry_static_elements
!
!==========================================================================
!==========================================================================
!
    subroutine pack_nongeometry_dynamic_elements()
        !--------------------------------------------------------------------------
        !% packed arrays for non geometry dynamic elements
        !--------------------------------------------------------------------------
        integer          :: ii
        integer, pointer :: ptype, npack, fup, fdn, eIDx(:)
        character(64) :: subroutine_name = 'pack_nongeometry_dynamic_elements'
        !--------------------------------------------------------------------------
        !if (crashYN) return
        if (setting%Debug%File%pack_mask_arrays) &
            write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        eIdx => elemI(:,ei_Lidx)

        ! !% ep_AC ================================================
        ! !% - all elements that use AC
        ! ptype => col_elemP(ep_AC)
        ! npack => npack_elemP(ptype)
        ! npack = count( &
        !         (elemI(:,ei_tmType) == AC))
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (elemI(:,ei_tmType) == AC))
        ! end if

        ! !print *, 'CC_AC'
        ! !% ep_CC_AC ================================================
        ! !% - all channel conduit elements that use AC
        ! ptype => col_elemP(ep_CC_AC)
        ! npack => npack_elemP(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC)     )
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC)     )
        ! end if

        ! !print *, 'CC_ETM'
        ! !% ep_CC_ETM ================================================
        ! !% - all channel conduit elements that use ETM
        ! ptype => col_elemP(ep_CC_ETM)
        ! npack => npack_elemP(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM)     )

        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM)     )
        ! end if

        !print *, 'CC_H'
        !% ep_CC_H ================================================
        !% - all channel conduit elements that have head time march using ETM
        ptype => col_elemP(ep_CC_H)
        npack => npack_elemP(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemI(:,ei_HeqType) == time_march))
        if (npack > 0) then
            elemP(1:npack,ptype) = pack(eIdx,  &
               (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemI(:,ei_HeqType) == time_march))
        end if

        ! !print *, 'CC_Q_AC'
        ! !% ep_CC_Q_AC ================================================
        ! !% - all channel conduit elements that have flow time march using AC
        ! ptype => col_elemP(ep_CC_Q_AC)
        ! npack => npack_elemP(ptype)
        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         (elemI(:,ei_QeqType) == time_march) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC)     )
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !        (elemI(:,ei_elementType) == CC) &
        !         .and. &
        !         (elemI(:,ei_QeqType) == time_march) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC)     )
        ! end if

        !print *, 'CC_Q'
        !% ep_CC_Q ================================================
        !% - all channel conduit elements elements that have flow time march
        ptype => col_elemP(ep_CC_Q)
        npack => npack_elemP(ptype)
        npack = count( &
                (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemI(:,ei_QeqType) == time_march) )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack(eIdx,  &
               (elemI(:,ei_elementType) == CC) &
                .and. &
                (elemI(:,ei_QeqType) == time_march) )
        end if

        !print *, 'CCJB_AC'
        !% ep_CCJB_AC ================================================
        !% - all channel conduit or junction branch elements elements that are AC
        ! ptype => col_elemP(ep_CCJB_AC)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or.&
        !             (elemI(:,ei_elementType) == JB) &
        !         ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC)     )
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or.&
        !             (elemI(:,ei_elementType) == JB) &
        !         ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC)     )
        ! end if

        ! !print *, 'CC_AC_surcharged'
        ! !% ep_CC_ACsurcharged ================================================
        ! !% - all channel conduit elements elements that are AC and surcharged
        ! ptype => col_elemP(ep_CC_ACsurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (  &
        !             (elemI(:,ei_elementType) == CC) &
        !         ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC)        &
        !         .and. &
        !         (elemYN(:,eYN_isACsurcharged)))
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (  &
        !             (elemI(:,ei_elementType) == CC) &
        !         ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC)        &
        !         .and. &
        !         (elemYN(:,eYN_isACsurcharged)))
        ! end if

        ! !print *, 'CCJB_AC_surcharged'
        ! !% ep_CCJB_ACsurcharged ================================================
        ! !% - all channel conduit or junction branch elements elements that are AC and surcharged
        ! ptype => col_elemP(ep_CCJB_ACsurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (  &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or. &
        !             (elemI(:,ei_elementType) == JB) &
        !         ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC)        &
        !         .and. &
        !         (elemYN(:,eYN_isACsurcharged)))
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (  &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or. &
        !             (elemI(:,ei_elementType) == JB) &
        !         ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC)        &
        !         .and. &
        !         (elemYN(:,eYN_isACsurcharged)))
        ! end if

        ! !print *, 'CC_ALLtm_ACsurcharged'
        ! !% ep_CC_ALLtm_ACsurcharged ================================================
        ! !% - all channel conduit elements with any time march and surcharged
        ! ptype => col_elemP(ep_CC_ALLtm_ACsurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_tmType) == AC)        &
        !             .or. &
        !             (elemI(:,ei_tmType) == ETM)  &
        !         ) &
        !         .and. &
        !         (elemYN(:,eYN_isACsurcharged)))
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_tmType) == AC)        &
        !             .or. &
        !             (elemI(:,ei_tmType) == ETM)  &
        !         ) &
        !         .and. &
        !         (elemYN(:,eYN_isACsurcharged)))
        ! end if

        ! print *, ' '
        ! print *, 'in ',trim(subroutine_name), ' ',ptype
        ! print *, 'thisP '
        ! print *, elemP(1:npack,ptype)
        ! print *, ' '
        ! print *, 'is_surcharged'
        ! print *, elemYN(elemP(1:npack,ptype),eYN_isACsurcharged)
        ! print *, ' '

        !print *, 'CCJB_ALLtm_ACsurcharged'
        !% ep_CCJB_ALLtm_ACsurcharged ================================================
        !% - all channel conduit or junction branch elements with any time march and surcharged
        ! ptype => col_elemP(ep_CCJB_ALLtm_ACsurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or. &
        !             (elemI(:,ei_elementType) == JB) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_tmType) == AC)        &
        !             .or. &
        !             (elemI(:,ei_tmType) == ETM)  &
        !         ) &
        !         .and. &
        !         (elemYN(:,eYN_isACsurcharged)))
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or. &
        !             (elemI(:,ei_elementType) == JB) &
        !         ) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_tmType) == AC)        &
        !             .or. &
        !             (elemI(:,ei_tmType) == ETM)  &
        !         ) &
        !         .and. &
        !         (elemYN(:,eYN_isACsurcharged)))
        ! end if

        ! !% ep_CCJB_eETM_i_fAC ================================================
        ! !% conduits, channels, and junction branches that are ETM and have
        ! !% an adjacent face that is AC
        ! ptype => col_elemP(ep_CCJB_eETM_i_fAC)
        ! npack => npack_elemP(ptype)

        ! !% HACK: due to elements having u/s or d/s null faces, the code below
        ! !% is written in do loop untill other fix is figured out

        ! npack = zeroI
        ! do ii = 1,N_elem(this_image())
        !     fup => elemI(ii,ei_Mface_uL)
        !     fdn => elemI(ii,ei_Mface_dL)
        !     if ((fup /= nullvalueI) .and. (fdn /= nullValueI)) then
        !         if (((elemI(ii,ei_elementType) == CC) .or. (elemI(ii,ei_elementType) == JB)) &
        !             .and. &
        !             (elemI(ii,ei_tmType) == ETM) &
        !             .and. &
        !             ((faceYN(fup,fYN_isAC_adjacent)) .or. (faceYN(fdn,fYN_isAC_adjacent)))) then
                    
        !             npack = npack + oneI
        !             elemP(npack,ptype) = ii
        !         end if
        !     end if
        ! end do

        !% ep_CCJB_ETM ================================================
        !% - all channel conduit or junction branch that are ETM
        ! ptype => col_elemP(ep_CCJB_ETM)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or. &
        !             (elemI(:,ei_elementType) == JB)  &
        !          ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM) &
        !         )
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx, &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or. &
        !             (elemI(:,ei_elementType) == JB)  &
        !          ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM) &
        !         )
        ! end if

        !print *, 'CC_ETM_PSsurcharged'
        !% ep_CC_ETM_PSsurcharged ================================================
        !% - all channel conduit or junction branch that are ETM and PS surcharged
        ! ptype => col_elemP(ep_CC_ETM_PSsurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !          ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM) &
        !         .and. &
        !         (elemYN(:,eYN_isPSsurcharged)) &
        !         )
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx, &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !          ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM) &
        !         .and. &
        !         (elemYN(:,eYN_isPSsurcharged)) &
        !         )
        ! end if

        !print *, 'CCJB_ETM_surcharged'
        !% ep_CCJB_ETM_PSsurcharged ================================================
        !% - all channel conduit or junction branch that are ETM and surcharged
        ! ptype => col_elemP(ep_CCJB_ETM_PSsurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or. &
        !             (elemI(:,ei_elementType) == JB)  &
        !          ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM) &
        !         .and. &
        !         (elemYN(:,eYN_isPSsurcharged)) &
        !         )
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx, &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or. &
        !             (elemI(:,ei_elementType) == JB)  &
        !          ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM) &
        !         .and. &
        !         (elemYN(:,eYN_isPSsurcharged)) &
        !         )
        ! end if

        !print *, 'CCJM_H_AC_open'
        !% ep_CCJM_H_AC_open ================================================
        !% - all channel conduit or junction main elements solving head with AC and are non-surcharged
        ! ptype => col_elemP(ep_CCJM_H_AC_open)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or. &
        !             (elemI(:,ei_elementType) == JM)  &
        !          ) &
        !         .and. &
        !         (elemI(:,ei_HeqType) == time_march) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isACsurcharged)) &
        !         )
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx, &
        !         ( &
        !             (elemI(:,ei_elementType) == CC) &
        !             .or. &
        !             (elemI(:,ei_elementType) == JM)  &
        !          ) &
        !         .and. &
        !         (elemI(:,ei_HeqType) == time_march) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isACsurcharged)) &
        !         )
        ! end if

        !print *, 'CCJM_H'
        !% ep_CCJM_H ================================================
        !% - all channel conduit or junction main that use head solution with ETM
        ptype => col_elemP(ep_CCJM_H)
        npack => npack_elemP(ptype)

        npack = count( &
                ( &
                    (elemI(:,ei_elementType) == CC) &
                    .or. &
                    (elemI(:,ei_elementType) == JM)  &
                 ) &
                .and. &
                (elemI(:,ei_HeqType) == time_march) &
                )
        if (npack > 0) then
            elemP(1:npack,ptype) = pack(eIdx, &
                ( &
                    (elemI(:,ei_elementType) == CC) &
                    .or. &
                    (elemI(:,ei_elementType) == JM)  &
                 ) &
                .and. &
                (elemI(:,ei_HeqType) == time_march) &
                )
        end if

        ! !print *, 'ETM'
        ! !% ep_ETM ================================================
        ! !% - all elements that use ETM
        ! ptype => col_elemP(ep_ETM)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (elemI(:,ei_tmType) == ETM))
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx, &
        !         (elemI(:,ei_tmType) == ETM))
        ! end if

        ! !print *, 'JM_AC'
        ! !% ep_JM_AC ================================================
        ! !% - all elements that are junction mains and use AC
        ! ptype => col_elemP(ep_JM_AC)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (elemI(:,ei_elementType) == JM ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC))
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (elemI(:,ei_elementType) == JM ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC))
        ! end if

        !print *, 'JB_AC'
        !% ep_JB_AC ================================================
        !% - all elements that are junction mains and use AC
        ! ptype => col_elemP(ep_JB_AC)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (elemI(:,ei_elementType) == JB ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC))
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (elemI(:,ei_elementType) == JB ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC))
        ! end if

        !print *, 'JM_ETM'
        !% ep_JM_ETM ================================================
        !% - all elements that are junction mains and ETM
        ! ptype => col_elemP(ep_JM_ETM)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (elemI(:,ei_elementType) == JM ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM))

        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (elemI(:,ei_elementType) == JM ) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM))
        ! end if

        !print *, 'JB'
    !% ep_JB ================================================
        !% - all elements that are junction branches
        ptype => col_elemP(ep_JB)
        npack => npack_elemP(ptype)

        npack = count( &
                (elemI(:,ei_elementType) == JB ) &
                .and. &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI))

        if (npack > 0) then
            elemP(1:npack,ptype) = pack(eIdx,  &
                (elemI(:,ei_elementType) == JB ) &
                .and. &
                (elemSI(:,esi_JunctionBranch_Exists) == oneI))
        end if

        !print *, 'NonSurcharged_AC'
        !% ep_AC_ACnonSurcharged ================================================
        !% - all AC elements that are not surcharged
        ! ptype => col_elemP(ep_AC_ACnonSurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (.not. elemYN(:,eYN_isACsurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC))
        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (.not. elemYN(:,eYN_isACsurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC))
        ! end if

        !print *,'NonSurcharged_ALLtm'
        !% ep_ALLtm_NonSurcharged ================================================
        !% -- elements with any time march that are not surcharged
        ! ptype => col_elemP(ep_ALLtm_NonSurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (.not. elemYN(:,eYN_isACsurcharged)) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isPSsurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_tmType) == AC) &
        !             .or.&
        !             (elemI(:,ei_tmType) == ETM) &
        !         ))

        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (.not. elemYN(:,eYN_isACsurcharged)) &
        !         .and. &
        !         (.not. elemYN(:,eYN_isPSsurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_tmType) == AC) &
        !             .or.&
        !             (elemI(:,ei_tmType) == ETM) &
        !         ))
        ! end if

        !print *, 'NonSurcharged_ETM'
        !% ep_ETM_PSnonSurcharged ================================================
        !% -- elements with ETM time march that are not surcharged 
        ! ptype => col_elemP(ep_ETM_PSnonSurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (.not. elemYN(:,eYN_isPSsurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM))

        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (.not. elemYN(:,eYN_isPSsurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM))
        ! end if

       

        !print *,'Surcharged_AC'
        !% ep_ACsurcharged ================================================
        !% - all AC elements that are surcharged
        ! ptype => col_elemP(ep_ACsurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (elemYN(:,eYN_isACsurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC))

        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (elemYN(:,eYN_isACsurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == AC))
        ! end if

        !print *, 'Surcharged_ALLtm'
        !% ep_ALLtmSurcharged ================================================
        !% - all elements of any time march that are surcharged
        ! ptype => col_elemP(ep_ALLtmSurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (elemYN(:,eYN_isACsurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_tmType) == AC) &
        !             .or. &
        !             (elemI(:,ei_tmType) == ETM) &
        !         ))

        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (elemYN(:,eYN_isACsurcharged)) &
        !         .and. &
        !         ( &
        !             (elemI(:,ei_tmType) == AC) &
        !             .or. &
        !             (elemI(:,ei_tmType) == ETM) &
        !         ))
        ! end if

        !print *, 'Surcharged_ETM'
        !% ep_PSsurcharged ================================================
        !% - all ETM elements that are surcharged
        ! ptype => col_elemP(ep_PSsurcharged)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (elemYN(:,eYN_isPSsurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM))

        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx,  &
        !         (elemYN(:,eYN_isPSsurcharged)) &
        !         .and. &
        !         (elemI(:,ei_tmType) == ETM))
        ! end if

        ! !print *, 'CC closed elements'
        ! !% ep_CC_isClosedSetting =====================================================
        ! !% --- all CC elements that are closed by elemR(:,er_Setting) = 0.0
        ! ptype => col_elemP(ep_CC_isClosedSetting)
        ! npack => npack_elemP(ptype)

        ! npack = count( &
        !         (elemI(:,ei_elementType) == CC ) &
        !         .and. &
        !         (elemR(:,er_Setting) == zeroR ) )

        ! if (npack > 0) then
        !     elemP(1:npack,ptype) = pack(eIdx, &
        !         (elemI(:,ei_elementType) == CC ) &
        !         .and. &
        !         (elemR(:,er_Setting) == zeroR ) )        
        ! end if

        if (setting%Solver%ForceMain%AllowForceMainTF) then
            !% print *, 'ForceMain Hazen-Williams Preissmann Slot Surcharged elements
            !% ep_FM_HW_PSsurcharged
            !% --- all force main (CC) elements that are full pipe and HW roughness method
            ptype => col_elemP(ep_FM_HW_PSsurcharged)
            npack => npack_elemP(ptype)

            npack = count(                                            &
                    (elemYN(:,eYN_isForceMain))                       &
                    .and.                                             &
                    (elemSI(:,esi_Conduit_Forcemain_Method) == HazenWilliams) &
                    .and.                                             &
                    (elemR(:,er_SlotVolume) > zeroR) )

            if (npack > 0) then
                elemP(1:npack,ptype) = pack(eIdx,                     &
                    (elemYN(:,eYN_isForceMain))                       &
                    .and.                                             &
                    (elemSI(:,esi_Conduit_Forcemain_Method) == HazenWilliams) &
                    .and.                                             &
                    (elemR(:,er_SlotVolume) > zeroR)  )
            end if

            !% --- the unsubmerged HW should not be needed.
            ! !% print *, 'ForceMain Hazen-Williams Preissmann Slot open-channel (unsubmerged) elements
            ! !% ep_FM_HW_PS_NonSurcharged
            ! !% --- all force main (CC) elements that are full pipe and HW roughness method
            ! ptype => col_elemP(ep_FM_HW_PS_NonSurcharged)
            ! npack => npack_elemP(ptype)

            ! npack = count(                                             &
            !         (elemYN(:,eYN_isForceMain))                        &
            !         .and.                                              &
            !         (elemSI(:,esi_Conduit_Forcemain_Method) == HazenWilliams)  &
            !         .and.                                              &
            !         (elemR(:,er_SlotVolume) .eq. zeroR) )

            ! if (npack > 0) then
            !     elemP(1:npack,ptype) = pack(eIdx,                      &
            !         (elemYN(:,eYN_isForceMain))                        &
            !         .and.                                              &
            !         (elemSI(:,esi_Conduit_Forcemain_Method) == HazenWilliams)  &
            !         .and.                                              &
            !         (elemR(:,er_SlotVolume) .eq. zeroR)  )
            ! end if

            !% print *, 'ForceMain Darcy-Weisbach Preissmann Slot Surcharged elements
            !% ep_FM_dw_PSsurcharged
            !% --- all force main (CC) elements that are full pipe and DW roughness method
            ptype => col_elemP(ep_FM_dw_PSsurcharged)
            npack => npack_elemP(ptype)

            npack = count(                                             &
                    (elemYN(:,eYN_isForceMain))                        &
                    .and.                                              &
                    (elemSI(:,esi_Conduit_Forcemain_Method) == DarcyWeisbach)  &
                    .and.                                              &
                    (elemR(:,er_SlotVolume) > zeroR) )

            if (npack > 0) then
                elemP(1:npack,ptype) = pack(eIdx,                      &
                    (elemYN(:,eYN_isForceMain))                        &
                    .and.                                              &
                    (elemSI(:,esi_Conduit_Forcemain_Method) == DarcyWeisbach)  &
                    .and.                                              &
                    (elemR(:,er_SlotVolume) > zeroR)  )
            end if

            !% print *, 'ForceMain Darcy-Weisbach Preissmann Slot open-channel (unsubmerged) elements
            !% ep_FM_dw_PSnonSurcharged
            !% --- all force main (CC) elements that are full pipe using DW roughness method
            ptype => col_elemP(ep_FM_dw_PSnonSurcharged)
            npack => npack_elemP(ptype)

            npack = count(                                                &
                    (elemYN(:,eYN_isForceMain))                           &
                    .and.                                                 &
                    (elemSI(:,esi_Conduit_Forcemain_Method) == DarcyWeisbach)     &
                    .and.                                                 &
                    (elemR(:,er_SlotVolume) .eq. zeroR) )

            if (npack > 0) then
                elemP(1:npack,ptype) = pack(eIdx,                         &
                    (elemYN(:,eYN_isForceMain))                           &
                    .and.                                                 &
                    (elemSI(:,esi_Conduit_Forcemain_Method) == DarcyWeisbach)     &
                    .and.                                                 &
                    (elemR(:,er_SlotVolume) .eq. zeroR)  )
            end if
        end if

        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_nongeometry_dynamic_elements
!%
!%==========================================================================
!%==========================================================================
!%
    subroutine pack_small_or_zero_depth_elements (eType, isZeroDepth)
        !%-----------------------------------------------------------------
        !% dynamic packing of elements with small and zero depths
        !%-----------------------------------------------------------------
        integer, intent(in)  :: eType
        logical, intent(in)  :: isZeroDepth
        integer, pointer :: ptype, npack, eIdx(:)
        !%-----------------------------------------------------------------
        !%-----------------------------------------------------------------
        
        eIdx => elemI(:,ei_Lidx)

        select case (eType)
            case (CC)
                if (.not. isZeroDepth) then 
                    !% ep_SmallDepth_CC ====================================
                    !% - all Small depth that are CC 
                    ptype => col_elemP(ep_SmallDepth_CC)
                    npack => npack_elemP(ptype)
                    if (setting%SmallDepth%useMomentumCutoffYN) then
                        npack = count( &
                                (elemYN(:,eYN_isSmallDepth)) &
                                .and. &
                                (elemI(:,ei_elementType) == CC))

                        if (npack > 0) then
                            elemP(1:npack,ptype) = pack(eIdx,  &
                                (elemYN(:,eYN_isSmallDepth)) &
                                .and. &
                                (elemI(:,ei_elementType) == CC) )
                        end if
                    else 
                        npack = zeroI
                    end if
                end if

                if (isZeroDepth) then 
                    !% ep_ZeroDepth_CC ====================================
                    !% - all zero depth that are CC
                    ptype => col_elemP(ep_ZeroDepth_CC)
                    npack => npack_elemP(ptype)

                    npack = count( &
                            (elemYN(:,eYN_isZeroDepth)) &
                            .and. &
                            (elemI(:,ei_elementType) == CC) )

                    if (npack > 0) then
                        elemP(1:npack,ptype) = pack(eIdx,  &
                            (elemYN(:,eYN_isZeroDepth)) &
                            .and. &
                            (elemI(:,ei_elementType) == CC) )
                    end if
                end if
           
            case (JM)
                if (.not. isZeroDepth) then
                    !% BeginNew 20220122brh
                    !% ep_SmallDepth_JM_ ====================================
                    !% - all Small depth that are JM 
                    ptype => col_elemP(ep_SmallDepth_JM)
                    npack => npack_elemP(ptype)

                    if (setting%SmallDepth%useMomentumCutoffYN) then
                        npack = count( &
                                (elemYN(:,eYN_isSmallDepth)) &
                                .and. &
                                (elemI(:,ei_elementType) == JM))

                        if (npack > 0) then
                            elemP(1:npack,ptype) = pack(eIdx,  &
                                (elemYN(:,eYN_isSmallDepth)) &
                                .and. &
                                (elemI(:,ei_elementType) == JM))
                        end if
                    else 
                        npack = zeroI
                    end if
                end if

                if (isZeroDepth) then
                    !% ep_ZeroDepth_JM_ETM ====================================
                    !% - all Zero depth that are JM 
                    ptype => col_elemP(ep_ZeroDepth_JM)
                    npack => npack_elemP(ptype)

                    npack = count( &
                            (elemYN(:,eYN_isZeroDepth)) &
                            .and. &
                            (elemI(:,ei_elementType) == JM))

                    if (npack > 0) then
                        elemP(1:npack,ptype) = pack(eIdx,  &
                            (elemYN(:,eYN_isZeroDepth)) &
                            .and. &
                            (elemI(:,ei_elementType) == JM) )
                    end if
                end if

            case (JB)
                ! !% ep_SmallDepth_JB_ETM ====================================
                ! !% - all Small depth that are JB and ETM time march
                ! ptype => col_elemP(ep_SmallDepth_JB_ETM)
                ! npack => npack_elemP(ptype)

                ! if (setting%SmallDepth%useMomentumCutoffYN) then
                !     npack = count( &
                !             (elemYN(:,eYN_isSmallDepth)) &
                !             .and. &
                !             (elemI(:,ei_elementType) == JB) &
                !             .and. &
                !             (elemI(:,ei_tmType) == ETM) )

                !     if (npack > 0) then
                !         elemP(1:npack,ptype) = pack(eIdx,  &
                !             (elemYN(:,eYN_isSmallDepth)) &
                !             .and. &
                !             (elemI(:,ei_elementType) == JB) &
                !             .and. &
                !             (elemI(:,ei_tmType) == ETM))
                !     end if
                ! else 
                !     npack = zeroI
                ! end if

                if (isZeroDepth) then
                    !% ep_ZeroDepth_JB ====================================
                    !% - all Zero depth that are JB
                    ptype => col_elemP(ep_ZeroDepth_JB)
                    npack => npack_elemP(ptype)

                    npack = count( &
                            (elemYN(:,eYN_isZeroDepth)) &
                            .and. &
                            (elemI(:,ei_elementType) == JB))

                    if (npack > 0) then
                        elemP(1:npack,ptype) = pack(eIdx,  &
                            (elemYN(:,eYN_isZeroDepth)) &
                            .and. &
                            (elemI(:,ei_elementType) == JB) )
                    end if
                end if
                
            case default 
                print *, 'unexpected case default'
                call util_crashpoint(5598723)
        end select

        if (.not. isZeroDepth) then
            !print *, 'CC_NOTsmalldepth'
            !% ep_CC_NOTsmalldepth  ====================================
            !% Flow solution that are NOT small volume or zero depth
            !% -- needed to limit where CFL is computed and volume conservation
            ptype => col_elemP(ep_CC_NOTsmalldepth)
            npack => npack_elemP(ptype)
            if (setting%SmallDepth%useMomentumCutoffYN) then 
                npack = count( &
                        (elemI(:,ei_elementType) == CC) &
                        .and. &
                        (elemI(:,ei_QeqType) == time_march) &
                        .and. &
                        (.not. elemYN(:,eYN_isSmallDepth)) &
                        .and. &
                        (.not. elemYN(:,eYN_isZeroDepth))     )
                if (npack > 0) then
                    elemP(1:npack,ptype) = pack(eIdx,  &
                        (elemI(:,ei_elementType) == CC) &
                        .and. &
                        (elemI(:,ei_QeqType) == time_march) &
                        .and. &
                        (.not. elemYN(:,eYN_isSmallDepth))   &
                        .and. &
                        (.not. elemYN(:,eYN_isZeroDepth))     )
                end if
            else 
                npack = zeroI
            end if
        end if

        if (isZeroDepth) then
            !print *, 'CC_NOTzerodepth'
            !% ep_CC_NOTzerodepth  ====================================
            !% Flow solution that are NOT zero depth
            !% -- needed for seepage computations
            ptype => col_elemP(ep_CC_NOTzerodepth)
            npack => npack_elemP(ptype)
            npack = count( &
                    (elemI(:,ei_elementType) == CC) &
                    .and. &
                    (.not. elemYN(:,eYN_isZeroDepth))     )
            if (npack > 0) then
                elemP(1:npack,ptype) = pack(eIdx,  &
                    (elemI(:,ei_elementType) == CC) &
                    .and. &
                    (.not. elemYN(:,eYN_isZeroDepth))     )
            end if


            
        end if


        !print *, 'JBJM_NOTsmalldepth'
        !% ep_JBJM_NOTsmalldepth  ====================================
        !% Flow solution that are NOT small volume or zero depth
        !% -- needed to limit where CFL is computed
        ! ptype => col_elemP(ep_JBJM_NOTsmalldepth)
        ! npack => npack_elemP(ptype)
        ! if (setting%SmallDepth%useMomentumCutoffYN) then 
        !     npack = count( &
        !             (      &
        !                 ( elemI(:,ei_elementType) == JM) &
        !             .or. ((elemI(:,ei_elementType) == JB) .and. (elemSI(:,esi_JunctionBranch_Exists) == oneI) ) &   
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSmallDepth)) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isZeroDepth))     )
        !     if (npack > 0) then
        !         elemP(1:npack,ptype) = pack(eIdx,  &
        !             (      &
        !                 ( elemI(:,ei_elementType) == JM) &
        !             .or. ((elemI(:,ei_elementType) == JB) .and. (elemSI(:,esi_JunctionBranch_Exists) == oneI) ) &   
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSmallDepth)) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isZeroDepth))     ) 
        !     end if
        ! else 
        !     npack = zeroI
        ! end if

        !print *, 'CCJBJM_NOTsmalldepth'
        !% ep_CCJBJM_NOTsmalldepth  ====================================
        !% Flow solution that are NOT small volume or zero depth
        !% -- needed to limit where CFL is computed
        ! ptype => col_elemP(ep_CCJBJM_NOTsmalldepth)
        ! npack => npack_elemP(ptype)
        ! if (setting%SmallDepth%useMomentumCutoffYN) then 
        !     npack = count( &
        !             (      &
        !                 ( elemI(:,ei_elementType) == CC) &
        !             .or. ( elemI(:,ei_elementType) == JM) &
        !             .or. ((elemI(:,ei_elementType) == JB) .and. (elemSI(:,esi_JunctionBranch_Exists) == oneI) ) &   
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSmallDepth)) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isZeroDepth))     )
        !     ! print *, ' '
        !     ! print *, ' in pack_mask_arrays checking CCJBJM_NOTsmalldepth'
        !     ! print *, 'npack ',npack        
        !     if (npack > 0) then
        !         elemP(1:npack,ptype) = pack(eIdx,  &
        !             (      &
        !                 ( elemI(:,ei_elementType) == CC) &
        !             .or. ( elemI(:,ei_elementType) == JM) &
        !             .or. ((elemI(:,ei_elementType) == JB) .and. (elemSI(:,esi_JunctionBranch_Exists) == oneI) ) &   
        !             ) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isSmallDepth)) &
        !             .and. &
        !             (.not. elemYN(:,eYN_isZeroDepth))     ) 
        !     end if
        ! else 
        !     npack = zeroI
        ! end if

        if (.not. isZeroDepth) then
            !print *, 'CCJM_NOTsmalldepth'
            !% ep_CCJM_NOTsmalldepth  ====================================
            !% Flow solution that are NOT small volume or zero depth
            !% -- alternate needed to limit where CFL is computed
            ptype => col_elemP(ep_CCJM_NOTsmalldepth)
            npack => npack_elemP(ptype)
            if (setting%SmallDepth%useMomentumCutoffYN) then 
                npack = count( &
                        (      &
                            ( elemI(:,ei_elementType) == CC) &
                        .or. ( elemI(:,ei_elementType) == JM) &   
                        ) &
                        .and. &
                        (.not. elemYN(:,eYN_isSmallDepth)) &
                        .and. &
                        (.not. elemYN(:,eYN_isZeroDepth))     )
                ! print *, ' '
                ! print *, ' in pack_mask_arrays checking CCJM_NOTsmalldepth'
                ! print *, 'npack ',npack        
                if (npack > 0) then
                    elemP(1:npack,ptype) = pack(eIdx,  &
                        (      &
                            ( elemI(:,ei_elementType) == CC) &
                        .or. ( elemI(:,ei_elementType) == JM) &   
                        ) &
                        .and. &
                        (.not. elemYN(:,eYN_isSmallDepth)) &
                        .and. &
                        (.not. elemYN(:,eYN_isZeroDepth))     ) 
                end if
            else
                npack = zeroI 
            end if
        end if


        if (isZeroDepth) then
            ptype => col_elemP(ep_CCJM_NOTzerodepth)
            npack => npack_elemP(ptype)
            npack = count( &
                    (      &
                         ( elemI(:,ei_elementType) == CC) &
                    .or. ( elemI(:,ei_elementType) == JM) &   
                    ) &
                    .and. &
                    (.not. elemYN(:,eYN_isZeroDepth))     )     
            if (npack > 0) then
                elemP(1:npack,ptype) = pack(eIdx,  &
                    (      &
                         ( elemI(:,ei_elementType) == CC) &
                    .or. ( elemI(:,ei_elementType) == JM) &   
                    ) &
                    .and. &
                    (.not. elemYN(:,eYN_isZeroDepth))     ) 
            end if
        end if


    end subroutine pack_small_or_zero_depth_elements

!%
!%==========================================================================
!%==========================================================================
!%
    subroutine pack_CC_zeroDepth_interior_faces ()
        !%------------------------------------------------------------------
        !% Description
        !% Dynamic pack for faces that have zero depth elements on one or
        !% both sides.

        !%  OBSOLETE fi_zerodepth
        !% This also sets values for the faceI(:,fi_zeroDepth) array to
        !% -1 or +1 for upstream or downstream value
        !% note the default of faceI(:,fi_zeroDepth) = 0.0 must be
        !% set before this procedure is called
        !%------------------------------------------------------------------
        !% Declarations
            integer, pointer :: ptype, npack 
            integer, pointer :: eUp(:), eDn(:),  fCC(:)
            integer :: ii
        !%------------------------------------------------------------------
        !% Aliases:
            !% --- all the interior faces with CC on both sides
            fCC      => faceP(1:npack_faceP(fp_CC_both_IorS),fp_CC_both_IorS)
            !% --- upstream elements
            eUp      => faceI(:,fi_Melem_uL)
            !% --- downstream elements
            eDn      => faceI(:,fi_Melem_dL)
        !%------------------------------------------------------------------

        !%===================
        !% ---- fp_CC_upstream_is_zero_IorS (CC on both sides)
            ptype => col_faceP(fp_CC_upstream_is_zero_IorS)
            npack => npack_faceP(ptype)
            npack = count(                                                &
                                   elemYN(eUp(fCC),eYN_isZeroDepth)       &
                            .and.                                         &
                            (.not. elemYN(eDn(fCC),eYN_isZeroDepth))      &
                        ) 
            if (npack > 0) then 
                faceP(1:npack,ptype) = pack(fCC ,                         &
                                elemYN(eUp(fCC),eYN_isZeroDepth)       &
                            .and.                                          &
                            (.not. elemYN(eDn(fCC),eYN_isZeroDepth))      &
                        )
                !% -1 indicates zerodepth upstream of face        
               ! faceI(faceP(1:npack,ptype),fi_zeroDepth) = -oneI        
            end if

        !%=========================
        !% ---- fp_CC_downstream_is_zero_IorS (CC on both sides)
            ptype => col_faceP(fp_CC_downstream_is_zero_IorS)
            npack => npack_faceP(ptype)
            npack = count(                                                 &
                                elemYN(eDn(fCC),eYN_isZeroDepth)       &
                            .and.                                          &
                            (.not. elemYN(eUp(fCC),eYN_isZeroDepth))      &
                        ) 
            if (npack > 0) then 
                faceP(1:npack,ptype) = pack(fCC ,                         &
                                elemYN(eDn(fCC),eYN_isZeroDepth)       &
                            .and.                                          &
                            (.not. elemYN(eUp(fCC),eYN_isZeroDepth))      &
                        )

                !% +1 indicates zerodepth downstream of face
               ! faceI(faceP(1:npack,ptype),fi_zeroDepth) = oneI       
            end if  

        !%================
        !% ---- fp_CC_bothsides_are_zero_IorS (CC on both sides)
            ptype => col_faceP(fp_CC_bothsides_are_zero_IorS)
            npack => npack_faceP(ptype)
            npack = count(                                                 &
                                elemYN(eDn(fCC),eYN_isZeroDepth)       &
                            .and.                                          &
                                elemYN(eUp(fCC),eYN_isZeroDepth)       &
                        ) 
            if (npack > 0) then 
                faceP(1:npack,ptype) = pack(fCC ,                         &
                                elemYN(eDn(fCC),eYN_isZeroDepth)       &
                            .and.                                          &
                                elemYN(eUp(fCC),eYN_isZeroDepth)       &
                        )
                !% +2 indicates zerodepth both upstream and downstream        
               ! faceI(faceP(1:npack,ptype),fi_zeroDepth) = twoI        
            end if  

    end subroutine pack_CC_zeroDepth_interior_faces
!%
!%==========================================================================
!%==========================================================================
!%      
    subroutine pack_JB_zeroDepth_interior_faces ()
        !%------------------------------------------------------------------
        !% Description
        !% Dynamic pack for JB-adjacent faces that have zero depth elements 
        !% on one or both sides

        !% OBSOLETE fi_zeroDepth
        !% This also sets values for the faceI(:,fi_zeroDepth) array to
        !% -1 or +1 for upstream or downstream value
        !% note the default of faceI(:,fi_zeroDepth) = 0.0 must be
        !% set before this procedure is called
        !%------------------------------------------------------------------
        !% Declarations
            integer, pointer :: ptype, npack 
            integer, pointer :: eUp(:), eDn(:),  fJB(:)
            integer :: ii
        !%------------------------------------------------------------------
        !% Aliases:
            !% --- all the interior faces with JBCC
            fJB      => faceP(1:npack_faceP(fp_JB_IorS),fp_JB_IorS)
            !% --- upstream elements
            eUp      => faceI(:,fi_Melem_uL)
            !% --- downstream elements
            eDn      => faceI(:,fi_Melem_dL)
        !%------------------------------------------------------------------

        !%===================
        !% ---- fp_JB_upstream_is_zero_IorS
            ptype => col_faceP(fp_JB_upstream_is_zero_IorS)
            npack => npack_faceP(ptype)
            npack = count(                                                &
                                   elemYN(eUp(fJB),eYN_isZeroDepth)       &
                            .and.                                         &
                            (.not. elemYN(eDn(fJB),eYN_isZeroDepth))      &
                        ) 
            if (npack > 0) then 
                faceP(1:npack,ptype) = pack(fJB ,                         &
                                elemYN(eUp(fJB),eYN_isZeroDepth)       &
                            .and.                                          &
                            (.not. elemYN(eDn(fJB),eYN_isZeroDepth))      &
                        )
                !% -1 indicates zerodepth upstream of face        
               ! faceI(faceP(1:npack,ptype),fi_zeroDepth) = -oneI        
            end if

        !%=========================
        !% ---- fp_JB_downstream_is_zero_IorS 
            ptype => col_faceP(fp_JB_downstream_is_zero_IorS)
            npack => npack_faceP(ptype)
            npack = count(                                                 &
                                elemYN(eDn(fJB),eYN_isZeroDepth)       &
                            .and.                                          &
                            (.not. elemYN(eUp(fJB),eYN_isZeroDepth))      &
                        ) 
            if (npack > 0) then 
                faceP(1:npack,ptype) = pack(fJB ,                         &
                                elemYN(eDn(fJB),eYN_isZeroDepth)       &
                            .and.                                          &
                            (.not. elemYN(eUp(fJB),eYN_isZeroDepth))      &
                        )

                !% +1 indicates zerodepth downstream of face
               ! faceI(faceP(1:npack,ptype),fi_zeroDepth) = oneI       
            end if  

        !%================
        !% ---- fp_JB_bothsides_are_zero_IorS 
            ptype => col_faceP(fp_JB_bothsides_are_zero_IorS)
            npack => npack_faceP(ptype)
            npack = count(                                                 &
                                elemYN(eDn(fJB),eYN_isZeroDepth)       &
                            .and.                                          &
                                elemYN(eUp(fJB),eYN_isZeroDepth)       &
                        ) 
            if (npack > 0) then 
                faceP(1:npack,ptype) = pack(fJB ,                         &
                                elemYN(eDn(fJB),eYN_isZeroDepth)       &
                            .and.                                          &
                                elemYN(eUp(fJB),eYN_isZeroDepth)       &
                        )
                !% +2 indicates zerodepth both upstream and downstream        
                !faceI(faceP(1:npack,ptype),fi_zeroDepth) = twoI        
            end if  

    end subroutine pack_JB_zeroDepth_interior_faces 
!%
!%==========================================================================
!%==========================================================================
!%   
    subroutine pack_static_all_faces ()
        !%------------------------------------------------------------------
        !% Description
        !% Packs all faces whether shared or interior
        !% NOTE that these can only be used with face-only algorithms
        !% and CANNOT be used with adjacent element data (which would cause seg fault)
        !%------------------------------------------------------------------
        !% Declarations
            integer, pointer :: Nfaces, fIdx(:), npack, ptype
        !%------------------------------------------------------------------
        !% Aliases
            Nfaces => N_face(this_image())
            fIdx   => faceI(1:Nfaces,fi_Lidx)
        !%------------------------------------------------------------------
        
    !% fp_Diag_all
        !% --- all faces adjacent to a diagnostic element
        ptype => col_faceP(fp_Diag_all)
        npack => npack_faceP(ptype)

        npack = count(faceYN(1:Nfaces,fYN_isDiag_adjacent_all))

        if (npack > 0) then 
            faceP(1:npack,ptype) = pack(fIdx,                        &
                      faceYN(1:Nfaces,fYN_isDiag_adjacent_all))
        end if

    !% fp_JB_all
        !% --- all faces with JB on eitehr side
        ptype => col_faceP(fp_JB_all)
        npack => npack_faceP(ptype)
        npack = count(                                           &
                      faceYN(1:Nfaces,fYN_isUpstreamJBFace)      &
                        .or.                                     &
                      faceYN(1:Nfaces,fYN_isDownstreamJBFace)    &
                      )
        if (npack > 0) then 
            faceP(1:npack,ptype) = pack(fIdx,                    &
                      faceYN(1:Nfaces,fYN_isUpstreamJBFace)      &
                        .or.                                     &
                      faceYN(1:Nfaces,fYN_isDownstreamJBFace)    &
                      )
        end if


    !% fp_notJB_all
        !% --- CC or Diag faces that are not adjacent to JB
        ptype => col_faceP(fp_notJB_all)
        npack => npack_faceP(ptype)
        npack = count(                                                   &
                        (.not. faceYN(1:Nfaces,fYN_isUpstreamJBFace))    &
                            .and.                                        &
                        (.not. faceYN(1:Nfaces,fYN_isDownstreamJBFace) ) &
                        )
        if (npack > 0) then 
            faceP(1:npack,ptype) = pack(fIdx,                             &
                        (.not. faceYN(1:Nfaces,fYN_isUpstreamJBFace))     &
                        .and.                                             &
                        (.not. faceYN(1:Nfaces,fYN_isDownstreamJBFace) ) &
                        )
        end if

    !% fp_JBorDiag_all
        !% --- faces connected to either a JB or a Diag or or both  
        ptype => col_faceP(fp_JBorDiag_all)
        npack => npack_faceP(ptype)
        npack = count(                                             &
                        (faceYN(1:Nfaces,fYN_isUpstreamJBFace))    &
                        .or.                                       &
                        (faceYN(1:Nfaces,fYN_isDownstreamJBFace) ) &
                        .or.                                       &
                        (faceYN(1:Nfaces,fYN_isDiag_adjacent_all)) &
                      )
        if (npack > 0) then 
            faceP(1:npack,ptype) = pack(fIdx,                      &
                        (faceYN(1:Nfaces,fYN_isUpstreamJBFace))    &
                        .or.                                       &
                        (faceYN(1:Nfaces,fYN_isDownstreamJBFace) ) &
                        .or.                                       &
                        (faceYN(1:Nfaces,fYN_isDiag_adjacent_all)) &
                       )
        end if

    end subroutine pack_static_all_faces
!%
!%==========================================================================
!%==========================================================================
!%
    subroutine pack_static_interior_faces()
        !--------------------------------------------------------------------------
        !% packed arrays for static faces
        !--------------------------------------------------------------------------
        integer :: ii, image
        integer, pointer :: Nfaces, ptype, npack, fIdx(:), eup(:), edn(:)

        character(64) :: subroutine_name = 'pack_static_interior_faces'

        !--------------------------------------------------------------------------
        !if (crashYN) return
        if (setting%Debug%File%pack_mask_arrays) &
            write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        !% pointing to the number of faces in this image
        image  = this_image()
        Nfaces => N_face(image)

        fIdx => faceI(1:Nfaces,fi_Lidx)
        eup  => faceI(1:Nfaces,fi_Melem_uL)
        edn  => faceI(1:Nfaces,fi_Melem_dL)

    !% fp_noBC_IorS
        !% - interior faces except boundary, null, and shared faces
        ptype => col_faceP(fp_noBC_IorS)
        npack => npack_faceP(ptype)

        npack = count(faceYN(1:Nfaces,fYN_isInteriorFace))

        if (npack > 0) then
            faceP(1:npack,ptype) = pack(fIdx, &
                faceYN(1:Nfaces,fYN_isInteriorFace) &
                )
        end if

    !% fp_CC_both_IorS
        !% -- interior faces with CC on BOTH sides
        ptype => col_faceP(fp_CC_both_IorS)
        npack => npack_faceP(ptype)

        npack = count( faceYN(1:Nfaces,fYN_isInteriorFace) &
                      .and.                                &
                      (elemI(eUp,ei_elementType) == CC)    &
                      .and.                                &
                      (elemI(eDn,ei_elementType) == CC))

        if (npack > 0) then 
            faceP(1:npack,ptype) = pack(fIdx, &
                      faceYN(1:Nfaces,fYN_isInteriorFace)  &
                      .and.                                &
                      (elemI(eUp,ei_elementType) == CC)    &
                      .and.                                &
                      (elemI(eDn,ei_elementType) == CC)    &
                    )
        end if

    !% fp_Diag_IorS
        !% - all interior faces adjacent to a diagnostic element
        ptype => col_faceP(fp_Diag_IorS)
        npack => npack_faceP(ptype)

        npack =  count( &
                faceYN(1:Nfaces,fYN_isInteriorFace)   &
                .and. &
                ( &
                   (elemI(edn,ei_HeqType) == diagnostic) &
                   .or.  &
                   (elemI(edn,ei_QeqType) == diagnostic) &
                   .or.  &
                   (elemI(eup,ei_HeqType) == diagnostic) &
                   .or.  &
                   (elemI(eup,ei_QeqType) == diagnostic) &
                ) )

        if (npack > 0) then
            faceP(1:npack, ptype) = pack( fIdx, &
                    faceYN(1:Nfaces,fYN_isInteriorFace)   &
                    .and. &
                    ( &
                       (elemI(edn,ei_HeqType) == diagnostic) &
                       .or.  &
                       (elemI(edn,ei_QeqType) == diagnostic) &
                       .or.  &
                       (elemI(eup,ei_HeqType) == diagnostic) &
                       .or.  &
                       (elemI(eup,ei_QeqType) == diagnostic) &
                    ) )
        end if
        !% set the fYN for diagnostic adjacent face
        faceYN(:,fYN_isDiag_adjacent_interior) = .false.
        faceYN(faceP(1:npack, ptype),fYN_isDiag_adjacent_interior) = .true.

    !% fp_notJB_interior
        ! !% --- all interior faces (no boundary, null shared) that are not adjaent to JB
        ! ptype => col_faceP(fp_notJB_interior)
        ! npack => npack_faceP(ptype)
        
        ! npack = count( &
        !         faceYN(1:Nfaces,fYN_isInteriorFace)     &
        !         .and.                                   &
        !         (   (elemI(edn,ei_elementType) .ne. JB) &
        !             .or.                                &
        !             (elemI(eup,ei_elementTYpe) .ne. JB) &
        !         ) )

        ! if (npack > 0) then 
        !     faceP(1:npack,ptype) = pack(fIdx,           &
        !         faceYN(1:Nfaces,fYN_isInteriorFace)     &
        !         .and.                                   &
        !         (   (elemI(edn,ei_elementType) .ne. JB) &
        !             .or.                                &
        !             (elemI(eup,ei_elementTYpe) .ne. JB) &
        !         ) )
        ! end if


    !% fp_JB_IorS
        !% --- faces that are adjacent to a JM
        ptype => col_faceP(fp_JB_IorS)
        npack => npack_faceP(ptype)

        npack =  count( &
            faceYN(1:Nfaces,fYN_isInteriorFace)   &
                .and. &
                (   (elemI(edn,ei_elementType) == JB) &
                    .or.  &
                    (elemI(eup,ei_elementTYpe) == JB) &
                ) )

        if (npack > 0) then 
            faceP(1:npack, ptype) = pack( fIdx, &
                faceYN(1:Nfaces,fYN_isInteriorFace)   &
                .and. &
                (   (elemI(edn,ei_elementType) == JB) &
                   .or.  &
                    (elemI(eup,ei_elementTYpe) == JB) &
                ) )
        end if

    !% fp_JBCC_interior
        ! !% face that bounds interior JB/CC cells
        ! ptype => col_faceP(fp_JBCC_interior)
        ! npack => npack_faceP(ptype)

        ! npack =  count( &
        !     faceYN(1:Nfaces,fYN_isInteriorFace)           &
        !         .and.                                     &
        !         (                                         &
        !             (  (elemI(edn,ei_elementType) == JB)  &
        !                 .and.                             &
        !                (elemI(eup,ei_elementTYpe) == CC)  &
        !             )                                     &
        !            .or.                                   &
        !            (   (elemI(edn,ei_elementType) == CC)  &
        !                 .and.                             &
        !                (elemI(eup,ei_elementTYpe) == JB)  &
        !            )                                      &
        !         ))

        ! if (npack > 0) then 
        !     faceP(1:npack, ptype) = pack( fIdx, &
        !         faceYN(1:Nfaces,fYN_isInteriorFace)   &
        !         .and. &
        !         (   (elemI(edn,ei_elementType) == JB) &
        !            .or.  &
        !             (elemI(eup,ei_elementTYpe) == JB) &
        !         ) )
        ! end if

    !% fp_J1
        !% - faces with only one link that are not inflow BC
        ptype => col_faceP(fp_J1)
        npack => npack_faceP(ptype)

        npack = count(faceI(1:Nfaces,fi_BCtype)==BCnone)

        if (npack > 0) then 
            faceP(1:npack, ptype) = pack( fIdx, &
                    faceI(1:Nfaces,fi_BCtype)==BCnone)
        end if

    !% fp_J1_BCup
        !% - faces with only one link that are not outfalls
        !%   these are either J1 or BCup
        ptype => col_faceP(fp_J1_BCup)
        npack => npack_faceP(ptype)

        npack = count(                              &
                (faceI(1:Nfaces,fi_BCtype)==BCnone) &
                .or.                                &
                (faceI(1:Nfaces,fi_BCtype)==BCup) )

        if (npack > 0) then 
            faceP(1:npack, ptype) = pack( fIdx,    &
                (faceI(1:Nfaces,fi_BCtype)==BCnone) &
                .or.                                &
                (faceI(1:Nfaces,fi_BCtype)==BCup) )
        end if

   

    !% fp_Diag_NotJB_interior
        ! !% --- faces that are diagnostic but face is not JB face
        ! ptype => col_faceP(fp_Diag_NotJB_interior)
        ! npack => npack_faceP(ptype)

        ! npack =  count( &
        !         faceYN(1:Nfaces,fYN_isInteriorFace)                 &
        !         .and.                                               &
        !         (                                                   &
        !            (elemI(edn,ei_HeqType) == diagnostic)            &
        !            .or.                                             &
        !            (elemI(edn,ei_QeqType) == diagnostic)            &
        !            .or.                                             &
        !            (elemI(eup,ei_HeqType) == diagnostic)            &
        !            .or.                                             &
        !            (elemI(eup,ei_QeqType) == diagnostic)            &
        !         )                                                   &
        !         .and.                                               &
        !         (                                                   &
        !             (.not. faceYN(1:Nfaces,fYN_isDownstreamJBFace)) &
        !             .and.                                           &
        !             (.not. faceYN(1:Nfaces,fYN_isUpstreamJBFace))   &
        !         ) )

        ! if (npack > 0) then 
        !     faceP(1:npack, ptype) = pack( fIdx,                     &
        !         faceYN(1:Nfaces,fYN_isInteriorFace)                 &
        !         .and.                                               &
        !         (                                                   &
        !             (elemI(edn,ei_HeqType) == diagnostic)           &
        !             .or.                                            &
        !             (elemI(edn,ei_QeqType) == diagnostic)           &
        !             .or.                                            &
        !             (elemI(eup,ei_HeqType) == diagnostic)           &
        !             .or.                                            &
        !             (elemI(eup,ei_QeqType) == diagnostic)           &
        !         )                                                   &
        !         .and.                                               &
        !         (                                                   &
        !             (.not. faceYN(1:Nfaces,fYN_isDownstreamJBFace)) &
        !             .and.                                           &
        !             (.not. faceYN(1:Nfaces,fYN_isUpstreamJBFace))   &
        !         ) )
        ! end if       



        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_static_interior_faces
!
!==========================================================================
!==========================================================================
!
    subroutine pack_jump_interior_faces()
        !--------------------------------------------------------------------------
        !% packed arrays for dynamic faces
        !%
        !% HACK: Should the jump packing be called after all jump conditions are
        !% changed? or can it wait until the end of a time step? Note that this
        !% simply packs what is stored in faceI(:,fi_jump_type) as the actual
        !% computation of what is a jump is in the identify_hydraulic_jump subroutine.
        !--------------------------------------------------------------------------
        integer          :: ii, image
        integer, pointer :: Nfaces, ptype, npack, fIdx(:), eup(:), edn(:)
        character(64) :: subroutine_name = 'pack_jump_interior_faces'
        !--------------------------------------------------------------------------
        !if (crashYN) return
        if (setting%Debug%File%pack_mask_arrays) &
            write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        !% pointing to the number of faces in this image
        image  = this_image()
        Nfaces => N_face(image)

        fIdx => faceI(1:Nfaces,fi_Lidx)
        eup  => faceI(1:Nfaces,fi_Melem_uL)
        edn  => faceI(1:Nfaces,fi_Melem_dL)

        !% fp_JumpUp_IorS
        !% -Hydraulic jump from nominal upstream to downstream
        ptype => col_faceP(fp_JumpUp_IorS)
        npack => npack_faceP(ptype)

        npack = count( &
            faceYN(1:Nfaces,fYN_isInteriorFace) &
            .and. &
            faceI(1:Nfaces,fi_jump_type) == jump_from_upstream )

        if (npack > 0) then
            faceP(1:npack, ptype) = pack( fIdx, &
                faceYN(1:Nfaces,fYN_isInteriorFace) &
                .and.&
                faceI(1:Nfaces,fi_jump_type) == jump_from_upstream )
        end if

        !% fp_JumpDn_IorS
        !% --Hydraulic jump from nominal downstream to upstream
        ptype => col_faceP(fp_JumpDn_IorS)
        npack => npack_faceP(ptype)

        npack = count( &
            faceYN(1:Nfaces,fYN_isInteriorFace) &
            .and. &
            faceI(1:Nfaces,fi_jump_type) == jump_from_downstream )

        if (npack > 0) then
            faceP(1:npack, ptype) = pack( fIdx, &
                faceYN(1:Nfaces,fYN_isInteriorFace) &
                .and. &
                faceI(1:Nfaces,fi_jump_type) == jump_from_downstream )
        end if

        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_jump_interior_faces
!
!==========================================================================
!==========================================================================
!
    subroutine pack_static_shared_faces()
        !--------------------------------------------------------------------------
        !% packed arrays for static shared faces
        !--------------------------------------------------------------------------
        integer :: ii
        integer, pointer :: ptype, npack, fIdx(:), eup, edn, gup, gdn, Nfaces
        integer, pointer :: c_image, N_shared_faces, thisP
        logical, pointer :: isUpGhost, isDnGhost
        integer(kind=8) :: crate, cmax, cval
        character(64) :: subroutine_name = 'pack_static_shared_faces'
        !--------------------------------------------------------------------------
        !if (crashYN) return
        if (setting%Debug%File%pack_mask_arrays) &
            write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

        ! !% start the shared timer    
        ! sync all    
        ! if (this_image()==1) then
        !     call system_clock(count=cval,count_rate=crate,count_max=cmax)
        !     setting%Time%WallClock%SharedStart = cval
        ! end if

        !% pointing to the number of faces in this image
        Nfaces => N_face(this_image())

        fIdx   => faceI(1:Nfaces,fi_Lidx)

        !%===========================
        !% fp_noBC_IorS (shared faces)
            !% --- all faces that are shared across images (Internal Boundary Faces)
            !%     which (by definition) cannot include BC faces
            ptype => col_facePS(fp_noBC_IorS)
            npack => npack_facePS(ptype)

            npack = count( &
                    faceYN(1:Nfaces,fYN_isSharedFace))

            if (npack > 0) then
                facePS(1:npack, ptype) = pack( fIdx, &
                    faceYN(1:Nfaces,fYN_isSharedFace))
            else 
                !% no shared faces
            end if

            sync all

        !%===========================
        !% fp_CC_both_IorS
            !% --- all faces with CC on both sides that are shared
            ptype => col_facePS(fp_CC_both_IorS)
            npack => npack_facePS(ptype)
            npack = 0

            !% pointer towards the total number of shared faces in an image
            N_shared_faces  => npack_facePS(fp_noBC_IorS)

            if (N_shared_faces > 0) then
                do ii = 1,N_shared_faces
                    thisP       => facePS(ii,fp_noBC_IorS) !% a shared face for testing
                    eup         => faceI(thisP,fi_Melem_uL)
                    edn         => faceI(thisP,fi_Melem_dL)
                    isUpGhost   => faceYN(thisP,fYN_isUpGhost)
                    gup         => faceI(thisP,fi_GhostElem_uL)
                    isDnGhost   => faceYN(thisP,fYN_isDnGhost)
                    gdn         => faceI(thisP,fi_GhostElem_dL)
                    c_image     => faceI(thisP,fi_Connected_image)
    
                    if (isUpGhost) then
                       if ((elemI(gup,ei_elementType)[c_image] == CC) .and.  &
                           (elemI(edn,ei_elementType)          == CC))   then
    
                            !% advance the number of pack value
                            npack = npack + oneI
                            !% save the face index
                            facePS(npack,ptype) = thisP
                        else 
                            !% not an up ghost
                        end if
    
                    elseif (isDnGhost) then
                        if ((elemI(gdn,ei_elementType)[c_image] == CC) .and.  &
                            (elemI(eup,ei_elementType)          == CC))  then
    
                            !% advance the number of pack value
                            npack = npack + oneI
                            !% save the face index
                            facePS(npack,ptype) = thisP
                        else 
                            !% not a down ghoste
                        end if
                    else 
                        print *, 'CODE ERROR: unexpected else'
                        call util_crashpoint(340112)
                    end if
                end do
            else 
                !% no shared faces
            end if
            

        !%===================================
        !% fp_Diag_IorS (shared faces)
            !% - all faces adjacent to a diagnostic element which is shared across images
            ptype => col_facePS(fp_Diag_IorS)
            npack => npack_facePS(ptype)
            npack = 0

            !% pointer towards the total number of shared faces in an image
            N_shared_faces  => npack_facePS(fp_noBC_IorS)

            if (N_shared_faces > 0) then
                do ii = 1,N_shared_faces
                    thisP       => facePS(ii,fp_noBC_IorS) !% a shared face for testing
                    eup         => faceI(thisP,fi_Melem_uL)
                    edn         => faceI(thisP,fi_Melem_dL)
                    isUpGhost   => faceYN(thisP,fYN_isUpGhost)
                    gup         => faceI(thisP,fi_GhostElem_uL)
                    isDnGhost   => faceYN(thisP,fYN_isDnGhost)
                    gdn         => faceI(thisP,fi_GhostElem_dL)
                    c_image     => faceI(thisP,fi_Connected_image)

                    if (isUpGhost) then
                        if ((elemI(gup,ei_HeqType)[c_image] == diagnostic) .or.  &
                            (elemI(gup,ei_QeqType)[c_image] == diagnostic) .or.  &
                            (elemI(edn,ei_HeqType)          == diagnostic) .or.  &
                            (elemI(edn,ei_QeqType)          == diagnostic))   then

                            !% advance the number of pack value
                            npack = npack + oneI
                            !% save the face index
                            facePS(npack,ptype) = thisP
                        else 
                            !% not an up ghost
                        end if

                    elseif (isDnGhost) then
                        if ((elemI(gdn,ei_HeqType)[c_image] == diagnostic) .or.  &
                            (elemI(gdn,ei_QeqType)[c_image] == diagnostic) .or.  &
                            (elemI(eup,ei_HeqType)          == diagnostic) .or.  &
                            (elemI(eup,ei_QeqType)          == diagnostic))  then

                            !% advance the number of pack value
                            npack = npack + oneI
                            !% save the face index
                            facePS(npack,ptype) = thisP
                        else 
                            !% not a down ghost
                        end if
                    else 
                        print *, 'CODE ERROR: unexpected else'
                        call util_crashpoint(62098711)
                    end if
                end do
            else
                !% no shared faces
            end if

            !% set the shared face logical
            if (npack > 0) faceYN(facePS(1:npack, ptype),fYN_isDiag_adjacent_interior) = .true.

        !%=======================
        !% fp_JB_IorS (shared faces)
            !% --- shared faces that have JB on one side or the other
            ptype => col_facePS(fp_JB_IorS)
            npack => npack_facePS(ptype)
            npack = 0
            
            !% pointer towards the total number of shared faces in an image
            N_shared_faces  => npack_facePS(fp_noBC_IorS)

            if (N_shared_faces > 0) then 
                do ii=1,N_shared_faces
                    thisP       => facePS(ii,fp_noBC_IorS) !% a shared face for testing
                    eup         => faceI(thisP,fi_Melem_uL)
                    edn         => faceI(thisP,fi_Melem_dL)
                    isUpGhost   => faceYN(thisP,fYN_isUpGhost)
                    gup         => faceI(thisP,fi_GhostElem_uL)
                    isDnGhost   => faceYN(thisP,fYN_isDnGhost)
                    gdn         => faceI(thisP,fi_GhostElem_dL)
                    c_image     => faceI(thisP,fi_Connected_image)
               

                    if (isUpGhost) then
                        if ((elemI(gup,ei_elementType)[c_image] == JB) .or.  &
                            (elemI(edn,ei_elementType)          == JB))   then

                            !% advance the number of pack value
                            npack = npack + oneI
                            !% save the face index
                            facePS(npack,ptype) = thisP
                        else 
                            !% not an up ghost
                        end if

                    elseif (isDnGhost) then
                        if ((elemI(gdn,ei_elementType)[c_image] == JB) .or.  &
                            (elemI(eup,ei_elementType)          == JB))  then

                            !% advance the number of pack value
                            npack = npack + oneI
                            !% save the face index
                            facePS(npack,ptype) = thisP
                        else 
                            !% not a down ghost
                        end if
                    else 
                        print *, 'CODE ERROR: unexpected else'
                        call util_crashpoint(510987)
                    end if
                end do
            else 
                !% no shared faces
            end if
            
        !% stop the shared timer
        sync all
        ! if (this_image()==1) then
        !     call system_clock(count=cval,count_rate=crate,count_max=cmax)
        !     setting%Time%WallClock%SharedStop = cval
        !     setting%Time%WallClock%SharedCumulative &
        !             = setting%Time%WallClock%SharedCumulative &
        !             + setting%Time%WallClock%SharedStop &
        !             - setting%Time%WallClock%SharedStart
        ! end if 
        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_static_shared_faces
!
!==========================================================================
!==========================================================================
!
    subroutine pack_jump_shared_faces()
        !--------------------------------------------------------------------------
        !% packed arrays for dynamic shared faces
        !%
        !% HACK: Should the jump packing be called after all jump conditions are
        !% changed? or can it wait until the end of a time step? Note that this
        !% simply packs what is stored in faceI(:,fi_jump_type) as the actual
        !% computation of what is a jump is in the identify_hydraulic_jump subroutine.
        !--------------------------------------------------------------------------
        integer          :: ii, image
        integer, pointer :: ptype, npack, fIdx(:), Nfaces
        integer, pointer :: N_shared_faces, thisP, eup, edn, gup, gdn, c_image
        logical, pointer :: isUpGhost, isDnGhost
        integer(kind=8) :: crate, cmax, cval
        character(64)    :: subroutine_name = 'pack_jump_shared_faces'
        !--------------------------------------------------------------------------
        
        if (setting%Debug%File%pack_mask_arrays) &
            write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
            
        !% start the shared timer    
        sync all    
        if (this_image()==1) then
            call system_clock(count=cval,count_rate=crate,count_max=cmax)
            setting%Time%WallClock%SharedStart = cval
            setting%Time%WallClock%SharedStart_B = cval
        end if

        !% pointing to the number of faces in this image
        image  = this_image()
        Nfaces => N_face(image)

        fIdx => faceI(1:Nfaces,fi_Lidx)

       ! print *, 'in shared pack'
        !print *, Nfaces, fIdx

        !% fp_JumpUp_IorS (shared faces)
        !% -Hydraulic jump from nominal upstream to downstream
        ptype => col_facePS(fp_JumpUp_IorS)
        npack => npack_facePS(ptype)

        npack = count( &
                faceYN(1:Nfaces,fYN_isSharedFace)              .and. &
                (faceI(1:Nfaces,fi_jump_type) == jump_from_upstream))

        if (npack > 0) then
            facePS(1:npack, ptype) = pack( fIdx, &
                faceYN(1:Nfaces,fYN_isSharedFace)              .and. &
                (faceI(1:Nfaces,fi_jump_type) == jump_from_upstream))
        end if

        !% fp_JumpDn_IorS
        !% --Hydraulic jump from nominal downstream to upstream
        ptype => col_facePS(fp_JumpDn_IorS)
        npack => npack_facePS(ptype)

        npack = count( &
                faceYN(1:Nfaces,fYN_isSharedFace)                .and. &
                (faceI(1:Nfaces,fi_jump_type) == jump_from_downstream))

        if (npack > 0) then
            facePS(1:npack, ptype) = pack( fIdx, &
                faceYN(1:Nfaces,fYN_isSharedFace)                .and. &
                (faceI(1:Nfaces,fi_jump_type) == jump_from_downstream))
        end if

        !% stop the shared timer
        sync all
        if (this_image()==1) then
            call system_clock(count=cval,count_rate=crate,count_max=cmax)
            setting%Time%WallClock%SharedStop = cval
            setting%Time%WallClock%SharedCumulative &
                    = setting%Time%WallClock%SharedCumulative &
                    + setting%Time%WallClock%SharedStop &
                    - setting%Time%WallClock%SharedStart

            setting%Time%WallClock%SharedStop_B = cval
            setting%Time%WallClock%SharedCumulative_B &
                    = setting%Time%WallClock%SharedCumulative_B &
                    + setting%Time%WallClock%SharedStop_B &
                    - setting%Time%WallClock%SharedStart_B            
        end if 
        if (setting%Debug%File%pack_mask_arrays) &
        write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    end subroutine pack_jump_shared_faces
!%
!%==========================================================================
!%==========================================================================
!%
    subroutine pack_CC_zeroDepth_shared_faces ()
        !%------------------------------------------------------------------
            !% Description
            !% Dynamic pack for shared faces that have zero depth elements 
            !% on one or both sides AND BOTH SIDES ARE CC
            !%------------------------------------------------------------------
            !% Declarations
                integer, pointer :: N_shared_faces 
                integer, pointer :: thisP, eup, edn, gup, gdn, c_image
                integer, pointer :: ptype_up_zero, ptype_dn_zero, ptype_both_zero
                integer, pointer :: npack_up_zero, npack_dn_zero, npack_both_zero
                logical, pointer :: isUpGhost, isDnGhost
                integer :: ii
            !%------------------------------------------------------------------
                !% start the shared timer    
                sync all 
            !%------------------------------------------------------------------
            !% Aliases:
                !% pointer towards the total number of shared faces in an image
                N_shared_faces  => npack_facePS(fp_CC_both_IorS)
                ptype_up_zero   => col_facePS(fp_CC_upstream_is_zero_IorS)
                npack_up_zero   => npack_facePS(ptype_up_zero)
                ptype_dn_zero   => col_facePS(fp_CC_downstream_is_zero_IorS)
                npack_dn_zero   => npack_facePS(col_facePS(ptype_dn_zero))
                ptype_both_zero => col_facePS(fp_CC_bothsides_are_zero_IorS)
                npack_both_zero => npack_facePS(col_facePS(ptype_both_zero))
                !% initialize the npacks
                npack_up_zero   = 0
                npack_dn_zero   = 0
                npack_both_zero = 0

            if (N_shared_faces > 0) then

                !% cycle through faces with CC on both sides
                do ii = 1,N_shared_faces

                    thisP       => facePS(ii,fp_CC_both_IorS) !% face for testing
                    eup         => faceI(thisP,fi_Melem_uL)
                    edn         => faceI(thisP,fi_Melem_dL)
                    isUpGhost   => faceYN(thisP,fYN_isUpGhost)
                    gup         => faceI(thisP,fi_GhostElem_uL)
                    isDnGhost   => faceYN(thisP,fYN_isDnGhost)
                    gdn         => faceI(thisP,fi_GhostElem_dL)
                    c_image     => faceI(thisP,fi_Connected_image)
                    
                    if (isUpGhost) then

                        !% --- zero depth on upstream element
                        if ((      elemYN(gup,eYN_isZeroDepth)[c_image]) .and.  &
                            (.not. elemYN(edn,eYN_isZeroDepth)         ))  then

                            npack_up_zero = npack_up_zero + oneI
                            facePS(npack_up_zero,ptype_up_zero) = thisP
                            !% -1 indicates zerodepth upstream of face        
                            !faceI(thisP,fi_zeroDepth) = -oneI  

                        !% --- zero depth on downstream element
                        else if ((.not. elemYN(gup,eYN_isZeroDepth)[c_image]) .and.  &
                                       (elemYN(edn,eYN_isZeroDepth)               ))  then

                                npack_dn_zero = npack_dn_zero + oneI
                                facePS(npack_dn_zero,ptype_dn_zero) = thisP
                                !% +1 indicates zerodepth downstream of face
                                !faceI(thisP,fi_zeroDepth)= oneI  
                        
                        !% --- zero depth on both elements        
                        else if ((elemYN(gup,eYN_isZeroDepth)[c_image]) .and.  &
                                 (elemYN(edn,eYN_isZeroDepth)         ))  then 

                                npack_both_zero = npack_both_zero + oneI
                                facePS(npack_both_zero,ptype_both_zero) = thisP
                                !% +2 indicates zerodepth both upstream and downstream        
                               !faceI(thisP,fi_zeroDepth) = twoI  
                        else 
                            !% zero depth element not found
                        end if

                    else if (isDnGhost) then
                    
                        !% --- zero depth on upstream element
                        if ((      elemYN(eup,eYN_isZeroDepth)               ) .and.  &
                            (.not. elemYN(gdn,eYN_isZeroDepth)[c_image]))  then

                            npack_up_zero = npack_up_zero + oneI
                            facePS(npack_up_zero,ptype_up_zero) = thisP
                            !% -1 indicates zerodepth upstream of face        
                            !faceI(thisP,fi_zeroDepth) = -oneI   
                        
                        !% --- zero depth on downstream element
                        else if ((.not. elemYN(eup,eYN_isZeroDepth)         ) .and.  &
                                (       elemYN(gdn,eYN_isZeroDepth)[c_image]))  then

                                npack_dn_zero = npack_dn_zero + oneI
                                facePS(npack_dn_zero,ptype_dn_zero) = thisP
                                !% +1 indicates zerodepth downstream of face
                                !faceI(thisP,fi_zeroDepth)= oneI
                        
                        !% --- zero depth on both elements   
                        else if ((elemYN(eup,eYN_isZeroDepth)         ) .and.  &
                                 (elemYN(gdn,eYN_isZeroDepth)[c_image]))  then
                                
                                npack_both_zero = npack_both_zero + oneI
                                facePS(npack_both_zero,ptype_both_zero) = thisP
                                !% +2 indicates zerodepth both upstream and downstream        
                                !faceI(thisP,fi_zeroDepth) = twoI
                        else 
                        !% --- no zero depth element found
                        end if
                    else 
                        print *, 'CODE ERROR: unexpected else'
                        call util_crashpoint(798723)
                    end if
                
                end do
            else 
                !% no shared elements
            end if

    end subroutine pack_CC_zeroDepth_shared_faces

!%
!%==========================================================================
!%==========================================================================
!%
    subroutine pack_JB_zeroDepth_shared_faces ()

       ! print *, 'stub routine for pack_JB_zeroDepth_shared_faces'

    end subroutine pack_JB_zeroDepth_shared_faces
!%
!%==========================================================================
!%==========================================================================
!%
!% OBSOLETE?
    ! subroutine pack_link_node_output
    !     integer :: ii, jj, link_output_idx_length, node_output_idx_length
    !     character(64)    :: subroutine_name = 'pack_link_node_output'
    !     !% --------------------------------------------------------------------------
    !     !if (crashYN) return
    !     if (setting%Debug%File%pack_mask_arrays) &
    !         write(*,"(A,i5,A)") '*** enter ' // trim(subroutine_name) // " [Processor ", this_image(), "]"

    !     !% count the amount of valid output links
    !     link_output_idx_length = count(link_output_idx(:) /= nullvalueI)
    !     node_output_idx_length = count(node_output_idx(:) /= nullvalueI)

    !     !% allocate the pack
    !     allocate(link%P%have_output(link_output_idx_length))
    !     allocate(node%P%have_output(node_output_idx_length))

    !     !% fill the pack
    !     link%P%have_output = pack(link%I(link_output_idx(1:link_output_idx_length), li_idx), &
    !         link%I(link_output_idx(1:link_output_idx_length), li_P_image) == this_image())
    !     node%P%have_output = pack(node%I(node_output_idx(1:node_output_idx_length), ni_idx), &
    !         node%I(node_output_idx(1:node_output_idx_length), ni_P_image) == this_image())

    !     if (setting%Debug%File%pack_mask_arrays) &
    !     write(*,"(A,i5,A)") '*** leave ' // trim(subroutine_name) // " [Processor ", this_image(), "]"
    ! end subroutine pack_link_node_output
!
!==========================================================================
! END MODULE
!==========================================================================
!    
end module pack_mask_arrays
