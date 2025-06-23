;/****************************************************************************
;** MODULE:	a.inc
;** AUTHOR:	Sami Tammilehto / Fennosoftec OY
;** DOCUMENT:	?
;** VERSION:	1.0
;** REFERENCE:	-
;** REVISED BY:	-
;*****************************************************************************
;**
;** Assembler / Include
;** - variable definitions
;** - constant definitions
;**
;****************************************************************************/

;######## macros ########

;note: C macros expect a LARGE memory model

%macro LOADDS 0	;loads the ds segment to point to asm_data
	mov	ax,SEG _datanull
	mov	ds,ax
%endmacro

%macro LOADES 0	;loads the es segment to point to asm_data
	mov	ax,SEG _datanull
	mov	es,ax
%endmacro

%macro LOADGS 0	;loads the gs segment to point to asm_data
	mov	ax,SEG _datanull
	mov	gs,ax
%endmacro

%macro CBEG 0 ;C/Assembler procedure begin
	push	bp
	mov	bp,sp
	push	si
	push	di
	push	ds
	LOADDS	;since all routines expect to have DS pointed to the
		;data segment, it's loaded at every public entrypoint
		;(which should all be C procedures).
%endmacro

%macro CEND 0 ;C/Assembler procedure end
	pop	ds
	pop	di
	pop	si
	pop	bp
	ret
%endmacro

%macro CBEGR 1 ; bytes ;C/Assembler procedure begin - with local variable reserve
	push	bp
	mov	bp,sp
	sub	sp,%1
	push	si
	push	di
	push	ds
	push	bp ;just in case the asm routine changes bp
	LOADDS	;since all routines expect to have DS pointed to the
		;data segment, it's loaded at every public entrypoint
		;(which should all be C procedures).
%endmacro

%macro CENDR 0 ;C/Assembler procedure end
	pop	bp
	pop	ds
	pop	di
	pop	si
	mov	sp,bp
	pop	bp
	ret
%endmacro

%macro movpar 2	;reg,par ;loads parameter [par(0..)] to register [reg]
	mov	%1,[bp+(%2)*2+6]
%endmacro
	
%macro ldspar 2	;reg,par ;loads pointer parameter [par(0..)] to register ds:[reg]
	lds	%1,[bp+(%2)*2+6]
%endmacro
	
%macro lespar 2	;reg,par ;loads pointer parameter [par(0..)] to register es:[reg]
	les	%1,[bp+(%2)*2+6]
%endmacro
	
%macro lfspar 2	;reg,par ;loads pointer parameter [par(0..)] to register fs:[reg]
	lfs	%1,[bp+(%2)*2+6]
%endmacro
	
%macro lgspar 2	;reg,par ;loads pointer parameter [par(0..)] to register gs:[reg]
	lgs	%1,[bp+(%2)*2+6]
%endmacro

%macro LOOP_LARGE 1
  loop %%notDone
  jmp %%done
  %%notDone:
  jmp %1
  %%done:
%endmacro

%macro JCXZ_LARGE 1
  cmp ecx, 0
  jz %1
%endmacro

%ifdef INCLUDE_DATA
%define DECL global
%else
%define DECL extern
%endif
%ifdef INCLUDE_CODE
%define CODEDECL extern
%else
%define CODEDECL global
%endif

;######## public routines ########

global	_vid_init
global	_vid_window
global	_vid_cameraangle
global	_vid_deinit
global	_vid_setpal
global	_vid_dotdisplay_pvlist
global	_vid_dotdisplay_zcolor
global	_vid_clear
global	_vid_clear255
global	_vid_clearbg
global	_vid_switch
global	_vid_setswitch
global	_vid_waitb
global	_vid_poly
global	_vid_pset
global	_vid_skyclear
global	_vid_drawpolylist
global	_vid_inittimer
global	_vid_deinittimer
global	_vid_drawsight
global	_vid_pic320200
;polygon fillers
;CODEDECL	_vid_drawfill
;CODEDECL	_vid_drawfill_nrm
;CODEDECL	_vid_drawfill_grd
global	_vid_drawdots

global	_calc_project
global	_calc_project16
global	_calc_setrmatrix_rotyxz
global	_calc_setrmatrix_rotxyz
global	_calc_setrmatrix_rotzyx
global	_calc_setrmatrix_ident
global	_calc_applyrmatrix
global	_calc_rotate
global	_calc_rotate16
global	_calc_sftranslate
global	_calc_singlez
global	_calc_nrotate
global	_calc_mulrmatrix
global	_calc_invrmatrix

global	_draw_polylist
global	_draw_setfillroutine

;######## constants ######## (these should be same as in CDATA.H)

%define MAXROWS			480	;maximum number of rows used in any mode
%define MAXCOLS			640	;maximum number of rows used in any mode (should be divisible with 4)
%define MAXPOLYSIDES		16	;maximum sides in a polygon

;######## variables ########
;for documentation on global variables, see adata.asm

DECL	_datanull
DECL	_rows
DECL	_rowlen
DECL	_vramseg
DECL	_cdataseg
%define CLIPMIN	0
%define CLIPMAX 4
DECL	_projclipx
DECL	_projclipy
DECL	_projclipz
DECL	_projmulx
DECL	_projmuly
DECL	_projaddx
DECL	_projaddy
DECL	_projaspect
DECL	_projoversampleshr
;equs are offsets of routine pointers inside vr for current video driver
%define PSET	0	
%define CLEAR	2
%define SWITCH	4
%define WAITB	6
%define VRSIZE	8
DECL	vr

DECL	_sintable
DECL	_avistan
DECL	_afilldiv

DECL	_polydrw

;####### data types ########

%include "ad.inc"
