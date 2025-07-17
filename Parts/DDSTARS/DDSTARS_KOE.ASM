section .DATA

global _textpic
_textpic:
incbin "TEXTS.16"

section .code

extern	_dis_partstart
extern	init_stars
extern	do_stars
extern	deinit_stars
	
%macro PLANE	1
	mov	dx,3c4h
	mov	ax,0002h+%1*100h
	out	dx,ax
%endmacro

resetmode13:
	mov	ax,13
	int	10h
	mov	dx,3dah
	in	al,dx
	mov	dx,3c0h
	xor	al,al
	%rep 16
	out	dx,al
	out	dx,al
	inc	al
	%endrep
	mov	al,11h
	out	dx,al
	mov	al,255
	out	dx,al
	mov	al,32
	out	dx,al
	;clear pal
	mov	dx,3c8h
	xor	al,al
	out	dx,al
	inc	dx
	mov	cx,768
@@clp:	out	dx,al
	loop	@@clp
	ret

outpal:
	mov	dx,3c8h
	out	dx,al
	mov	ax,cs
	mov	ds,ax
	inc	dx
	rep	outsb
	ret

waitb:
	mov	bx,1
	int	0fch
	ret

global _ddstars_main
_ddstars_main:
	mov	bx,SEG endcode
	mov	ax,es
	sub	bx,ax
	add	bx,64
        mov     ah,4ah
 	int	21h
	
	call	_dis_partstart
	
	call	resetmode13

	call	init_stars
	
	call	do_stars
	call	deinit_stars

	ret
	
;@@xit:	mov	ax,3
;	int	10h
;	mov	ax,4c00h
;	int	21h
	
section .data

stack:
	times 1024 db	 0

endcode:
	times 16 db	0
