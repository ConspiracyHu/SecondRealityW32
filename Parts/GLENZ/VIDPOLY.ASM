;borders - can be found in asm.asm at the tmp work area (size 8K = 1024 rows)
;ALIGN 4

section .data

global _polyinfo
_polyinfo:
polysides dw	0		;polygon sides 
polyxy	times	32 dw 0,0	;x1,y1,x2,y2,...
polyz	times	32 dd 0	;z1,z2,...
polytxy	times	32 dw 0,0	;texturexy
POLYZ	equ	polyz-polyxy
POLYTXY	equ	polytxy-polyxy
;clipped from polyclip
cpolyxy	 times	32 dw 0,0
cpolyxy2 times	32 dw 0,0 ;tmp storage for polyclip
cpolysides dw	0

clip_x1	dw	0
clip_y1	dw	0
clip_x2	dw	0
clip_y2	dw	0

polyroutines:
	dd	polyret
	dd	poly1
	dd	poly2
	dd	polyf ;poly3
	dd	polyf ;poly4 ;poly4
	dd	polyf ;polyn ;poly>4

%IF 0
tpolyroutines:
	dd	polyret
	dd	poly1
	dd	poly2
	dd	polyft
	dd	polyft
	dd	polyft
%ENDIF

section .code

polygroup: ;draw polygon group
	;es:di=pointer to polygon group:
	;	word: sides (0=end of list, &256=texture)
	;	word: color (|8000=hidden |4000=forceshow)
	;	word(s): x,y
.@@1:	mov	cx,[edi]
	add	edi,2
	or	cx,cx
	jz	.@@3
	mov	[polysides],cx
	mov	ax,[edi]
	add	edi,2
	test	ah,40h
	jnz	.@@6
	test	ah,80h
	jnz	.@@5
.@@6:	mov	[color1],al
	mov	ebx,polyxy
	sub	ebx,edi
	sub	ebx,4
.@@2:	mov	eax,[edi]
	add	di,4
	mov	[edi+ebx],eax
	loop	.@@2
	push	es
	push	di
	call	poly
	pop	di
	pop	es
	jmp	.@@1
.@@3:	ret
.@@5:	shl	cx,2
	add	di,cx
	jmp	.@@1


poly: ;****
	mov	dx,3c4h
	mov	al,2
	out	dx,al
	mov	es,[vram]
	mov	ax,[polysides]
	mov	[cpolysides],ax
	cmp	ax,2
	ja	noclip
	call	clipanypoly ;only lines at the moment, others done by polyrout
noclip:	mov	esi,polyroutines
;	test	cs:groupflags,4
;	jz	notext
;	mov	si,OFFSET tpolyroutines
notext:	mov	bx,[cpolysides]
	cmp	bx,5
	jb	ply1
	jmp	[esi+10]
ply1:	shl	bx,1
	jmp	[esi+ebx]
polyret: ret


;***** POLYGON CLIP


clipanypoly:
	;polysides/polyxy => cpolysides/cpolyxy
	mov	cx,[polysides]
	cmp	cx,2
	jg	cap3
	cmp	cx,1
	je	cap4
	JCXZ_LARGE	cap0
	;line
	mov	eax,dword [polyxy+0]
	mov	dword [clip_x1],eax
	mov	eax,dword [polyxy+4]
	mov	dword [clip_x2],eax
cap2r:	call	clipliney
	cmp	ax,0
	jnz	cap0
	call	cliplinex
	cmp	ax,0
	jnz	cap0
	mov	eax,dword [clip_x1]
	mov	dword [cpolyxy+0],eax
	mov	edx,dword [clip_x2]
	mov	dword [cpolyxy+4],edx
	cmp	eax,edx
	je	cap2
	mov	word [cpolysides],2
	ret
cap2:	mov	word [cpolysides],1
	ret
cap4:	;dot
	mov	eax,dword [polyxy+0]
	cmp	ax,[wminx]
	jl	cap0
	cmp	ax,[wmaxx]
	jg	cap0
	ror	eax,16
	cmp	ax,[wminy]
	jl	cap0
	cmp	ax,[wmaxy]
	jg	cap0
	ror	eax,16
	mov	dword [cpolyxy],eax
	mov	word [cpolysides],1
	ret
cap0:	;all clipped away
	mov	word [cpolysides],0
	ret
