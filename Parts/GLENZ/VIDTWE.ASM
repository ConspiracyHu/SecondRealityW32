;256 color tweaked routines

;routines ending in "1" are vector drawers:
;	DS:SI preserved
;	OUT 3C4,02h required
;	DS=CS & ES=vram required

;ALIGN	4
section .data
leftside db	1111b,1110b,1100b,1000b
rightside db	0001b,0011b,0111b,1111b
middledot db	0001b,0010b,0100b,1000b

;ALIGN	4
tmiddle:
	db	00010001b
	db	00100010b
	db	01000100b
	db	10001000b
tmpttt	db	0

;ALIGN 2
;line variables
xdif	dw	0
ydif	dw	0
xabs	dw	0
yabs	dw	0
xsgn	dw	0
ysgn	dw	0
xtmp	dw	0
ytmp	dw	0

tmplnx	dw	0
tmplny	dw	0


section .code
;ALIGN	4
twpset:
	;requires: OUT 3C4,2
	;DS:SI preserved, CX preserved!
	shl	bx,1
	mov	di,[rows+bx]
	mov	bx,3
	and	bx,dx
	sar	dx,2
	add	di,dx
	mov	al,[middledot+bx]
	mov	dx,3c5h
	out	dx,al
	mov	al,[color1]
	mov	[edi],al
	ret


twhline:
	;requires: OUT 3C4,2
	;DS:SI must be preserved!
	;(ax,bx)-(dx,bx)
	cmp	ax,dx
	jl	hli1
	xchg	ax,dx
hli1:	
	cmp	ax,0
	jnl	hli2
	cmp	dx,0
	jl	hli0
	xor	ax,ax
hli2:	cmp	dx,[wmaxx]
	jng	hli21
	cmp	ax,[wmaxx]
	jg	hli0
	mov	dx,[wmaxx]
	
hli21:	mov	di,ax
	sar	di,2
	mov	cx,dx
	sar	cx,2
	sub	cx,di
	shl	bx,1
	add	di,[rows+ebx]

	mov	bp,3
	and	bp,ax
	mov	bh,[leftside+ebp]
	mov	bp,3
	and	bp,dx
	mov	bl,[rightside+ebp]
	mov	dx,3c5h
	
	;(di..si,bx)
	cmp	cx,0
	je	hli30
	;left side
	mov	al,bh
	out	dx,al
	mov	al,[color1]
	stosb
	dec	cx
	mov	ah,al
	;middle
	jcxz	hli33
	mov	al,0fh
	out	dx,al
	mov	al,ah
	test	di,1
	jz	hli32
	stosb
	dec	cx
hli32:	shr	cx,1
	rep	stosw
	adc	cx,cx
	rep	stosb
hli33:	;right side
	mov	al,bl
	out	dx,al
	mov	al,ah
	mov	[edi],al
hli0:	ret
hli30:	;end and beg in same byte
	mov	al,bl
	and	al,bh
	out	dx,al
	mov	al,[color1]
	mov	[edi],al
	ret


twpsetc:
	;(dx,bx)=(color), es must be 0a000h
	;uses nothing
	push	ax
	push	bx
	push	cx
	push	dx
	mov	ch,al
	mov	cl,dl
	shl	bx,1
	mov	bx,[rows+ebx]
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
psc0:	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


twlineto:
	;draw line from (cx,ax) to (dx,bx) with color (color)
	;requires es=vram, changes: ax
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
	ja	lt4
	cmp	bx,[wmaxy]
	ja	lt4
	jmp	lt5 ;dx,bx is inside, no changes
lt4:	;dx,bx outside, swap
	xchg	bx,[tmplny]
	xchg	dx,[tmplnx]
	;check with new bx,dx
	cmp	dx,wmaxx
	ja	lt6
	cmp	bx,wmaxy
	ja	lt6
	jmp	lt5 ;dx,bx is inside

