%include "asm.inc"

extern __newgroup

section .data

global _lightshift
_lightshift db	0
count	dw	0
edgesoff dd	0
pointsoff dd	0
cntoff	dd	0

global _backpal	
_backpal times 16 db 16,16,16
	
back1	db	0,4,8
back2	db	4,0,0
back3	db	7,0,0
back4	db	13,0,0

rolcol	times	256 db 0
rolused	times	256 db 0

clipz	dd	2200

;ALIGN 2
global _demomode
_demomode dd	demo_glz
	dd	demo_glz
	dd	demo_glz2

section .code

global _csetmatrix
_csetmatrix:
	CBEG
	LOADDS
	mov	eax,[esp+12]
	mov	[_xadd],eax		
	mov	eax,[esp+16]
	mov	[_yadd],eax		
	mov	eax,[esp+20]
	mov	[_zadd],eax		
	mov	esi,[esp+8]
	call	setmatrix
	CEND


global _crotlist
_crotlist:
	CBEG
	mov	esi,[esp+12]
	mov	edi,[esp+8]
	call	_rotlist
	CEND


global _cprojlist
_cprojlist:
	CBEG
	mov	esi,[esp+12]
	mov	edi,[esp+8]
	call	projlist
	CEND


global _ccliplist
_ccliplist:
	CBEG
	mov	esi,[esp+8]
	call	cliplist
	CEND


global setmatrix
setmatrix:
	;ds:si=matrix
	movsx	eax,word [esi+0]
	mov	dword [1+mtrm00],eax
	movsx	eax,word [esi+2]
	mov	dword [1+mtrm02],eax
	movsx	eax,word [esi+4]
	mov	dword [1+mtrm04],eax
	movsx	eax,word [esi+6]
	mov	dword [1+mtrm06],eax
	movsx	eax,word [esi+8]
	mov	dword [1+mtrm08],eax
	movsx	eax,word [esi+10]
	mov	dword [1+mtrm10],eax
	movsx	eax,word [esi+12]
	mov	dword [1+mtrm12],eax
	movsx	eax,word [esi+14]
	mov	dword [1+mtrm14],eax
	movsx	eax,word [esi+16]
	mov	dword [1+mtrm16],eax
	ret


;ALIGN 2

global _rotlist
_rotlist:
	;pointlist@DS:SI=>pointlist@ES:DI
	push	edi
	LOADGS
	mov	cx,[esi]
	add	esi,4
	mov	[count],cx
	mov	ax,[edi]
	add	[edi],cx
	mov	bx,ax
	shl	ax,1
	add	ax,bx
	shl	ax,2
	add	di,ax
	add	di,4

nrup1:	;rotate with matrix
	push	esi
	push	edi
	mov	ebp,[esi+8]
	mov	edi,[esi+4]
	mov	esi,[esi+0]
mtrm00:	mov	eax,12345678h
	imul	esi
	mov	ebx,eax
	mov	ecx,edx
mtrm02:	mov	eax,12345678h
	imul	edi
	add	ebx,eax
	adc	ecx,edx
mtrm04:	mov	eax,12345678h
	imul	ebp
	add	ebx,eax
	adc	ecx,edx
	shld	ecx,ebx,17
	push	ecx
mtrm06:	mov	eax,12345678h
	imul	esi
	mov	ebx,eax
	mov	ecx,edx
mtrm08:	mov	eax,12345678h
	imul	edi
	add	ebx,eax
	adc	ecx,edx
mtrm10:	mov	eax,12345678h
	imul	ebp
	add	ebx,eax
	adc	ecx,edx
	shld	ecx,ebx,17
	push	ecx
mtrm12:	mov	eax,12345678h
	imul	esi
	mov	ebx,eax
	mov	ecx,edx
mtrm14:	mov	eax,12345678h
	imul	edi
	add	ebx,eax
	adc	ecx,edx
mtrm16:	mov	eax,12345678h
	imul	ebp
	add	ebx,eax
	adc	ecx,edx
	shld	ecx,ebx,17
	pop	edx
	pop	eax
	pop	edi
	pop	esi
	;
	add	eax,[_xadd]
	mov	[edi+0],eax
	add	ecx,[_yadd]
	mov	[edi+4],ecx
	add	edx,[_zadd]
	mov	[edi+8],edx
	;next point
	add	esi,12
	add	edi,12
	dec word	[count]
	jnz	nrup1
	pop	edi
	ret