cap3:	;polygon, first clip y, then x
	mov	si,cx
	shl	si,2
	sub	si,4
	mov	di,0
	mov	eax,dword [polyxy+esi]
	mov	dword [clip_x1],eax
	mov	eax,dword [polyxy+edi]
	mov	dword [clip_x2],eax
	call	clipliney
	;
	mov	cx,[polysides]
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
	mov	eax,dword [polyxy+esi]
	mov	dword [clip_x1],eax
	mov	eax,dword [polyxy+edi]
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
	mov	dword [cpolyxy2+ebx],eax
	mov	edx,eax
	add	bx,4
cap33:	mov	eax,dword [clip_x2]
	cmp	eax,edx
	je	cap34
	mov	dword [cpolyxy2+ebx],eax
	mov	edx,eax
	add	bx,4
cap34:	add	di,4
	loop	cap32
	;
	mov	cx,bx
	shr	cx,2
	cmp	dword [cpolyxy2+0],edx
	jne	cap31
	dec	cx
cap31:	mov	[cpolysides],cx
	
	cmp	cx,2
	jg	cap39
	cmp	cx,0
	je	cap38
	mov	eax,dword [cpolyxy2+0]
	mov	dword [clip_x1],eax
	mov	eax,dword [cpolyxy2+4]
	mov	dword [clip_x2],eax
	jmp	cap2r ;reclip the remaining line
cap38:	ret
cap39:
	mov	si,cx
	shl	si,2
	sub	si,4
	mov	di,0
	mov	eax,dword [cpolyxy2+esi]
	mov	dword [clip_x1],eax
	mov	eax,dword [cpolyxy2+edi]
	mov	dword [clip_x2],eax
	call	cliplinex
	;
	mov	cx,[cpolysides]
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
	mov	eax,dword [cpolyxy2+esi]
	mov	dword [clip_x1],eax
	mov	eax,dword [cpolyxy2+edi]
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
	mov	dword [cpolyxy+ebx],eax
	mov	edx,eax
	add	bx,4
cbp33:	mov	eax,dword [clip_x2]
	cmp	eax,edx
	je	cbp34
	mov	dword [cpolyxy+ebx],eax
	mov	edx,eax
	add	bx,4
cbp34:	add	di,4
	loop	cbp32
	;
	mov	cx,bx
	shr	cx,2
	cmp	dword [cpolyxy+0],edx
	jne	cbp31
	dec	cx
cbp31:	mov	[cpolysides],cx

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
	;input line cpolyxy[SI]=>cpolyxy[DI]
	xor	bx,bx
	mov	ax,[clip_x1]
	clipcheck ax,[wminx],[wmaxx],bl,1,2
	mov	ax,[clip_x2]
	clipcheck ax,[wminx],[wmaxx],bh,1,2
	mov	al,bl
	and	al,bh
	jz	clpx1
	ret
clpx1:
	test	bl,1
	jz	clpx13
	clipmacro [clip_y1],[clip_y2],[clip_x1],[clip_x2],[wminx]
clpx13:	test	bl,2
	jz	clpx14
	clipmacro [clip_y1],[clip_y2],[clip_x1],[clip_x2],[wmaxx]
clpx14:
	test	bh,1
	jz	clpx23
	clipmacro [clip_y2],[clip_y1],[clip_x2],[clip_x1],[wminx]
clpx23:	test	bh,2
	jz	clpx24
	clipmacro [clip_y2],[clip_y1],[clip_x2],[clip_x1],[wmaxx]
clpx24:
	xor	ax,ax
	ret

clipliney:
	xor	bx,bx
	mov	ax,[clip_y1]
	clipcheck ax,[wminy],[wmaxy],bl,4,8
	mov	ax,[clip_y2]
	clipcheck ax,[wminy],[wmaxy],bh,4,8
	mov	al,bl
	and	al,bh
	jz	clpy1
	ret
clpy1:
	test	bl,4
	jz	clpy11
	clipmacro [clip_x1],[clip_x2],[clip_y1],[clip_y2],[wminy]
clpy11:	test	bl,8
	jz	clpy12
	clipmacro [clip_x1],[clip_x2],[clip_y1],[clip_y2],[wmaxy]
clpy12:
	test	bh,4
	jz	clpy21
	clipmacro [clip_x2],[clip_x1],[clip_y2],[clip_y1],[wminy]
clpy21:	test	bh,8
	jz	clpy22
	clipmacro [clip_x2],[clip_x1],[clip_y2],[clip_y1],[wmaxy]
clpy22:	
	xor	ax,ax
	ret


;***** POLYGON DRAW

