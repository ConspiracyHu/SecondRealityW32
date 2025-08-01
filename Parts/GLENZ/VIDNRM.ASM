;256 color normal routines

;routines ending in "1" are vector drawers:
;	DS:SI preserved
;	OUT 3C4,02h required
;	DS=CS & ES=vram required

;ALIGN	4
nrpset:
	;requires: OUT 3C4,2
	;DS:SI preserved, CX preserved!
	shl	bx,1
	mov	di,[glenz_rows+ebx]
	mov	bx,3
	and	bx,dx
	sar	dx,2
	add	di,dx
	mov	al,[middledot+ebx]
	mov	dx,3c5h
	out	dx,al
	mov	al,[color1]
	mov	[edi],al
	ret


nrhline:
	;requires: OUT 3C4,2
	;DS:SI must be preserved!
	;(ax,bx)-(dx,bx)
	cmp	ax,dx
	jl	nrhi1
	xchg	ax,dx
nrhi1:	
	cmp	ax,0
	jnl	nrhi2
	cmp	dx,0
	jl	nrhi0
	xor	ax,ax
nrhi2:	cmp	dx,[wmaxx]
	jng	nrhi21
	cmp	ax,[wmaxx]
	jg	nrhi0
	mov	dx,[wmaxx]
	
nrhi21:	mov	di,ax
	sar	di,2
	mov	cx,dx
	sar	cx,2
	sub	cx,di
	shl	bx,1
	add	di,[glenz_rows+ebx]

	mov	bp,3
	and	bp,ax
	mov	bh,[leftside+ebp]
	mov	bp,3
	and	bp,dx
	mov	bl,[rightside+ebp]
	mov	dx,3c5h
	
	;(di..si,bx)
	cmp	cx,0
	je	nrhi30
	;left side
	mov	al,bh
	out	dx,al
	mov	al,[color1]
	stosb
	dec	cx
	mov	ah,al
	;middle
	jcxz	nrhi33
	mov	al,0fh
	out	dx,al
	mov	al,ah
	test	di,1
	jz	nrhi32
	stosb
	dec	cx
nrhi32:	shr	cx,1
	rep	stosw
	adc	cx,cx
	rep	stosb
nrhi33:	;right side
	mov	al,bl
	out	dx,al
	mov	al,ah
	mov	[edi],al
nrhi0:	ret
nrhi30:	;end and beg in same byte
	mov	al,bl
	and	al,bh
	out	dx,al
	mov	al,[color1]
	mov	[edi],al
	ret


;line variables - shared - also in vidtwe.asm
;xdif	dw	0
;ydif	dw	0
;xabs	dw	0
;yabs	dw	0
;xsgn	dw	0
;ysgn	dw	0
;xtmp	dw	0
;ytmp	dw	0
;tmplnx	dw	0
;tmplny	dw	0

nrpsetc:
	;(dx,bx)=(color), es must be 0a000h
	;uses nothing
	push	ax
	push	bx
	push	cx
	push	dx
	mov	ch,al
	mov	cl,dl
	shl	bx,1
	mov	bx,[glenz_rows+ebx]
	sar	dx,1
	sar	dx,1
	add	bx,dx
	and	cl,3
	mov	ax,102h
	mov	dx,03c4h
	shl	ah,cl
	out	dx,ax
	mov	al,[color1]
	mov	[ebx],al
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


nrlineto:
	;draw line from (cx,ax) to (dx,bx) with color (color)
	;requires ds=cs, es=vram, changes: ax
	push	cx
	push	si
	push	di
	push	bp
	push	dx
	push	bx
	
	mov	[tmplnx],cx
	mov	[tmplny],ax

	;set insider point as begin of line
	cmp	dx,[wmaxx]
	ja	nrlt4
	cmp	bx,[wmaxy]
	ja	nrlt4
	jmp	nrlt5 ;dx,bx is inside, no changes
nrlt4:	;dx,bx outside, swap
	xchg	bx,[tmplny]
	xchg	dx,[tmplnx]
	;check with new bx,dx
	cmp	dx,[wmaxx]
	ja	nrlt6
	cmp	bx,[wmaxy]
	ja	nrlt6
	jmp	nrlt5 ;dx,bx is inside

