;/****************************************************************************
;** MODULE:	ad.inc
;** AUTHOR:	Sami Tammilehto / Fennosoftec OY
;** DOCUMENT:	?
;** VERSION:	1.0
;** REFERENCE:	-
;** REVISED BY:	-
;*****************************************************************************
;**
;** Assembler / Include - THIS FILE AND CD.H SHOULD BE IN SYNC
;** - data types and related constants
;**
;****************************************************************************/

%define pvlist_x	0
%define pvlist_y	2
%define pvlist_vf	4
%define pvlist_normal 8
%define pvlist_size 16
%define pvlist_sizeshl 4	;[!!] vlist_sizeshl==pvlist_sizeshl required in many
			;places! seek for [!!] for places expecting this
%define vlist_x	0
%define vlist_y	4
%define vlist_z	8
%define vlist_normal 12
%define vlist_size 16
%define vlist_sizeshl 4 	;[!!] vlist_sizeshl==pvlist_sizeshl required in many
			;places! seek for [!!] for places expecting this
%define nlist_x	0
%define nlist_y	2
%define nlist_z	4
%define nlist_size  8
%define nlist_sizeshl 3
	
%define rmatrix_m	0
%define rmatrix_x	36
%define rmatrix_y	40
%define rmatrix_z	44
%define rmatrix_size 48

%define	unit	16384
%define	unitshr	14

%define	VF_UP	1
%define	VF_DOWN	2
%define	VF_LEFT	4
%define VF_RIGHT	8
%define VF_NEAR	16
%define VF_FAR	32

%define MAXSIDES 16

;offsets to fields inside polylist. First vertex at offset 0, next at 4 
;and so on. For example third vertices X coordinate is at [base+3*4+POLYX]
%define POLYSIDES 0
%define POLYCOLOR 2
%define POLYFLAGS 4
%define POLYVXSEG 6 ;segment
%define  POLYX (16)
%define  POLYY (16+2)
%define POLYVX (16+MAXSIDES*4) 	;offset
%define POLYGR (16+2*MAXSIDES*4)	;color
%define POLYTX (16+2*MAXSIDES*4+2)
%define POLYSIZE (16+3*MAXSIDES*4)

%define	F_DEFAULT 0f001h
%define	F_VISIBLE 00001h
%define		F_FLIP 00100h
%define		F_2SIDE 00200h
%define	F_SHADE8 00400h
%define	F_SHADE16 00800h
%define	F_SHADE32 00C00h
%define	F_GOURAUD 01000h
%define	F_TEXTURE 02000h