poly1:
	mov	dx,[cpolyxy+0]
	mov	bx,[cpolyxy+2]
	call	VIDPSET
	ret


poly2:
	mov	cx,[cpolyxy+0]
	mov	ax,[cpolyxy+2]
	mov	dx,[cpolyxy+4]
	mov	bx,[cpolyxy+6]
	call	VIDLINE
	ret


;*** POLYF / POLYFT

ALIGN 4
feax	dd	0
fedx	dd	0

fleftaddl dd	0 ;+0
fleftaddh dw	0 ;+4
fleftrown dw	0 ;+6
fleftzb dd	0 ;+8
fleftze dd	0 ;+12
flefttx0 dw	0 ;+16
fleftty0 dw	0 ;+18
flefttxa dw	0 ;+20
flefttya dw	0 ;+22
fleftcnt dw	0 ;+24
fleftcnta dw	0 ;+26
fleftd3a dw	0 ;+28

frightaddl dd	0 ;+0
frightaddh dw	0 ;+4
frightrown dw	0 ;+6
frightzb dd	0 ;+8
frightze dd	0 ;+12
frighttx0 dw	0 ;+16
frightty0 dw	0 ;+18
frighttxa dw	0 ;+20
frighttya dw	0 ;+22
frightcnt dw	0 ;+24
frightcnta dw	0 ;+26
frightd3a dw	0 ;+28

finfolen dw	0
finfo0 dw	0
finfo1 dw	0
fwmaxy1 dw 	0

finfo	times	32 dw 0,0,0,0,0,0,0,0
		;x,y,zlo,zhi,tx,ty,0,0

polyf: ;ONLY CONVEX POLYGONS - FAST?
	;input: polysides/polyxy
	;requirements:
	;es=vram
	;cpolysides>=4 (not checked)
	;color=set
	;**COPY/SEEK UPPERMOST**
	LOADGS
	mov	ax,cs
	mov	ds,ax
	mov	cx,[polysides]
	mov	ax,cx
	shl	ax,4 ;*16
	mov	[finfolen],ax
	add	eax,finfo
	mov	[finfo1],ax
	mov	ax,[wmaxy]
	inc	ax
	mov	[fwmaxy1],ax
	mov	edx,077770000h
	xor	bx,bx
	mov	esi,polyxy
	mov	edi,finfo
	mov	[finfo0],di
pfn1:	mov	eax,dword [esi]
	cmp	eax,edx
	jg	pfn2
	mov	edx,eax
	mov	bx,di
pfn2:	mov	dword [edi],eax
	add	si,4
	add	di,16
	loop	pfn1
	;[bx]=uppermost
	;**SETUP REGS**
	mov	word [fleftrown],-32767
	mov	word [frightrown],-32767
	mov	si,bx
	mov	di,bx
	mov	bp,[esi+2]
	mov	ebx,borders
	mov	ax,bp
	cmp	ax,[wminy]
	jge	pfn35
	mov	ax,[wminy]
pfn35:	mov	[ebx],ax
	add	bx,2
	mov	cx,16 ;max tmp count to avoid hanging on illegal polygons
	;eax=left
	;bx=pointer to borders[]
	;cx=count
	;edx=right
	;si=left
	;di=right
	;bp=y
pfn63:	push	cx
	push	bx
	
	cmp	bp,[fleftrown]
	jl	pfn42
	push	edx
	push	di
	mov	di,si
	sub	di,16
	cmp	di,[finfo0]
	jae	pfn41
	add	di,[finfolen]
pfn41:	mov	ebx,fleftaddl
	call	polyfcalc
	add	cx,bp
	mov	[fleftrown],cx
	movzx	eax,word [esi+0]
	mov	ebx,[fleftaddl]
	mov	dx,[fleftaddh]
	sar	dx,1
	rcr	ebx,1
	xor	bx,bx
	sub	eax,ebx
	sbb	ax,dx
	mov	si,di
	pop	di
	pop	edx
pfn42:
	cmp	bp,[frightrown]
	jl	pfn52
	push	eax
	push	si
	mov	si,di
	add	di,16
	cmp	di,[finfo1]
	jb	pfn51
	sub	di,[finfolen]
pfn51:	mov	ebx,frightaddl
	call	polyfcalc
	add	cx,bp
	mov	[frightrown],cx
	movzx	edx,word [esi+0]
	mov	ebx,[frightaddl]
	mov	ax,[frightaddh]
	sar	ax,1
	rcr	ebx,1
	xor	bx,bx
	sub	edx,ebx
	sbb	dx,ax
	pop	si
	pop	eax
	
