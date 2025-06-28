extern _l1 
extern _l2 
extern _l3 
extern _l4 
extern _k1 
extern _k2 
extern _k3 
extern _k4 
extern _il1 
extern _il2 
extern _il3 
extern _il4 
extern _ik1 
extern _ik2 
extern _ik3 
extern _ik4 

;PUBLIC  frame_count, init_copper, close_copper, cop_drop, cop_pal, do_pal
;PUBLIC	C cop_scrl, cop_start, cop_plz

section .data

;frame_count     dw      0
;cop_drop	dw	0
;cop_pal	    	dd	0
;do_pal		dw	0
;cop_start	dw	0
;cop_scrl	dw	0
;cop_plz		dw	1
extern _cop_drop
extern _cop_scrl
extern _do_pal
extern _cop_pal
extern _fadepal
extern _cop_fadepal

global _dtau
_dtau:
%assign ccc 0
%assign cccc 0
%rep 65				; 43=dy*512/dtý
	dw	ccc*ccc/4*43/128+60
%assign ccc ccc+1
%endrep

pompi   db      0

;_fadepal
fadepal		times	768*2 db 0
;
;_cop_fadepal
cop_fadepal	dd	0

;PROC	close_copper
;
;	mov	bx, 7
;	mov	ax, 0
;	mov	cx, 0
;	mov	dx, 0
;	int	0fch
;
;	mov	bx, 7
;	mov	ax, 1
;	mov	cx, 0
;	mov	dx, 0
;	int	0fch
;
;	mov	bx, 7
;	mov	ax, 2
;	mov	cx, 0
;	mov	dx, 0
;	int	0fch
;
;	ret
;ENDP
;
;PROC	init_copper
;
;	mov	bx, 7
;	mov	ax, 1
;	mov	cx, OFFSET copper1
;	mov	dx, SEG copper1
;	int	0fch
;
;	mov	bx, 7
;	mov	ax, 2
;	mov	cx, OFFSET copper2
;	mov	dx, SEG copper2
;	int	0fch
;
;	mov	bx, 7
;	mov	ax, 0
;	mov	cx, OFFSET copper3
;	mov	dx, SEG copper3
;	int	0fch
;
;	ret
;ENDP
;
;PROC	copper1
;
;	mov	dx, 03d4h
;	mov	al, 0dh
;	mov	ah, [Byte cs:cop_start]
;	out	dx, ax
;	mov	al, 0ch
;	mov	ah, [Byte cs:cop_start+1]
;	out	dx, ax
;
;	mov	dx, 3c0h
;	mov	al, 33h
;	out	dx, al
;	mov	ax, [cs:cop_scrl]
;	out	dx, al
;
;	retf
;ENDP
;
;PROC	copper2
;
;	pusha
;	push	ds
;
;	inc	[cs:frame_count]
;
;	cmp	[cs:do_pal], 0d
;	je	@@no_pal
;	lds	si, [cs:cop_pal]
;	mov	cx, 768d
;	mov	dx, 3c8h
;	mov	al, 0d
;	out	dx, al
;	inc	dx
;	rep	outsb
;	mov	[cs:do_pal], 0d
;@@no_pal:
;	cmp	[cs:cop_plz], 0d
;	je	@@l3
;	call    pompota
;	call    moveplz
;@@l3:
;	cmp	[cs:cop_drop], 0d
;	je	@@l1
;	call	do_drop
;@@l1:
;	pop	ds
;	popa
;	retf
;ENDP
;
;PROC 	copper3
;	retf
;ENDP

section .code

global _pompota
_pompota:

	mov	word [_cop_scrl], 4
	mov	dx, 3d4h
	mov	ax, 3c18h
	out	dx, ax
	mov	ax, 0f07h
	out	dx, ax			; 8th bit
	mov	ax, 3c18h
	inc     byte [pompi]
	test    byte [pompi], 1
	jz      @@l1
	mov	word [_cop_scrl], 0
	mov	ax, 3d18h
@@l1:
	out	dx, ax
	ret

global _moveplz
_moveplz:

  push ebp
	add     word [_k1], -3
	and     word [_k1], 4095
	add     word [_k2], -2
	and     word [_k2], 4095
	add     word [_k3], 1
	and     word [_k3], 4095
	add     word [_k4], 2
	and     word [_k4], 4095

	add     word [_l1], -1
	and     word [_l1], 4095
	add     word [_l2], -2
	and     word [_l2], 4095
	add     word [_l3], 2
	and     word [_l3], 4095
	add     word [_l4], 3
	and     word [_l4], 4095

	pop ebp
	ret

do_drop:

	inc	word [_cop_drop]
	cmp	word [_cop_drop], 64
	ja	@@over

	push	bx
	mov	bx, [_cop_drop]
	shl	bx, 1
	add	bx, _dtau

	mov	bx, [cs:bx]
	mov	dx, 3d4h
	mov	al, 18h		; linecompare
	mov	ah, bl
	out	dx, ax
	mov	al, 07h
	mov	ah, bh
	shl	ah, 4
	and	ah, 10h
	or	ah, 0fh
	out	dx, ax			; 8th bit

	pop	bx
	ret

@@over:
	cmp	word [_cop_drop], 256
	jae	@@end
	cmp	word [_cop_drop], 128
	jae	@@lll
	cmp	word [_cop_drop], 64+32
	ja	@@end

@@lll:	mov	word [_cop_pal], _fadepal
	mov	word [_cop_pal+2], _fadepal
	mov	word [_do_pal], 1

	cmp	word [_cop_drop], 65
	je	@@l5

	mov	dx, 3d4h
	mov	ax, 3c18h
	out	dx, ax
	mov	ax, 0f07h
	out	dx, ax			; 8th bit

	;push	ds si di cx

	lds	si, [_cop_fadepal]
	mov	di, _fadepal
	mov	cx, 768/16
@@l4:
	%assign ccc 0
	%rep 16
	mov	ax, [si+ccc*2]
	add	[cs:di+ccc+768], al
	adc	[cs:di+ccc], ah
	%assign ccc ccc+1
	%endrep
	add	di, 16
	add	si, 32
	dec	cx
	jnz	@@l4

	;pop	cx di si ds
	ret
@@l5:
	mov	dx, 3d4h
	mov	ax, 9018h
	out	dx, ax
	mov	ax, 1f07h
	out	dx, ax			; 8th bit

	call	_initpparas
	ret
@@end:
	mov	word [_cop_drop], 0
	ret

global _initpparas
_initpparas:
	push	ebp

	mov	ax, [_il1]
	mov	[_l1], ax
	mov	ax, [_il2]
	mov	[_l2], ax
	mov	ax, [_il3]
	mov	[_l3], ax
	mov	ax, [_il4]
	mov	[_l4], ax

	mov	ax, [_ik1]
	mov	[_k1], ax
	mov	ax, [_ik2]
	mov	[_k2], ax
	mov	ax, [_ik3]
	mov	[_k3], ax
	mov	ax, [_ik4]
	mov	[_k4], ax

	pop ebp
	ret