projlist:
	;pointlist@DS:SI=>projectedpointlist@ES:DI
	push	edi
	LOADGS
	mov	cx,[esi]
	add	esi,4
	mov	[count],cx
	mov	ax,[edi]
	add	[edi],cx
	mov	bx,ax
	shl	ax,1
	add	ax,bx
	shl	ax,2
	add	di,ax
	add	di,4

.@@1:	;rotate with matrix
	mov	ebx,[esi+8]
	mov	eax,[esi+4]
	mov	ecx,[esi+0]
	
	;project

	xor	ebp,ebp
	mov	dword [edi+8],ebx
	cmp	ebx,[projminz]
	jge	.@@2
	mov	ebx,[projminz]
	or	bp,16
.@@2:	;
	imul	dword [projymul]
	idiv	ebx
	add	ax,[projyadd]
	cmp	ax,[wmaxy]
	jng	.@@41
	or	bp,8
.@@41:	cmp	ax,[wminy]
	jnl	.@@42
	or	bp,4
.@@42:	mov	[edi+2],ax ;store Y
	;
	mov	eax,[projxmul]
	imul	ecx
	idiv	ebx
	add	ax,[projxadd]
	cmp	ax,[wmaxx]
	jng	.@@43
	or	bp,2
.@@43:	cmp	ax,[wminx]
	jnl	.@@44
	or	bp,1
.@@44:	mov	[edi+0],ax ;store X

.@@5:	mov	[edi+4],bp ;store visiblity flags
	
	;next point
	add	esi,12
	add	edi,12
	dec	word [count]
	jnz	.@@1
	pop	edi
	ret


cliplist:
	;pointlist@DS:SI
	push	edi
	LOADGS
	mov	cx,[esi]
	add	esi,4

.@@1:	;rotate with matrix
	mov	eax,[esi+4]
	cmp	eax,1500
	jl	.@@2
	mov	dword [esi+4],1500
.@@2:
	;next point
	add	esi,12
	dec	cx
	jnz	.@@1
	pop	edi
	ret

adddot:
	cmp	ax,bp
	je	.@@3
	mov	bp,ax
	;add dot
	push	ebx
  movzx eax,ax
	mov	ebx,eax
	shl	ebx,1
	add	ebx,eax
	shl	ebx,2
	add	ebx,[pointsoff]
	mov	eax,[edx+ebx] ;edx=gs
	stosd
	pop	ebx
.@@3:
  ret


checkhiddenbx:
	push	si
	mov	ax,[ebx]
	mov	si,[ebx+2]
	sub	ax,[ebx+4]
	sub	si,[ebx+8+2]
	imul	si
	push	ax
	push	dx
	mov	ax,[ebx+2]
	mov	si,[ebx]
	sub	ax,[ebx+4+2]
	sub	si,[ebx+8]
	imul	si
	pop	cx
	pop	si
	xchg	si,ax
	xchg	dx,cx
	sub	ax,si
	sbb	dx,cx
	pop	si
	cmp	dx,0
	jl	.@@1
	clc
	ret
.@@1:	stc
	ret


global _cpolylist
_cpolylist: ;polylist,polys,edges,points3
	CBEG
	mov	di,[bp+6]
	mov	es,word [bp+8]
	mov	si,[bp+10]
	mov	ds,word [bp+12]
	mov	ax,[bp+14]
	add	ax,4
	mov	[edgesoff],ax
	mov	fs,word [bp+16]
	mov	ax,[bp+18]
	add	ax,4
	mov	[pointsoff],ax
	mov	gs,word [bp+20]
	mov	bp,-1
.@@2:	lodsw
	cmp	ax,0
	je	.@@1
	add	di,2
	mov	cx,ax
	movsw
	mov	[cntoff],di
.@@3:	push	cx
	mov	bx,[esi]
	add	si,2
	shl	bx,3
	add	bx,[edgesoff]
	test	word [ebx+4],8000h
	jnz	.@@7
	mov	ax,[ebx+2]
	cmp	ax,bp
	je	.@@5
	mov	ax,[ebx]
	call	adddot
	mov	ax,[ebx+2]
	call	adddot
.@@7:	pop	cx
	loop	.@@3
	jmp	.@@6
.@@5:	mov	ax,[ebx+2]
	call	adddot
	mov	ax,[ebx]
	call	adddot
	pop	cx
	loop	.@@3