pfn52:	mov	bx,[fleftrown]
	mov	cx,[frightrown]
	cmp	cx,bx
	jl	pfn61
	mov	cx,bx
pfn61:	sub	cx,bp
	pop	bx
	cmp	cx,0
	jg	pfn71
pfn6:	pop	cx
	cmp	bp,[fwmaxy1]
	jg	pfn64
	cmp	si,di
	je	pfn64
	dec	cx
	jz	pfn64
	jmp	pfn63
pfn64:	mov	word [ebx],-32767
	mov	esi,borders
	LOADDS
;	call	newgroup
	call	VIDHGROUP
	ret
pfn65:	;above screen
	;entering screen, cut.
	add	bp,cx
	push	bp
	push	cx
	cmp	bp,[wminy]
	jl	pfn66
	sub	bp,cx
	mov	cx,[wminy]
	sub	cx,bp
pfn66:	;
	movsx	ecx,cx
	ror	eax,16
	mov	[feax],eax
	ror	edx,16
	mov	[fedx],edx
	;
	mov	ax,[fleftaddh]
	shl	eax,16
	mov	ax,word [fleftaddl+2]
	imul	ecx
	add	[feax],eax
	;
	mov	ax,[frightaddh]
	shl	eax,16
	mov	ax,word [frightaddl+2]
	imul	ecx
	add	[fedx],eax
	;
	mov	eax,[feax]
	ror	eax,16
	mov	edx,[fedx]
	ror	edx,16
	mov	bp,cx
	pop	cx
	sub	cx,bp
	pop	bp
	cmp	cx,0
	jne	pfn6b
	jmp	pfn6
pfn6b:	mov	bp,[wminy]
pfn71:	;process segment
	cmp	bp,[wminy]
	jl	pfn65 ;above screen still
	add	bp,cx
	;clip max to maxy
	cmp	bp,[fwmaxy1]
	jle	pfn72
	sub	bp,cx
	mov	cx,[fwmaxy1]
	sub	cx,bp
	mov	bp,[fwmaxy1]
pfn72:	cmp	cx,0
	jle	pfn6
	push	si
	push	di
	push	bp
	ror	ebx,16
	neg	cx
	mov	bx,cx
	ror	ebx,16
	mov	esi,[fleftaddl]
	mov	edi,[frightaddl]
	mov	bp,[fleftaddh]
	mov	cx,[frightaddh]
pfn7:	add	eax,esi
	adc	ax,bp
	add	edx,edi
	adc	dx,cx
	mov	[ebx],ax
	mov	[ebx+2],dx
	add	ebx,10004h
	jnc	pfn7
	pop	bp
	pop	di
	pop	si
	jmp	pfn6
polyfcalc: ;**** subroutine ****
	;calc slope for line [SI]->[DI] to [BX], returns CX=len
	mov	cx,[edi+2]
	sub	cx,bp ;[esi+2]
	jle	pfc1
	mov	ax,[edi+0]
	sub	ax,[esi+0]
	jl	pfc2
	xor	dx,dx
	div	cx
	mov	[ebx+4],ax
	xor	ax,ax
	div	cx
	mov	[ebx+2],ax
	;dec	cx
	ret
pfc1:	xor	cx,cx
	ret
pfc2:	neg	ax
	xor	dx,dx
	div	cx
	push	ax
	xor	ax,ax
	div	cx
	pop	dx
	neg	ax
	adc	dx,0
	neg	dx
	mov	[ebx+4],dx
	mov	[ebx+2],ax
	;dec	cx
	ret


%IF 0
;fleftaddl dd	0 ;+0
;fleftaddh dw	0 ;+4
;fleftrown dw	0 ;+6
;fleftzb dd	0 ;+8
;fleftze dd	0 ;+12
;flefttx0 dw	0 ;+16
;fleftty0 dw	0 ;+18
;flefttxa dw	0 ;+20
;flefttya dw	0 ;+22
;fleftcnt dw	0 ;+24
;fleftcnta dw	0 ;+26

polyft: ;ONLY CONVEX POLYGONS - FAST?
	;input: polysides/polyxy
	;requirements:
	;es=vram
	;ds=cs
	;cpolysides>=4 (not checked)
	;color=set
	;**COPY/SEEK UPPERMOST**
	LOADGS	;GS points to data seg!
	mov	ax,cs
	mov	ds,ax
	mov	fs,[depthseg]
	mov	cx,[polysides]
	mov	ax,cx
	shl	ax,4 ;*16
	mov	[finfolen],ax
	add	ax,OFFSET finfo
	mov	[finfo1],ax
	mov	ax,[wmaxy]
	inc	ax
	mov	[fwmaxy1],ax
	mov	edx,077770000h
	xor	bx,bx
	mov	si,OFFSET polyxy
	mov	di,OFFSET finfo
	mov	[finfo0],di
