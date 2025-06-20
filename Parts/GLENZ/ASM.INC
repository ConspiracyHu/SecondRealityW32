%include "adata.inc"
%include "aobj.inc"

%macro INT3 0
	int	3
	%endmacro

%MACRO LOADDS 0
;	mov	ax,SEG rows
;	mov	ds,ax
	%endmacro

%macro LOADGS 0
;	mov	ax,SEG rows
;	mov	gs,ax
	%endmacro

%macro movpar	2 ;reg,par ;loads parameter [par(0..)] to register [reg]
	mov	%1,[esp+8+%2]
	%endmacro

%macro CBEG 0	;C/Assembler procedure begin
	push	ebp
;	mov	bp,sp
;	push	si
;	push	di
;	push	ds
	%endmacro

%macro CEND 0	;C/Assembler procedure end
;	pop	ds
;	pop	di
;	pop	si
	pop	ebp
	ret
	%endmacro

%macro setborder 1
	mov	al,%1
	push	ax
;	call	_setborder
	add	sp,2
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

;LOCALS

;VID.ASM
;global setvmode
;global _setborder
%define VIDINIT	[video+0]
%define VIDSWITCH [video+4]
%define VIDCLEAR64 [video+8]
%define VIDPSET [video+12]
%define VIDLINE [video+16]
%define VIDHLINE [video+20]
%define VIDHGROUP [video+24]
%define VIDTHGROUP [video+28]
%define VIDPOLYGROUP [video+32]
%define VIDCLEAR [video+36]
%define VIDWAITB [video+40]
%define VIDNEWPOLYGROUP [video+44]
