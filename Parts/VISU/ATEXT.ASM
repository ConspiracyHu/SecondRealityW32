section .data

global _prtt
global _txtx
global _txty
global _prttcol
_txtx	dw	0
_txty	dw	0
_prttcol dw	0
global _font3x5
_font3x5 dw	0,0
truerowsadd dw	0

%macro prtmacro 0
	;local	prt41,prt42,prt43,prt44,prt45
	push	di
	out	dx,al
	mov	al,byte [_prttcol]
	rcr	bl,1
	jnc	%%prt41
	mov	[edi],al
%%prt41:	add	di,[truerowsadd]
	rcr	bh,1
	jnc	%%prt42
	mov	[edi],al
%%prt42:	add	di,[truerowsadd]
	rcr	cl,1
	jnc	%%prt43
	mov	[edi],al
%%prt43:	add	di,[truerowsadd]
	rcr	ch,1
	jnc	%%prt44
	mov	[edi],al
%%prt44:	add	di,[truerowsadd]
	rcr	ah,1
	jnc	%%prt45
	mov	[edi],al
%%prt45:	pop	di
%endmacro

_prtt:
	CBEG
	call	vidstart
	mov	ax,[_rowlen]
	mov	[truerowsadd],ax
	mov	fs,[_font3x5+2]
	movpar	ds,1
	movpar	si,0
	mov	di,[_txty]
	mov	ax,[truerowsadd]
	mul	di
	mov	di,ax
	mov	dx,[_txtx]
	shr	dx,2
	add	di,dx
	mov	dx,3c4h
	mov	al,02h
	out	dx,al
	inc	dx
	xor	bp,bp ;cnt

	mov	cx,256
prt3:	lodsb
	cmp	al,9 ;tab
	je	prt21
	cmp	al,0
	je	prt1x
	cmp	al,31
	ja	prt2
prt22:	jmp	prt10
prt1x:	jmp	prt1
prt21:	inc	bp
	inc	di
	test	bp,7
	jz	prt22
	jmp	prt21
prt2:	inc	bp
	push	cx
	mov	bl,al
	xor	bh,bh
	shl	bx,3
	mov	ah,[ebx+4]
	mov	cx,[ebx+2]
	mov	bx,[ebx+0]
	mov	al,01h
	prtmacro
	mov	al,02h
	prtmacro
	mov	al,04h
	prtmacro
	inc	di
	inc	word [_txtx]
	pop	cx
prt10:	dec	cx
	jz	prt1
	jmp	prt3
prt1:	CEND