nrlt6:	;both ends outside! Cut 'em here, not ready yet

nrlt5:	mov	[xtmp],dx
	mov	[ytmp],bx
	;calc differencies xdif,ydif (+-) & abs difs, xabs,yabs (+)
	;and signs xsgn,ysgn (-1/0/1)
	xor	cx,cx
	mov	ax,[tmplnx]
	sub	ax,dx
	mov	[xdif],ax
	or	ax,ax
	je	nrlt1
	inc	cx
	test	ax,32768
	jz	nrlt1
	neg	ax
	dec	cx
	dec	cx
nrlt1:	mov	[xabs],ax
	mov	[xsgn],cx

	xor	cx,cx
	mov	ax,[tmplny]
	sub	ax,bx
	mov	[ydif],ax
	or	ax,ax
	je	nrlt2
	inc	cx
	test	ax,32768
	jz	nrlt2
	neg	ax
	dec	cx
	dec	cx
nrlt2:	mov	[yabs],ax
	mov	[ysgn],cx

	;which is bigger?
	cmp	ax,[xabs]
	ja	nrlt3

	;xbigger

	;calc addl/h (si,di)
	jne	nrlt9
	;1/1 addition, 45 degree curve
	cmp	ax,0
	jne	nrlt15
	mov	dx,[tmplnx]
	mov	bx,[tmplny]
	call	nrpsetc
	jmp	nrlt10
nrlt15:	mov	di,[ysgn]
	mov	si,65535
	jmp	nrlt10
nrlt9:	mov	dx,ax ;dx=yabs
	xor	ax,ax
	div	word [xabs] ;ax=lowadd
	mov	si,ax
	mov	di,[ysgn]

nrlt10:	mov	ax,32767
	mov	bp,[xsgn]
	mov	cx,[xabs]
	inc	cx
	mov	dx,[xtmp]
	mov	bx,[ytmp]
nrlt7:	call	nrpsetc
	add	dx,bp ;xsgn
	add	ax,si ;yaddl
	jnc	nrlt8
	add	bx,di ;ysgn
nrlt8:	loop	nrlt7

	jmp	nrlt0


nrlt3:	;ybigger

	mov	dx,[xabs]
	xor	ax,ax
	div	word [yabs] ;ax=lowadd
	mov	si,ax
	mov	di,[xsgn]

nrlt12:	mov	ax,32767
	mov	bp,[ysgn]
	mov	cx,[yabs]
	inc	cx
	mov	dx,[xtmp]
	mov	bx,[ytmp]
nrlt13:	call	nrpsetc
	add	bx,bp ;ysgn
	add	ax,si ;xaddl
	jnc	nrlt14
	add	dx,di ;xsgn
nrlt14:	loop	nrlt13
	
nrlt0:	pop	bx
	pop	dx
	mov	[tmplnx],dx
	mov	[tmplny],bx
	pop	bp
	pop	di
	pop	si
	pop	cx
	ret


nrhlinegroup:
	;requires: OUT 3C4,2
	mov	dx,3c4h
	mov	al,2
	out	dx,al
	
	mov	bx,[esi]
	add	si,2	
	dec	bx
	push	bx
	
nrhg92:	pop	bx
	inc	bx
	push	bx
	mov	ax,[esi]
	add	si,2
	cmp	ax,-32767
	jne	nrhg91
	pop	bx
	ret
nrhg91:	mov	dx,ax
	mov	ax,[esi]
	add	si,2
	
	cmp	ax,dx
	jl	nrhg1
	xchg	ax,dx
nrhg1:	
	cmp	ax,[wminx]
	jnl	nrhg2
	cmp	dx,[wminx]
	jl	nrhg92
	mov	ax,[wminx]
nrhg2:	cmp	dx,[wmaxx]
	jng	nrhg21
	cmp	ax,[wmaxx]
	jg	nrhg92
	mov	dx,[wmaxx]
	