.@@6:	mov	bx,[cntoff]
	mov	eax,[ebx]
	cmp	eax,[edi-4]
	jne	.@@4
	sub	di,4
.@@4:	mov	ax,di
	sub	ax,[cntoff]
	shr	ax,2
	mov	[ebx-4],ax
	call	checkhiddenbx
	jnc	.@@2
	xor	word [ebx-2],8000h
	jmp	.@@2
.@@1:	mov	word [edi],0
	CEND


%macro setpalxxx 0
	;local	l1,l2,l3
	mov	al,cl
	cmp	al,64
	jb	%%l1
	mov	al,63
%%l1:	out	dx,al
	mov	al,bl
	cmp	al,64
	jb	%%l2
	mov	al,63
%%l2:	out	dx,al
	mov	al,bh
	cmp	al,64
	jb	%%l3
	mov	al,63
%%l3:	out	dx,al
%endmacro

demo_norm:
	ret


demo_glz2:
	jc	.@@1
	mov	al,[ebx-2]
	shr	al,1
	and	al,1
	mov	[ebx-2],al
.@@1:	ret


demo_glz:
	jnc	.@@7 ;visible
	mov	ax,[ebx-2]
	push	bx
	push	ax
	mov	bl,al
	xor	bh,bh
	mov	al,[rolcol+ebx]
	mov	byte [rolcol+ebx],0
	mov	bl,al
	mov	byte [rolused+ebx],0
	pop	ax
	pop	bx
	shr	al,1
	and	al,1
	shl	al,2
	mov	[ebx-2],ax
	ret
.@@7:	mov	cl,[_lightshift]
	cmp	cl,9
	je	.@@x9
	shrd	ax,dx,8
	push	ax	
	shrd	ax,dx,1
	pop	dx
	add	ax,dx
	jmp	.@@x10
.@@x9:	mov	cl,7
	shrd	ax,dx,cl
.@@x10:	cmp	ax,0
	jge	.@@s1
	mov	ax,0
.@@s1:	cmp	ax,63
	jle	.@@s2
	mov	ax,63
.@@s2:	mov	ah,al
	;
	push	ebx
	movzx	ebx, byte [ebx-2]
	mov	al,[rolcol+ebx]
	cmp	al,0
	jne	.@@rc1
	mov	cx,15
	mov	ebp,2
.@@rc3:	cmp	byte [rolused+ebp],0
	je	.@@rc4
	add	ebp,2
	loop	.@@rc3
.@@rc4:	mov	eax,ebp
.@@rc2:	mov	[rolcol+ebx],al
	mov	byte [rolused+ebp],1
.@@rc1:	pop	ebx
	mov	bp,[ebx-2]
	shl	al,3
	mov	[ebx-2],al
	
;	mov	dx,3c8h
;	out	dx,al
;	inc	dx

	test	bp,2
	jz	.@@b1	
	mov	bh,ah ;B
	shr	ah,1
	mov	bl,ah ;G
	jmp	.@@b2
.@@b1:	mov	cl,ah ;R
	mov	bl,ah ;G
	mov	bh,ah ;B
.@@b2:	push	esi
	push	edi
	mov	si,cx
	mov	di,bx
	
	%assign zzz 0
	%rep	16
	mov	al,[_backpal+zzz*3+0]
	shr	al,2
	add	cl,al
	mov	al,[_backpal+zzz*3+1]
	shr	al,2
	add	bl,al
	mov	al,[_backpal+zzz*3+2]
	shr	al,2
	add	bh,al
	;setpalxxx
	mov	bx,di
	mov	cx,si
	%assign zzz zzz+1
	%endrep
	
	pop	edi
	pop	esi
.@@xx:	ret

global _ceasypolylist
_ceasypolylist: ;polylist,polys,points3
	CBEG

  ; esi = "polys" input
  ;   1 word (vertex count)
  ;   1 word (face data)
  ;   N word (vertex indices)
  ; edi = "polylist" output
  ; edx = "points3" input
  ;   1 word (X)
  ;   1 word (Y)
  ;   1 word ("visiblity flags")

	mov	edi,[esp+8]
	;mov	es,word [ebp+8]
	mov	esi,[esp+12]
	;mov	ds,word [ebp+12]
	add	eax,4
	mov	[pointsoff],eax
	mov	edx,[esp+16]
	mov	bp,-1