pftn1:	mov	eax,dword [esi]
	cmp	eax,edx
	jg	pftn2
	mov	edx,eax
	mov	bx,di
pftn2:	mov	dword [edi],eax
	mov	eax,[esi+POLYZ]
	mov	[edi+4],eax
	mov	eax,[esi+POLYTXY]
	mov	[edi+8],eax
	add	si,4
	add	di,16
	loop	pftn1
	;[bx]=uppermost
	;**SETUP REGS**
	mov	[fleftrown],-32767
	mov	[frightrown],-32767
	mov	si,bx
	mov	di,bx
	mov	bp,[esi+2]
	mov	bx,OFFSET borders
	mov	ax,bp
	cmp	ax,[wminy]
	jge	pftn35
	mov	ax,[wminy]
pftn35:	mov	[ebx],ax
	add	bx,2
	mov	cx,16 ;max tmp count to avoid hanging on illegal polygons
	;eax=left
	;bx=pointer to borders[]
	;cx=count
	;edx=right
	;si=left
	;di=right
	;bp=y
pftn63:	push	cx
	push	bx
	
	cmp	bp,[fleftrown]
	jl	pftn42
	push	edx
	push	di
	mov	di,si
	sub	di,16
	cmp	di,[finfo0]
	jae	pftn41
	add	di,[finfolen]
pftn41:	mov	bx,OFFSET fleftaddl
	call	polyftcalc
	add	cx,bp
	mov	[fleftrown],cx
	movzx	eax,word [esi+0]
	mov	ebx,[fleftaddl]
	mov	dx,[fleftaddh]
	sar	dx,1
	rcr	ebx,1
	xor	bx,bx
	sub	eax,ebx
	sbb	ax,dx
	mov	si,di
	pop	di
	pop	edx
pftn42:
	cmp	bp,[frightrown]
	jl	pftn52
	push	eax
	push	si
	mov	si,di
	add	di,16
	cmp	di,[finfo1]
	jb	pftn51
	sub	di,[finfolen]
pftn51:	mov	bx,OFFSET frightaddl
	call	polyftcalc
	add	cx,bp
	mov	[frightrown],cx
	movzx	edx,word [esi+0]
	mov	ebx,[frightaddl]
	mov	ax,[frightaddh]
	sar	ax,1
	rcr	ebx,1
	xor	bx,bx
	sub	edx,ebx
	sbb	dx,ax
	pop	si
	pop	eax
	
pftn52:	mov	bx,[fleftrown]
	mov	cx,[frightrown]
	cmp	cx,bx
	jl	pftn61
	mov	cx,bx
pftn61:	sub	cx,bp
	pop	bx
	cmp	cx,0
	jg	pftn71
pftn6:	pop	cx
	cmp	bp,[fwmaxy1]
	jg	pftn64
	cmp	si,di
	je	pftn64
	dec	cx
	jz	pftn64
	jmp	pftn63
pftn64:	mov	word [ebx],-32767
	mov	si,OFFSET borders ;gs:si
	mov	fs,[_texture+2]
	LOADDS
;	call	newgroup
	call	VIDHGROUP
	ret
pftn65:	;above screen
	;entering screen, cut.
	add	bp,cx
	push	bp
	push	cx
	cmp	bp,[wminy]
	jl	pftn66
	sub	bp,cx
	mov	cx,[wminy]
	sub	cx,bp
pftn66:	;
	movsx	ecx,cx
	ror	eax,16
	mov	[feax],eax
	ror	edx,16
	mov	[fedx],edx
	;
	mov	ax,[fleftaddh]
	shl	eax,16
	mov	ax,word [fleftaddl+2]
	imul	ecx
	add	[feax],eax
	mov	ax,word [fleftcnta]
	imul	cx
	add	[fleftcnt],ax
	;
	mov	ax,[frightaddh]
	shl	eax,16
	mov	ax,word [frightaddl+2]
	imul	ecx
	add	[fedx],eax
	mov	ax,word [frightcnta]
	imul	cx
	add	[frightcnt],ax
	;
	mov	eax,[feax]
	ror	eax,16
	mov	edx,[fedx]
	ror	edx,16
	mov	bp,cx
	pop	cx
	sub	cx,bp
	pop	bp
	cmp	cx,0
	jne	pftn6b
	jmp	pftn6