lt6:	;both ends outside! Cut 'em here, not ready yet

lt5:	mov	[xtmp],dx
	mov	[ytmp],bx
	;calc differencies xdif,ydif (+-) & abs difs, xabs,yabs (+)
	;and signs xsgn,ysgn (-1/0/1)
	xor	cx,cx
	mov	ax,[tmplnx]
	sub	ax,dx
	mov	[xdif],ax
	or	ax,ax
	je	lt1
	inc	cx
	test	ax,32768
	jz	lt1
	neg	ax
	dec	cx
	dec	cx
lt1:	mov	[xabs],ax
	mov	[xsgn],cx

	xor	cx,cx
	mov	ax,[tmplny]
	sub	ax,bx
	mov	[ydif],ax
	or	ax,ax
	je	lt2
	inc	cx
	test	ax,32768
	jz	lt2
	neg	ax
	dec	cx
	dec	cx
lt2:	mov	[yabs],ax
	mov	[ysgn],cx

	;which is bigger?
	cmp	ax,[xabs]
	ja	lt3

	;xbigger

	;calc addl/h (si,di)
	jne	lt9
	;1/1 addition, 45 degree curve
	cmp	ax,0
	jne	lt15
	mov	dx,[tmplnx]
	mov	bx,[tmplny]
	call	twpsetc
	jmp	lt10
lt15:	mov	di,[ysgn]
	mov	si,65535
	jmp	lt10
lt9:	mov	dx,ax ;dx=yabs
	xor	ax,ax
	div	word [xabs] ;ax=lowadd
	mov	si,ax
	mov	di,[ysgn]

lt10:	mov	ax,32767
	mov	bp,[xsgn]
	mov	cx,[xabs]
	inc	cx
	mov	dx,[xtmp]
	mov	bx,[ytmp]
lt7:	call	twpsetc
	add	dx,bp ;xsgn
	add	ax,si ;yaddl
	jnc	lt8
	add	bx,di ;ysgn
lt8:	loop	lt7

	jmp	lt0


lt3:	;ybigger

	mov	dx,[xabs]
	xor	ax,ax
	div	word [yabs] ;ax=lowadd
	mov	si,ax
	mov	di,[xsgn]

lt12:	mov	ax,32767
	mov	bp,[ysgn]
	mov	cx,[yabs]
	inc	cx
	mov	dx,[xtmp]
	mov	bx,[ytmp]
lt13:	call	twpsetc
	add	bx,bp ;ysgn
	add	ax,si ;xaddl
	jnc	lt14
	add	dx,di ;xsgn
lt14:	loop	lt13
	
lt0:	pop	bx
	pop	dx
	mov	[tmplnx],dx
	mov	[tmplny],bx
	pop	bp
	pop	di
	pop	si
	pop	cx
	ret


twhlinegroup:
	;requires: OUT 3C4,2
	mov	dx,3c4h
	mov	al,2
	out	dx,al
	
	mov	bx,[esi]
	add	si,2	
	dec	bx
	push	bx
	
hlg92:	pop	bx
	inc	bx
	push	bx
	mov	ax,[esi]
	add	si,2
	cmp	ax,-32767
	jne	hlg91
	pop	bx
	ret
hlg91:	mov	dx,ax
	mov	ax,[esi]
	add	si,2
	
	cmp	ax,dx
	jl	hlg1
	xchg	ax,dx
hlg1:	
	cmp	ax,[wminx]
	jnl	hlg2
	cmp	dx,[wminx]
	jl	hlg0
	mov	ax,[wminx]
hlg2:	cmp	dx,[wmaxx]
	jng	hlg21
	cmp	ax,[wmaxx]
	jg	hlg0
	mov	dx,[wmaxx]
	