.@@2:	lodsw
	cmp	ax,0
	je	.@@1
	add	di,2
	movzx	ecx,ax
	movsw
	mov	[cntoff],edi
.@@3:	push	cx
	mov	ax,[esi]
	add	si,2
	call	adddot
	pop	cx
	loop	.@@3
.@@6:	mov	ebx,[cntoff]
	mov	eax,[ebx]
	cmp	eax,[edi-4]
	jne	.@@4
	sub	di,4
.@@4:	mov	eax,edi
	sub	eax,[cntoff]
	shr	eax,2
	mov	[ebx-4],ax
  push edx
	call	checkhiddenbx
	call	[_demomode] ;sets colors etc / hidden faces flipped
  pop edx
	jmp	.@@2
.@@1:	mov	word [edi],0
	CEND


global _cglenzinit
_cglenzinit:
	CBEG
	LOADDS
	mov	ax,0
	call	__newgroup
	CEND


global _cglenzdone
_cglenzdone:
	CBEG
	LOADDS
	mov	ax,2
	call	__newgroup
	CEND


global _cglenzpolylist
_cglenzpolylist:
	CBEG
	LOADDS
	movpar	esi,0
	mov	ax,1
	call	__newgroup
	CEND


global _cdrawpolylist
_cdrawpolylist:
	CBEG
	LOADDS
	movpar	di,0
	mov	es,word [bp+8]
	call	VIDPOLYGROUP
	CEND

clipsidi:
	;si=point1(hidden), di=point2
	;adds new point to pointlist (fs:bp-4)
	;returns number of new point (si)
	push	bx
	mov	ecx,[edi+8]
	mov	edx,ecx
	sub	ecx,[esi+8]
	;cx=length of entire edge
	sub	edx,[clipz]
	;dx=length of clipped edge
	xor	eax,eax
	div	ecx
	shr	eax,16
	mov	ecx,eax
	;ecx=multiplier (0..65535)
	mov	eax,[esi]
	sub	eax,[edi]
	imul	ecx
	shld	edx,eax,16
	add	edx,[edi]
	push	edx ;X
	mov	eax,[esi+4]
	sub	eax,[edi+4]
	imul	ecx
	shld	edx,eax,16
	add	edx,[edi+4] ;edx=Y
	;
	mov	bx,[ebp-4]
	inc	bx
	mov	[ebp-4],bx
	dec	bx
	mov	si,bx
	shl	bx,1
	add	bx,si
	shl	bx,2
	add	bx,bp
	mov	[ebx+4],edx
	pop	edx
	mov	[ebx],edx
	mov	edx,[clipz]
	mov	[ebx+8],edx
	pop	bx
	ret


global _cclipedges
_cclipedges: ;(destedges,edges,points)
	CBEG
	movpar	bx,0
	movpar	es,1
	movpar	si,2
	movpar	ds,3
	movpar	fs,5
	movpar	bp,4
	mov	cx,[esi]
	add	si,4
	mov	[ebx],cx
	add	bx,4
	add	bp,4
	;
.@@1:	push	cx
	push	si
	push	di
	push	bx
	mov	ax,[esi+4]
	mov	[ebx+4],ax
	mov	di,[esi+2]
	mov	[ebx+2],di
	mov	ax,di
	shl	di,1
	add	di,ax
	shl	di,2
	add	di,bp
	mov	si,[esi]
	mov	[ebx],si
	mov	ax,si
	shl	si,1
	add	si,ax
	shl	si,2
	add	si,bp
	;
	xor	cx,cx
	mov	eax,[esi+8] ;Z
	cmp	eax,[clipz]
	jge	.@@2
	or	cx,1
.@@2:	mov	edx,[edi+8] ;Z
	cmp	edx,[clipz]
	jge	.@@3
	or	cx,2
.@@3:	;
	cmp	cx,0
	je	.@@4
	cmp	cx,3
	jne	.@@5
	or	word [ebx+4],8000h
	jmp	.@@4
.@@5:	cmp	cx,1
	jne	.@@6
	;si hidden
	call	clipsidi
	mov	[ebx],si
	jmp	.@@4
.@@6:	;di hidden
	xchg	si,di
	call	clipsidi
	mov	[ebx+2],si
.@@4:	pop	bx
	add	bx,8
	pop	di
	add	di,8
	pop	si
	add	si,8
	pop	cx
	LOOP_LARGE	.@@1
	CEND
