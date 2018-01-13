! Copyright (c) 2015 Alberto Otero de la Roza
! <aoterodelaroza@gmail.com>,
! Ángel Martín Pendás <angel@fluor.quimica.uniovi.es> and Víctor Luaña
! <victor@fluor.quimica.uniovi.es>.
!
! critic2 is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at
! your option) any later version.
!
! critic2 is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see
! <http://www.gnu.org/licenses/>.

! Structure class and routines for basic crystallography computations
module crystalmod
  use spglib, only: SpglibDataset
  use types, only: atom, celatom, neighstar, species
  use fragmentmod, only: fragment
  use param, only: maxzat0
  implicit none

  private

  !> Crystal type
  type crystal
     ! Initialization flags
     logical :: isinit = .false. !< has the crystal structure been initialized?
     logical :: isenv = .false. !< were the atomic environments determined?
     integer :: havesym = 0 !< was the symmetry determined? (0 - nosym, 1 - full)
     logical :: isast = .false. !< have the molecular asterisms and connectivity been calculated?
     logical :: isewald = .false. !< do we have the data for ewald's sum?
     logical :: isrecip = .false. !< symmetry information about the reciprocal cell
     logical :: isnn = .false. !< information about the nearest neighbors

     ! file name for the occasional critic2 trick
     character(len=128) :: file

     !! Initialization level: isinit !!
     ! species list
     integer :: nspc = 0 !< Number of species
     type(species), allocatable :: spc(:) !< Species
     ! non-equivalent atoms list
     integer :: nneq = 0 !< Number of non-equivalent atoms
     type(atom), allocatable :: at(:) !< Non-equivalent atom array
     ! complete atoms list
     integer :: ncel = 0 !< Number of atoms in the main cell
     type(celatom), allocatable :: atcel(:) !< List of atoms in the main cell
     ! cell and lattice metrics
     real*8 :: aa(3) !< cell lengths (bohr)
     real*8 :: bb(3) !< cell angles (degrees)
     real*8 :: omega !< unit cell volume
     real*8 :: gtensor(3,3) !< metric tensor (3,3)
     real*8 :: ar(3) !< reciprocal cell lengths
     real*8 :: grtensor(3,3) !< reciprocal metric tensor (3,3)
     ! crystallographic/cartesian conversion matrices
     real*8 :: crys2car(3,3) !< crystallographic to cartesian matrix
     real*8 :: car2crys(3,3) !< cartesian to crystallographic matrix
     real*8 :: n2_x2c !< sqrt(3)/norm-2 of the crystallographic to cartesian matrix
     real*8 :: n2_c2x !< sqrt(3)/norm-2 of the cartesian to crystallographic matrix
     ! space-group symmetry
     type(SpglibDataset) :: spg !< spglib's symmetry dataset
     integer :: neqv !< number of symmetry operations
     integer :: neqvg !< number of symmetry operations, reciprocal space
     integer :: ncv  !< number of centering vectors
     real*8, allocatable :: cen(:,:) !< centering vectors
     real*8 :: rotm(3,4,48) !< symmetry operations
     real*8 :: rotg(3,3,48) !< symmetry operations, reciprocal space
     ! variables for molecular systems
     logical :: ismolecule = .false. !< is it a molecule?
     real*8 :: molx0(3) !< centering vector for the molecule
     real*8 :: molborder(3) !< molecular cell border (cryst coords)
     ! wigner-seitz cell 
     integer :: nws !< number of WS neighbors/faces
     integer :: ivws(3,16) !< WS neighbor lattice points
     integer :: nvert_ws !< number of vertices of the WS cell
     integer, allocatable :: nside_ws(:) !< number of sides of WS faces
     integer, allocatable :: iside_ws(:,:) !< sides of the WS faces
     real*8, allocatable :: vws(:,:) !< vertices of the WS cell
     logical :: isortho !< is the cell orthogonal?
     ! rotations and translations for finding shortest vectors
     real*8 :: rdelr(3,3) !< x_del = x_cur * c%rdelr
     real*8 :: rdeli(3,3) !< x_cur = x_del * c%rdeli
     real*8 :: rdeli_x2c(3,3) !< c_cur = x_del * c%rdeli_x2c
     real*8 :: crys2car_del(3,3) !< crys2car delaunay cell
     integer :: ivws_del(3,16) !< WS neighbor lattice points (del cell, Cartesian)
     logical :: isortho_del !< is the reduced cell orthogonal?
     ! core charges
     integer :: zpsp(maxzat0)

     !! Initialization level: isenv !!
     ! atomic environment of the cell
     integer :: nenv = 0 !< Environment around the main cell
     real*8 :: dmax0_env !< Maximum environment distance
     type(celatom), allocatable :: atenv(:) !< Atoms around the main cell

     !! Initialization level: isast !!
     ! asterisms
     type(neighstar), allocatable :: nstar(:) !< Neighbor stars
     integer :: nmol = 0 !< Number of molecules in the unit cell
     type(fragment), allocatable :: mol(:) !< Molecular fragments
     logical, allocatable :: moldiscrete(:) !< Is the crystal extended or molecular?

     !! Initialization level: isewald !!
     ! ewald data
     real*8 :: rcut, hcut, eta, qsum
     integer :: lrmax(3), lhmax(3)

   contains
     ! construction, destruction, initialization
     procedure :: init => struct_init !< Allocate arrays and nullify variables
     procedure :: checkflags !< Check the flags for a given crystal
     procedure :: end => struct_end !< Deallocate arrays and nullify variables
     procedure :: struct_new !< Initialize the structure from a crystal seed
     procedure :: struct_fill !< Initialize the structure from minimal info (already in the object)

     ! basic crystallographic operations
     procedure :: x2c !< Convert crystallographic to cartesian
     procedure :: c2x !< Convert cartesian to crystallographic
     procedure :: distance !< Distance between points in crystallographic coordinates
     procedure :: eql_distance !< Shortest distance between lattice-translated vectors
     procedure :: shortest !< Gives the lattice-translated vector with shortest length
     procedure :: are_close !< True if a vector is at a distance less than eps of another
     procedure :: are_lclose !< True if a vector is at a distance less than eps of all latice translations of another
     procedure :: nearest_atom !< Calculate the atom nearest to a given point
     procedure :: identify_atom !< Identify an atom in the unit cell
     procedure :: identify_fragment !< Build an atomic fragment of the crystal
     procedure :: identify_fragment_from_xyz !< Build a crystal fragment from an xyz file
     procedure :: symeqv  !< Calculate the symmetry-equivalent positions of a point
     procedure :: get_mult !< Multiplicity of a point
     procedure :: get_mult_reciprocal !< Reciprocal-space multiplicity of a point

     ! molecular environments and neighbors
     procedure :: build_env !< Build the crystal environment (atenv)
     procedure :: find_asterisms !< Find the molecular asterisms (atomic connectivity)
     procedure :: fill_molecular_fragments !< Find the molecular fragments in the crystal
     procedure :: listatoms_cells !< List all atoms in n cells (maybe w border)
     procedure :: listatoms_sphcub !< List all atoms in a sphere or cube
     procedure :: listmolecules !< List all molecules in the crystal
     procedure :: pointshell !< Calculate atomic shells around a point
     procedure :: sitesymm !< Determine the local-symmetry group symbol for a point
     procedure :: get_pack_ratio !< Calculate the packing ratio

     ! complex operations
     procedure :: powder !< Calculate the powder diffraction pattern
     procedure :: rdf !< Calculate the radial distribution function
     procedure :: calculate_ewald_cutoffs !< Calculate the cutoffs for Ewald's sum
     procedure :: ewald_energy !< electrostatic energy (Ewald)
     procedure :: ewald_pot !< electrostatic potential (Ewald)

     ! unit cell transformations
     procedure :: newcell !< Change the unit cell and rebuild the crystal
     procedure :: cell_standard !< Transform the the standard cell (possibly primitive)
     procedure :: cell_niggli !< Transform to the Niggli primitive cell
     procedure :: cell_delaunay !< Transform to the Delaunay primitive cell
     procedure :: delaunay_reduction !< Perform the delaunay reduction.

     ! output routines
     procedure :: report => struct_report !< Write lots of information about the crystal structure to uout
     procedure :: struct_report_symxyz !< Write sym. ops. in crystallographic notation to uout

     ! symmetry and WS cell
     procedure :: spglib_wrap !< Fill symmetry information in the crystal using spglib
     procedure :: wigner !< Calculate the WS cell and the IWS/tetrahedra
     procedure :: pmwigner !< Poor man's wigner

     ! structure writers
     procedure :: write_mol
     procedure :: write_3dmodel
     procedure :: write_espresso
     procedure :: write_vasp
     procedure :: write_abinit
     procedure :: write_elk
     procedure :: write_gaussian
     procedure :: write_tessel
     procedure :: write_critic
     procedure :: write_cif
     procedure :: write_d12
     procedure :: write_escher
     procedure :: write_gulp
     procedure :: write_lammps
     procedure :: write_siesta_fdf
     procedure :: write_siesta_in
     procedure :: write_dftbp_hsd
     procedure :: write_dftbp_gen

     ! grid writers
     procedure :: writegrid_cube
     procedure :: writegrid_vasp

     ! promolecular and core density calculation
     procedure :: promolecular
     procedure :: promolecular_grid
  end type crystal
  public :: crystal

  ! private to this module
  private :: lattpg
  private :: typeop
  ! private for wigner-seitz routines
  private :: equiv_tetrah
  private :: perm3
  ! other crystallography tools that are crystal-independent
  public :: search_lattice
  public :: pointgroup_info
  
  ! symmetry operation symbols
  integer, parameter :: ident=0 !< identifier for sym. operations
  integer, parameter :: inv=1 !< identifier for sym. operations
  integer, parameter :: c2=2 !< identifier for sym. operations
  integer, parameter :: c3=3 !< identifier for sym. operations
  integer, parameter :: c4=4 !< identifier for sym. operations
  integer, parameter :: c6=5 !< identifier for sym. operations
  integer, parameter :: s3=6 !< identifier for sym. operations
  integer, parameter :: s4=7 !< identifier for sym. operations
  integer, parameter :: s6=8 !< identifier for sym. operations
  integer, parameter :: sigma=9 !< identifier for sym. operations

  ! array initialization values
  integer, parameter :: mspc0 = 4
  integer, parameter :: mneq0 = 4
  integer, parameter :: mcel0 = 10
  integer, parameter :: menv0 = 100

  ! holohedry identifier
  integer, parameter, public :: holo_unk = 0 ! unknown
  integer, parameter, public :: holo_tric = 1 ! triclinic
  integer, parameter, public :: holo_mono = 2 ! monoclinic
  integer, parameter, public :: holo_ortho = 3 ! orthorhombic
  integer, parameter, public :: holo_tetra = 4 ! tetragonal
  integer, parameter, public :: holo_trig = 5 ! trigonal
  integer, parameter, public :: holo_hex = 6 ! hexagonal
  integer, parameter, public :: holo_cub = 7 ! cubic
  character(len=12), parameter, public :: holo_string(0:7) = (/ &
     "unknown     ","triclinic   ","monoclinic  ","orthorhombic",&
     "tetragonal  ","trigonal    ","hexagonal   ","cubic       "/)

  ! Laue class identifier
  integer, parameter, public :: laue_unk = 0 ! unknown
  integer, parameter, public :: laue_1 = 1 ! -1
  integer, parameter, public :: laue_2m = 2 ! 2/m
  integer, parameter, public :: laue_mmm = 3 ! mmm
  integer, parameter, public :: laue_4m = 4 ! 4/m
  integer, parameter, public :: laue_4mmm = 5 ! 4/mmm
  integer, parameter, public :: laue_3 = 6 ! -3
  integer, parameter, public :: laue_3m = 7 ! -3m
  integer, parameter, public :: laue_6m = 8 ! 6/m
  integer, parameter, public :: laue_6mmm = 9 ! 6/mmm
  integer, parameter, public :: laue_m3 = 10 ! m-3
  integer, parameter, public :: laue_m3m = 11 ! m-3m
  character(len=12), parameter, public :: laue_string(0:11) = (/ &
     "unknown","-1     ","2/m    ","mmm    ","4/m    ","4/mmm  ",&
     "-3     ","-3m    ","6/m    ","6/mmm  ","m-3    ","m-3m   "/)

  ! module procedure interfaces
  interface
     module subroutine struct_init(c)
       class(crystal), intent(inout) :: c
     end subroutine struct_init
     module subroutine checkflags(c,crash,env0,ast0,recip0,nn0,ewald0)
       class(crystal), intent(inout) :: c
       logical :: crash
       logical, intent(in), optional :: env0
       logical, intent(in), optional :: ast0
       logical, intent(in), optional :: recip0
       logical, intent(in), optional :: nn0
       logical, intent(in), optional :: ewald0
     end subroutine checkflags
     module subroutine struct_end(c)
       class(crystal), intent(inout) :: c
     end subroutine struct_end
     module subroutine struct_new(c,seed,crashfail)
       use crystalseedmod, only: crystalseed
       class(crystal), intent(inout) :: c
       type(crystalseed), intent(in) :: seed
       logical, intent(in) :: crashfail
     end subroutine struct_new
     module subroutine struct_fill(c,env0,iast0,recip0,lnn0,ewald0)
       class(crystal), intent(inout) :: c
       integer :: iast0
       logical, intent(in) :: env0, recip0, lnn0, ewald0
     end subroutine struct_fill
     pure module function x2c(c,xx) 
       class(crystal), intent(in) :: c
       real*8, intent(in) :: xx(3) 
       real*8 :: x2c(3)
     end function x2c
     pure module function c2x(c,xx)
       class(crystal), intent(in) :: c
       real*8, intent(in)  :: xx(3)
       real*8 :: c2x(3)
     end function c2x
     pure module function distance(c,x1,x2)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: x1(3)
       real*8, intent(in) :: x2(3)
       real*8 :: distance
     end function distance
     pure module function eql_distance(c,x1,x2)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: x1(3)
       real*8, intent(in) :: x2(3)
       real*8 :: eql_distance
     end function eql_distance
     pure module subroutine shortest(c,x,dist2)
       class(crystal), intent(in) :: c
       real*8, intent(inout) :: x(3)
       real*8, intent(out) :: dist2
     end subroutine shortest
     module function are_close(c,x0,x1,eps,d2)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: x0(3), x1(3)
       real*8, intent(in) :: eps
       real*8, intent(out), optional :: d2
       logical :: are_close
     end function are_close
     module function are_lclose(c,x0,x1,eps,d2)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: x0(3), x1(3)
       real*8, intent(in) :: eps
       real*8, intent(out), optional :: d2
       logical :: are_lclose
     end function are_lclose
     module subroutine nearest_atom(c,xp,nid,dist,lvec)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: xp(:)
       integer, intent(inout) :: nid
       real*8, intent(out) :: dist
       integer, intent(out) :: lvec(3)
     end subroutine nearest_atom
     module function identify_atom(c,x0,lncel0)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: x0(3)
       logical, intent(in), optional :: lncel0
       integer :: identify_atom
     end function identify_atom
     module function identify_fragment(c,nat,x0) result(fr)
       class(crystal), intent(in) :: c
       integer, intent(in) :: nat
       real*8, intent(in) :: x0(3,nat)
       type(fragment) :: fr
     end function identify_fragment
     module function identify_fragment_from_xyz(c,file) result(fr)
       class(crystal), intent(in) :: c
       character*(*) :: file
       type(fragment) :: fr
     end function identify_fragment_from_xyz
     module subroutine symeqv(c,xp0,mmult,vec,irotm,icenv,eps0)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: xp0(3)
       integer, intent(out) :: mmult
       real*8, allocatable, intent(inout), optional :: vec(:,:)
       integer, allocatable, intent(inout), optional :: irotm(:)
       integer, allocatable, intent(inout), optional :: icenv(:)
       real*8, intent(in), optional :: eps0
     end subroutine symeqv
     module function get_mult(c,x0) result (mult)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: x0(3)
       integer :: mult
     end function get_mult
     module function get_mult_reciprocal(c,x0) result (mult)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: x0(3)
       integer :: mult
     end function get_mult_reciprocal
     module subroutine build_env(c,dmax0)
       class(crystal), intent(inout) :: c
       real*8, intent(in), optional :: dmax0
     end subroutine build_env
     module subroutine find_asterisms(c)
       class(crystal), intent(inout) :: c
     end subroutine find_asterisms
     module function listatoms_cells(c,nx,doborder) result(fr)
       class(crystal), intent(in) :: c
       integer, intent(in) :: nx(3)
       logical, intent(in) :: doborder
       type(fragment) :: fr
     end function listatoms_cells
     module function listatoms_sphcub(c,rsph,xsph,rcub,xcub) result(fr)
       class(crystal), intent(in) :: c
       real*8, intent(in), optional :: rsph, xsph(3)
       real*8, intent(in), optional :: rcub, xcub(3)
       type(fragment) :: fr
     end function listatoms_sphcub
     module subroutine fill_molecular_fragments(c)
       class(crystal), intent(inout) :: c
     end subroutine fill_molecular_fragments
     module subroutine listmolecules(c,fri,nfrag,fr,isdiscrete)
       class(crystal), intent(inout) :: c
       type(fragment), intent(in) :: fri
       integer, intent(out) :: nfrag
       type(fragment), intent(out), allocatable :: fr(:)
       logical, intent(out), allocatable :: isdiscrete(:)
     end subroutine listmolecules
     module subroutine pointshell(c,x0,shmax,nneig,wat,dist,xenv)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: x0(3)
       integer, intent(in) :: shmax
       integer, intent(out) :: nneig(shmax)
       integer, intent(out) :: wat(shmax)
       real*8, intent(out) :: dist(shmax)
       real*8, intent(inout), allocatable, optional :: xenv(:,:,:)
     end subroutine pointshell
     module function sitesymm(c,x0,eps0,leqv,lrotm)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: x0(3)
       real*8, intent(in), optional :: eps0
       character*3 :: sitesymm
       integer, optional :: leqv
       real*8, optional :: lrotm(3,3,48)
     end function sitesymm
     module function get_pack_ratio(c) result (px)
       class(crystal), intent(inout) :: c
     end function get_pack_ratio
     module subroutine powder(c,th2ini0,th2end0,npts,lambda0,fpol,&
        sigma,t,ih,th2p,ip,hvecp)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: th2ini0, th2end0
       integer, intent(in) :: npts
       real*8, intent(in) :: lambda0
       real*8, intent(in) :: fpol
       real*8, intent(in) :: sigma
       real*8, allocatable, intent(inout) :: t(:)
       real*8, allocatable, intent(inout) :: ih(:)
       real*8, allocatable, intent(inout) :: th2p(:)
       real*8, allocatable, intent(inout) :: ip(:)
       integer, allocatable, intent(inout) :: hvecp(:,:)
     end subroutine powder
     module subroutine rdf(c,rend,sigma,npts,t,ih)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: rend
       real*8, intent(in) :: sigma
       integer, intent(in) :: npts
       real*8, allocatable, intent(inout) :: t(:)
       real*8, allocatable, intent(inout) :: ih(:)
     end subroutine rdf
     module subroutine calculate_ewald_cutoffs(c)
       class(crystal), intent(inout) :: c
     end subroutine calculate_ewald_cutoffs
     module function ewald_energy(c) result(ewe)
       class(crystal), intent(inout) :: c
     end function ewald_energy
     module function ewald_pot(c,x,isnuc)
       class(crystal), intent(inout) :: c
       real*8, intent(in) :: x(3)
       logical, intent(in) :: isnuc
       real*8 :: ewald_pot
     end function ewald_pot
     module subroutine newcell(c,x00,t0,verbose0)
       class(crystal), intent(inout) :: c
       real*8, intent(in) :: x00(3,3)
       real*8, intent(in), optional :: t0(3)
       logical, intent(in), optional :: verbose0
     end subroutine newcell
     module subroutine cell_standard(c,toprim,doforce,verbose)
       class(crystal), intent(inout) :: c
       logical, intent(in) :: toprim
       logical, intent(in) :: doforce
       logical, intent(in) :: verbose
     end subroutine cell_standard
     module subroutine cell_niggli(c,verbose)
       class(crystal), intent(inout) :: c
       logical, intent(in) :: verbose
     end subroutine cell_niggli
     module subroutine cell_delaunay(c,verbose)
       class(crystal), intent(inout) :: c
       logical, intent(in) :: verbose
     end subroutine cell_delaunay
     module subroutine delaunay_reduction(c,rmat,rmati,sco,rbas)
       class(crystal), intent(in) :: c
       real*8, intent(out) :: rmat(3,4)
       real*8, intent(in), optional :: rmati(3,3)
       real*8, intent(out), optional :: sco(4,4)
       real*8, intent(out), optional :: rbas(3,3)
     end subroutine delaunay_reduction
     module subroutine struct_report(c,lcrys,lq)
       class(crystal), intent(in) :: c
       logical, intent(in) :: lcrys
       logical, intent(in) :: lq
     end subroutine struct_report
     module subroutine struct_report_symxyz(c,strfin)
       class(crystal), intent(in) :: c
       character*255, intent(out), optional :: strfin(c%neqv)
     end subroutine struct_report_symxyz
     module subroutine spglib_wrap(c,usenneq,onlyspg)
       class(crystal), intent(inout) :: c
       logical, intent(in) :: usenneq
       logical, intent(in) :: onlyspg
     end subroutine spglib_wrap
     module subroutine wigner(c,xorigin,nvec,vec,area0,ntetrag,tetrag,&
        nvert_ws,nside_ws,iside_ws,vws)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: xorigin(3)
       integer, intent(out), optional :: nvec
       integer, intent(out), optional :: vec(3,16)
       real*8, intent(out), optional :: area0(40)
       integer, intent(out), optional :: ntetrag
       real*8, allocatable, intent(inout), optional :: tetrag(:,:,:)
       integer, intent(out), optional :: nvert_ws
       integer, allocatable, intent(inout), optional :: nside_ws(:)
       integer, allocatable, intent(inout), optional :: iside_ws(:,:)
       real*8, allocatable, intent(inout), optional :: vws(:,:)
     end subroutine wigner
     module subroutine pmwigner(c,ntetrag,tetrag)
       class(crystal), intent(in) :: c
       integer, intent(out), optional :: ntetrag
       real*8, allocatable, intent(out), optional :: tetrag(:,:,:)
     end subroutine pmwigner
     module function equiv_tetrah(c,x0,t1,t2,leqv,lrotm,eps)
       logical :: equiv_tetrah
       type(crystal), intent(in) :: c
       real*8, intent(in) :: x0(3)
       real*8, dimension(0:3,3), intent(in) :: t1, t2
       integer, intent(in) :: leqv
       real*8, intent(in) :: lrotm(3,3,48), eps
     end function equiv_tetrah
     module function perm3(p,r,t)
       real*8 :: perm3(0:3,3)
       integer, intent(in) :: p
       real*8, intent(in) :: r(0:3,3), t(0:3,3)
     end function perm3
     module subroutine lattpg(rmat,ncen,xcen,nn,rot)
       real*8, intent(in) :: rmat(3,3)
       integer, intent(in) :: ncen
       real*8, intent(in) :: xcen(3,ncen)
       integer, intent(out), optional :: nn
       real*8, intent(out), optional :: rot(3,3,48)
     end subroutine lattpg
     module subroutine search_lattice(x2r,rmax,imax,jmax,kmax)
       real*8, intent(in) :: x2r(3,3), rmax
       integer, intent(out) :: imax, jmax, kmax
     end subroutine search_lattice
     module subroutine typeop(rot,type,vec,order)
       real*8, intent(in) :: rot(3,4)
       integer, intent(out) :: type
       real*8, dimension(3), intent(out) :: vec
       integer, intent(out) :: order
     end subroutine typeop
     module subroutine pointgroup_info(hmpg,schpg,holo,laue)
       character*(*), intent(in) :: hmpg
       character(len=3), intent(out) :: schpg
       integer, intent(out) :: holo
       integer, intent(out) :: laue
     end subroutine pointgroup_info
     module subroutine write_mol(c,file,fmt,ix,doborder,onemotif,molmotif,&
        environ,renv,lnmer,nmer,rsph,xsph,rcub,xcub,luout)
       class(crystal), intent(inout) :: c
       character*(*), intent(in) :: file
       character*3, intent(in) :: fmt
       integer, intent(in) :: ix(3)
       logical, intent(in) :: doborder, onemotif, molmotif, environ
       real*8, intent(in) :: renv
       logical, intent(in) :: lnmer
       integer, intent(in) :: nmer
       real*8, intent(in) :: rsph, xsph(3)
       real*8, intent(in) :: rcub, xcub(3)
       integer, intent(out), optional :: luout
     end subroutine write_mol
     module subroutine write_3dmodel(c,file,fmt,ix,doborder,onemotif,molmotif,&
        docell,domolcell,rsph,xsph,rcub,xcub,gr0)
       use graphics, only: grhandle
       class(crystal), intent(inout) :: c
       character*(*), intent(in) :: file
       character*3, intent(in) :: fmt
       integer, intent(in) :: ix(3)
       logical, intent(in) :: doborder, onemotif, molmotif
       logical, intent(in) :: docell, domolcell
       real*8, intent(in) :: rsph, xsph(3)
       real*8, intent(in) :: rcub, xcub(3)
       type(grhandle), intent(out), optional :: gr0
     end subroutine write_3dmodel
     module subroutine write_espresso(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_espresso
     module subroutine write_vasp(c,file,verbose)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
       logical, intent(in) :: verbose
     end subroutine write_vasp
     module subroutine write_abinit(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_abinit
     module subroutine write_elk(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_elk
     module subroutine write_gaussian(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_gaussian
     module subroutine write_tessel(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_tessel
     module subroutine write_critic(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_critic
     module subroutine write_cif(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_cif
     module subroutine write_d12(c,file,dosym)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
       logical, intent(in) :: dosym
     end subroutine write_d12
     module subroutine write_escher(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_escher
     module subroutine write_gulp(c,file,dodreiding)
       class(crystal), intent(inout) :: c
       character*(*), intent(in) :: file
       logical :: dodreiding
     end subroutine write_gulp
     module subroutine write_lammps(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_lammps
     module subroutine write_siesta_fdf(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_siesta_fdf
     module subroutine write_siesta_in(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_siesta_in
     module subroutine write_dftbp_hsd(c,file)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
     end subroutine write_dftbp_hsd
     module subroutine write_dftbp_gen(c,file,lu0)
       class(crystal), intent(in) :: c
       character*(*), intent(in) :: file
       integer, intent(in), optional :: lu0
     end subroutine write_dftbp_gen
     module subroutine writegrid_cube(c,g,file,onlyheader,xd0,x00)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: g(:,:,:)
       character*(*), intent(in) :: file
       logical, intent(in) :: onlyheader
       real*8, intent(in), optional :: xd0(3,3)
       real*8, intent(in), optional :: x00(3)
     end subroutine writegrid_cube
     module subroutine writegrid_vasp(c,g,file,onlyheader)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: g(:,:,:)
       character*(*), intent(in) :: file
       logical :: onlyheader
     end subroutine writegrid_vasp
     module subroutine promolecular(c,x0,f,fp,fpp,nder,zpsp,fr,periodic)
       class(crystal), intent(in) :: c
       real*8, intent(in) :: x0(3)
       real*8, intent(out) :: f
       real*8, intent(out) :: fp(3)
       real*8, intent(out) :: fpp(3,3)
       integer, intent(in) :: nder
       integer, intent(in), optional :: zpsp(:) 
       type(fragment), intent(in), optional :: fr
       logical, intent(in), optional :: periodic
     end subroutine promolecular
     module subroutine promolecular_grid(c,f,n,zpsp,fr)
       use grid3mod, only: grid3
       class(crystal), intent(in) :: c 
       type(grid3), intent(out) :: f 
       integer, intent(in) :: n(3)
       integer, intent(in), optional :: zpsp(:)  
       type(fragment), intent(in), optional :: fr
     end subroutine promolecular_grid
  end interface

contains

end module crystalmod