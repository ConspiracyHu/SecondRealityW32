ALIGN 2

section .data

WMINY	dw	0
WMAXY	dw	199
WMINX	dw	0
WMAXX	dw	319

clip_x1	dw	0
clip_y1	dw	0
clip_x2	dw	0
clip_y2	dw	0
clipxy2 times	32 dw 0,0 ;tmp storage for polyclip

section .code

%macro JCXZ_LARGE 1
  cmp ecx, 0
  jz %1
%endmacro

extern polyisides
extern polysides

extern polyixy
extern polyxy

global clipanypoly
clipanypoly:
	;polyisides/polyixy =>polysides/polyxy
	mov	ax,cs
	mov	ds,ax
	mov	cx,[polyisides]
	cmp	cx,2
	jg	cap3
	cmp	cx,1
	je	cap4
	JCXZ_LARGE	cap0
	;line
	mov	eax,dword [polyixy+0]
	mov	dword [clip_x1],eax
	mov	eax,dword [polyixy+4]
	mov	dword [clip_x2],eax
cap2r:	call	clipliney
	cmp	ax,0
	jnz	cap0
	call	cliplinex
	cmp	ax,0
	jnz	cap0
	mov	eax,dword [clip_x1]
	mov	dword [polyxy+0],eax
	mov	edx,dword [clip_x2]
	mov	dword [polyxy+4],edx
	cmp	eax,edx
	je	cap2
	mov	word [polysides],2
	ret
cap2:	mov	word [polysides],1
	ret
cap4:	;dot
	mov	eax,dword [polyixy+0]
	cmp	ax,[WMINX]
	jl	cap0
	cmp	ax,[WMAXX]
	jg	cap0
	ror	eax,16
	cmp	ax,[WMINY]
	jl	cap0
	cmp	ax,[WMAXY]
	jg	cap0
	ror	eax,16
	mov	dword [polyxy],eax
	mov	word [polysides],1
	ret
cap0:	;all clipped away
	mov	word [polysides],0
	ret
cap3:	;polygon, first clip y, then x
	mov	si,cx
	shl	si,2
	sub	si,4
	mov	di,0
	mov	eax,dword [polyixy+si]
	mov	dword [clip_x1],eax
	mov	eax,dword [polyixy+di]
	mov	dword [clip_x2],eax
	call	clipliney
	;
	mov	cx,[polyisides]
	xor	di,di
	xor	bx,bx
	mov	edx,80008000h
	jmp	cap35
cap32:	push	di
	push	bx
	push	cx
	push	edx
	mov	si,di
	sub	si,4
	mov	eax,dword [polyixy+si]
	mov	dword [clip_x1],eax
	mov	eax,dword [polyixy+di]
	mov	dword [clip_x2],eax
	call	clipliney
	pop	edx
	pop	cx
	pop	bx
	pop	di
cap35:	cmp	ax,0
	jnz	cap34
	mov	eax,dword [clip_x1]
	cmp	eax,edx
	je	cap33
	mov	dword [clipxy2+bx],eax
	mov	edx,eax
	add	bx,4
cap33:	mov	eax,dword [clip_x2]
	cmp	eax,edx
	je	cap34
	mov	dword [clipxy2+bx],eax
	mov	edx,eax
	add	bx,4
cap34:	add	di,4
	loop	cap32
	;
	mov	cx,bx
	shr	cx,2
	cmp	dword [clipxy2+0],edx
	jne	cap31
	dec	cx
cap31:	mov	[polysides],cx
	
	cmp	cx,2
	jg	cap39
	cmp	cx,0
	je	cap38
	mov	eax,dword [clipxy2+0]
	mov	dword [clip_x1],eax
	mov	eax,dword [clipxy2+4]
	mov	dword [clip_x2],eax
	jmp	cap2r ;reclip the remaining line
cap38:	ret
cap39:
	mov	si,cx
	shl	si,2
	sub	si,4
	mov	di,0
	mov	eax,dword [clipxy2+si]
	mov	dword [clip_x1],eax
	mov	eax,dword [clipxy2+di]
	mov	dword [clip_x2],eax
	call	cliplinex
	;
	mov	cx,[polysides]
	xor	di,di
	xor	bx,bx
	mov	edx,80008000h
	jmp	cbp35