hlg21:	mov	di,ax
	sar	di,2
	mov	cx,dx
	sar	cx,2
	sub	cx,di
	shl	bx,1
	add	di,[rows+ebx]

	mov	bp,3
	and	bp,ax
	mov	bh,[leftside+ebp]
	mov	bp,3
	and	bp,dx
	mov	bl,[rightside+ebp]
	mov	dx,3c5h
	
	;(di..si,bx)
	cmp	cx,0
	je	hlg30
	;left side
	mov	al,bh
	out	dx,al
	mov	al,[color1]
	stosb
	dec	cx
	mov	ah,al
	;middle
	jcxz	hlg33
	mov	al,0fh
	out	dx,al
	mov	al,ah
	test	di,1
	jz	hlg32
	stosb
	dec	cx
hlg32:	shr	cx,1
	rep	stosw
	adc	cx,cx
	rep	stosb
hlg33:	;right side
	mov	al,bl
	out	dx,al
	mov	al,ah
	mov	[edi],al
hlg0:	jmp	hlg92
hlg30:	;end and beg in same byte
	mov	al,bl
	and	al,bh
	out	dx,al
	mov	al,[color1]
	mov	[edi],al
	jmp	hlg92


twthlinegroup:
	;requires: OUT 3C4,2
	mov	dx,3c4h
	mov	al,2
	out	dx,al

	mov	bx,[esi]
	add	si,2	
	dec	bx
	jmp	thlg93
thlg92:	pop	bx
	add	si,8
thlg93:	inc	bx
	push	bx
	mov	dx,[esi] ;left
	cmp	dx,-32767
	jne	thlg91
	pop	bx
	ret
thlg91:	mov	ax,[esi+2] ;right
	
	cmp	ax,dx
	jl	thlg1
	xchg	ax,dx
	mov	cx,[esi+4]
	xchg	cx,[esi+6]
	mov	[esi+4],cx
thlg1:	
	cmp	ax,[wminx]
	jnl	thlg2
	cmp	dx,[wminx]
	jl	thlg92
	mov	ax,[wminx]
thlg2:	cmp	dx,[wmaxx]
	jng	thlg21
	cmp	ax,[wmaxx]
	jg	thlg92
	mov	dx,[wmaxx]
	
thlg21:	mov	cx,dx
	sub	cx,ax
	jcxz	thlg92
	mov	di,ax
	shr	di,2
	shl	bx,1
	add	di,[rows+ebx]

	mov	bx,ax
	and	bx,3
	mov	bp,cx ;count
	mov	al,[tmiddle+ebx]
	mov	[tmpttt],al
	
	mov	ah,[esi+4] ;endx
	xor	al,al
	sub	ah,[esi+6] ;startx
	cwd
	idiv	bp
	rol	edi,16
	mov	cl,ah
	mov	ah,al
	xor	al,al
	mov	di,ax ;xadd
	rol	edi,16

	mov	ah,[esi+5] ;endy
	xor	al,al
	sub	ah,[esi+7] ;starty
	cwd
	idiv	bp

	mov	dh,al ;yadd
	xor	dl,dl
	shl	edx,16
	mov	dh,ah
	mov	dl,cl
	cmp	dl,0
	jge	thlg31
	dec	dh
thlg31:
	
	movzx	ebx,word [esi+6] ;startxy/zero ylow
	xor	ecx,ecx	;zero xlow
	
	;....Exx..H....L....
	;ax  -    -    <R>
	;bx  ylow y    x     
	;cx  xlow -    tmp
	;dx  yadd yah  xah
	;si  -    -    -     
	;di  xadd distbase   
	;bp  -    -    -     <=tmp reserved for count   
	mov	al,[tmpttt]
thlg82:	;
	add	ecx,edi
	mov	cl,[ebx]
	adc	ebx,edx
	adc	bh,0
	;
	push	dx
	mov	dx,3c5h
	out	dx,al
	mov	[edi],cl
	rol	al,1
	adc	di,0
	pop	dx
	;
	dec	bp
	jnz	thlg82
thlg0:	jmp	thlg92