nrhg21:	mov	di,ax
	mov	cx,dx
	sub	cx,ax
	shl	bx,1
	add	di,[glenz_rows+ebx]
	mov	al,[color1]
	mov	ah,al
	
	cmp	cx,8
	jl	nrhg22

	mov	dx,ax
	shl	eax,16
	mov	ax,dx
	
	mov	dx,cx
	mov	cx,4
	sub	cx,di
	and	cx,3
	sub	dx,cx
	rep	stosb
	mov	cx,dx
	shr	cx,2
	rep	stosd
	mov	cx,dx
	and	cx,3
	rep	stosb
	jmp	nrhg92
	
nrhg22:	shr	cx,1
	rep	stosw
	adc	cx,cx
	rep	stosb
	jmp	nrhg92


;ALIGN 2
bpmultable:
dw	0
%assign cc 1
%rep 255
dw	(16383)/cc
%assign cc cc+1
%endrep

global _dimtable
_dimtable times 256 db 1

;ALIGN 2
tmpax	dw	0

nrthlinegroup:
	;requires: OUT 3C4,2
	mov	dx,3c4h
	mov	al,2
	out	dx,al

	mov	bx,[esi]
	add	si,2	
	dec	bx
	jmp	tnrg93
tnrg92:	pop	bx
	add	si,8
tnrg93:	inc	bx
	push	bx
	mov	dx,[esi] ;left
	cmp	dx,-32767
	jne	tnrg91
	pop	bx
	ret
tnrg91:	mov	ax,[esi+2] ;right
	
	cmp	ax,dx
	jl	tnrg1
	xchg	ax,dx
	mov	cx,[esi+4]
	xchg	cx,[esi+6]
	mov	[esi+4],cx
tnrg1:	
	cmp	ax,[wminx]
	jnl	tnrg2
	cmp	dx,[wminx]
	jl	tnrg92
	mov	ax,[wminx]
tnrg2:	cmp	dx,[wmaxx]
	jng	tnrg21
	cmp	ax,[wmaxx]
	jg	tnrg92
	mov	dx,[wmaxx]
	
tnrg21:	mov	[tmpax],ax
	mov	cx,dx
	sub	cx,ax
	jcxz	tnrg92
	shl	bx,1
	mov	di,[glenz_rows+ebx]

	mov	bp,cx ;count
	
	shl	bp,1
	mov	bx,word [bpmultable+ebp]
	shr	bp,1

	mov	ah,[esi+4] ;endx
	sub	ah,[esi+6] ;startx
	xor	al,al
	imul	bx
	shld	dx,ax,2
	;dx=y, eaxh=x
	mov	cl,dh
	mov	ah,dl
	xor	al,al
	rol	eax,16 ;xadd

	mov	ah,[esi+5] ;endy
	sub	ah,[esi+7] ;starty
	xor	al,al
	imul	bx
	shld	dx,ax,2
	mov	ch,dh
	mov	dh,dl ;yadd
	xor	dl,dl
	rol	edx,16
	mov	dx,cx
	cmp	dl,80h
	adc	dh,-1 ;x/yaddhi

	push	si
	push	ds
	mov	ax,fs
	mov	ds,ax
	
	shl	bp,4
	mov	bx,[tmpax]
	shl	bx,4
	add	ebx,bas256
	add	bp,bx
	mov	ax,bx
	mov	byte [ebp],0c3h ;ret
	push	bp
	movzx	ebx,word [esi+6] ;startxy/zero ylow
	xor	ecx,ecx	;zero xlow
	call	ax
	pop	bx
	mov	byte [ebx],066h ;start of add ecx,eax
	
	pop	ds
	pop	si
	jmp	tnrg92

	;....Exx..H....L....
	;ax  xadd -    tmp
	;bx  ylow y    x  
	;cx  xlow -    -
	;dx  yadd yah  xah
	;si  -    -    -
	;di  -    distbase
	;bp  -    -    -

ALIGN 16
bas256:
  %assign cc 0	
	%rep 256
	add	ecx,eax		;@0
	mov	al,[ebx]	;@3
	adc	ebx,edx		;@5
	adc	bh,0		;@8
	;db	26h,88h,85h	;@B ;mov es:[di+XXX],al
	;dw	cc		;@E ;XXX
  mov [edi+cc],al
	%assign cc cc+1			;@10
	%endrep
	add	ecx,eax