pftn6b:	mov	bp,[wminy]
pftn71:	;process segment
	cmp	bp,[wminy]
	jl	pftn65 ;above screen still
	add	bp,cx
	;clip max to maxy
	cmp	bp,[fwmaxy1]
	jle	pftn72
	sub	bp,cx
	mov	cx,[fwmaxy1]
	sub	cx,bp
	mov	bp,[fwmaxy1]
pftn72:	cmp	cx,0
	jle	pftn6
	push	si
	push	di
	push	bp
	ror	ebx,16
	neg	cx
	mov	bx,cx
	ror	ebx,16
	mov	esi,[fleftaddl]
	mov	edi,[frightaddl]
	;eax/edx=x position
	;esi/edi=x adder high
	;bp/cx=xadder low
	;ebx=borders pointer / end counter
	;mov	cx,gs
	
calccx MACRO bb ;bp=>cx
	;linear
	mov	bp,word [bb+24]
	shr	bp,5
	shl	bp,1
	add	bp,word [bb+28]
	mov	bp,[ebp]
	mov	eax,dword [bb+20]
	imul	bp
	shld	dx,ax,7
	add	dx,word [bb+16]
	mov	cl,dl
	shr	eax,16
	imul	bp
	shld	dx,ax,7
	add	dx,word [bb+18]
	mov	ch,dl
	mov	bp,word [bb+26]
	add	word [bb+24],bp
	ENDM
	
pftn7:	add	eax,esi
	adc	ax,[fleftaddh]
	add	edx,edi
	adc	dx,[frightaddh]
	mov	[ebx],ax
	mov	[ebx+2],dx
	push	dx
	push	eax
	calccx	frightaddl
	shl	ecx,16
	calccx	fleftaddl
	mov	[ebx+4],ecx
	pop	eax
	pop	dx
	add	ebx,10008h
	jnc	pftn7
	pop	bp
	pop	di
	pop	si
	jmp	pftn6
ALIGN 4
zzzcxa	dw	0

;fleftaddl dd	0 ;+0
;fleftaddh dw	0 ;+4
;fleftrown dw	0 ;+6
;fleftzb dd	0 ;+8
;fleftze dd	0 ;+12
;flefttx0 dw	0 ;+16
;fleftty0 dw	0 ;+18
;flefttxa dw	0 ;+20
;flefttya dw	0 ;+22
;fleftcnt dw	0 ;+24
;fleftcnta dw	0 ;+26

polyftcalc: ;**** subroutine ****
	;calc slope for line [SI]->[DI] to [BX], returns CX=len
	;calc texture
	mov	eax,[esi+4]
	mov	[ebx+8],eax
	mov	eax,[edi+4]
	mov	[ebx+12],eax
	mov	eax,[esi+8]
	mov	[ebx+16],eax
	neg	ax
	add	ax,[edi+8]
	mov	[ebx+20],ax
	shr	eax,16
	neg	ax
	add	ax,[edi+10]
	mov	[ebx+22],ax
	;calc slope
	;bx+2=addl
	;bx+4=addh
	mov	cx,[edi+2]
	sub	cx,bp ;[esi+2]
	jle	pftc1
	;calc texture len
	mov	ax,16384
	xor	dx,dx
	mov	[ebx+24],dx
	div	cx
	mov	[ebx+26],ax
	;find suitable texture function
	push	bp
	mov	eax,256
	imul	dword [esi+4]
	idiv	dword [edi+4]
	mov	bp,-4
pftc3:	add	bp,4
	cmp	[ebp],ax
	ja	pftc3
	mov	ax,[ebp+2]
	mov	[ebx+28],ax
	pop	bp
	;
	mov	ax,[edi+0]
	sub	ax,[esi+0]
	jl	pftc2
	xor	dx,dx
	div	cx
	mov	[ebx+4],ax
	xor	ax,ax
	div	cx
	mov	[ebx+2],ax
	;dec	cx
	ret
pftc1:	xor	cx,cx
	ret
pftc2:	neg	ax
	xor	dx,dx
	div	cx
	push	ax
	xor	ax,ax
	div	cx
	pop	dx
	neg	ax
	adc	dx,0
	neg	dx
	mov	[ebx+4],dx
	mov	[ebx+2],ax
	ret

%ENDIF

;%include "new.asm"