cbp32:	push	di
	push	bx
	push	cx
	push	edx
	mov	si,di
	sub	si,4
	mov	eax,dword [clipxy2+si]
	mov	dword [clip_x1],eax
	mov	eax,dword [clipxy2+di]
	mov	dword [clip_x2],eax
	call	cliplinex
	pop	edx
	pop	cx
	pop	bx
	pop	di
cbp35:	cmp	ax,0
	jnz	cbp34
	mov	eax,dword [clip_x1]
	cmp	eax,edx
	je	cbp33
	mov	dword [polyxy+bx],eax
	mov	edx,eax
	add	bx,4
cbp33:	mov	eax,dword [clip_x2]
	cmp	eax,edx
	je	cbp34
	mov	dword [polyxy+bx],eax
	mov	edx,eax
	add	bx,4
cbp34:	add	di,4
	loop	cbp32
	;
	mov	cx,bx
	shr	cx,2
	cmp	dword [polyxy+0],edx
	jne	cbp31
	dec	cx
cbp31:	mov	[polysides],cx

	ret


%macro clipcheck 6 ;reg,min,max,flagreg,flagmin,flagmax
	;local	l1,l2
	cmp	%1,%2
	jge	%%l1
	or	%4,%5
%%l1:	cmp	%1,%3
	jle	%%l2
	or	%4,%6
%%l2:
%endmacro

%macro clipmacro 5 ;v1,v2,w1,w2,wl
	;local	l1,l2
	push	bx
	mov	bx,%5
	mov	cx,%4
	sub	cx,%3
	jcxz	%%l1
	mov	bp,bx
	sub	bp,%3
	mov	ax,%2
	sub	ax,%1
	imul	bp 
	idiv	cx
	add	ax,%1
	mov	%1,ax
	mov	word %3,bx
	jmp	%%l2
%%l1:	mov	ax,%1
	mov	word %3,bx
%%l2:	pop	bx
%endmacro

cliplinex:
	;input line polyxy[SI]=>polyxy[DI]
	xor	bx,bx
	mov	ax,[clip_x1]
	clipcheck ax,[WMINX],[WMAXX],bl,1,2
	mov	ax,[clip_x2]
	clipcheck ax,[WMINX],[WMAXX],bh,1,2
	mov	al,bl
	and	al,bh
	jz	clpx1
	ret
clpx1:
	test	bl,1
	jz	clpx13
	clipmacro [clip_y1],[clip_y2],[clip_x1],[clip_x2],[WMINX]
clpx13:	test	bl,2
	jz	clpx14
	clipmacro [clip_y1],[clip_y2],[clip_x1],[clip_x2],[WMAXX]
clpx14:
	test	bh,1
	jz	clpx23
	clipmacro [clip_y2],[clip_y1],[clip_x2],[clip_x1],[WMINX]
clpx23:	test	bh,2
	jz	clpx24
	clipmacro [clip_y2],[clip_y1],[clip_x2],[clip_x1],[WMAXX]
clpx24:
	xor	ax,ax
	ret

clipliney:
	xor	bx,bx
	mov	ax,[clip_y1]
	clipcheck ax,[WMINY],[WMAXY],bl,4,8
	mov	ax,[clip_y2]
	clipcheck ax,[WMINY],[WMAXY],bh,4,8
	mov	al,bl
	and	al,bh
	jz	clpy1
	ret
clpy1:
	test	bl,4
	jz	clpy11
	clipmacro [clip_x1],[clip_x2],[clip_y1],[clip_y2],[WMINY]
clpy11:	test	bl,8
	jz	clpy12
	clipmacro [clip_x1],[clip_x2],[clip_y1],[clip_y2],[WMAXY]
clpy12:
	test	bh,4
	jz	clpy21
	clipmacro [clip_x2],[clip_x1],[clip_y2],[clip_y1],[WMINY]
clpy21:	test	bh,8
	jz	clpy22
	clipmacro [clip_x2],[clip_x1],[clip_y2],[clip_y1],[WMAXY]
clpy22:	
	xor	ax,ax
	ret


