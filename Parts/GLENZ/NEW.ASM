%include "asm.inc"

;!!!!!! TRANSPARENT NEW COPPER !!!!!!

section .data

global __ndebug1
__ndebug1 dd 0

%define NROWS 256
%define MAXLINES 512
ndp0	dd 0			;toggling pointer inside newdata1
ndp	dd 0			;pointer inside newdata1
nec	dd 0			;pointer to next free in ne
nlc	dd 0			;items in horizontal list
;ALIGN 4
nep	times NROWS dd 0
;ALIGN 4
ne	times MAXLINES * 16 db 0
%define NE_X		0  ;dd
%define NE_Y1 	 4  ;dw
%define NE_Y2		6  ;dw
%define NE_COLOR 8  ;dw
%define NE_NEXT	 10 ;dw
%define NE_DX		12 ;dd
;ALIGN 4
nl	times 256 db 0

tmp_firstvx dw	0
tmp_color dw	0

yrow	dd	0
yrowad	dd	0
siend	dd	0

section .code

extern newdata1
extern _bgpic

ng_init:
	mov	dword [nec],ne
	mov	eax,[ndp0]
	xor	ax,8000h
	mov	[ndp0],eax
	mov	[ndp],eax
	mov	ecx,NROWS/2
	;mov	ax,cs
	;mov	es,ax
	xor	eax,eax
	mov	edi,nep
	rep	stosd
	mov	eax,newdata1
	cmp	word [eax],0
	jne	.@@1
	mov	word [eax],-1
.@@1:	cmp	word [eax+8000h],0
	jne	.@@2
	mov	word [eax+8000h],-1
.@@2:	ret

;ALIGN 2

%macro fillmacro 0;MACRO
	;local	l1,l2
	jcxz	%%l2
	push	ax
%%l1:	mov	ah,al
	or	ah,[_bgpic+edi] ;fs
	mov	[_shim_vram+edi],ah ;es
	inc	di
	loop	%%l1
	pop	ax
%%l2:
%endmacro 

extern _shim_vram

ng_pass3:
  ; ds = newdata
  ; es = VRAM
  ; fs = bgpic

  ;mov edi, _shim_vram

	;mov	ax,0a000h
	;mov	es,ax
  ;TODO
	;mov	ax,_bgpic
	;mov	fs,ax
	xor	edi,edi
	movzx	esi,word [ndp0]
	mov	bx,si
	xor	bx,8000h
	xor	ax,ax
	;si=new     bx=last
	;cx=newpos  dx=lastpos
	;al=newcol  ah=lastcol
	mov	edx,[newdata1+ebx] ;ds
	add	bx,4
	mov	ecx,[newdata1+esi] ;ds
	add	si,4
	;
.@@21:	cmp	dx,cx
	jb	.@@23
	je	.@@22
	;cx<dx
	cmp	al,ah
	je	.@@31
	push	ecx
	sub	cx,di
	;cmp	cx,4
	;jae	.@@r1
	;rep	stosb
	fillmacro
	pop	cx
.@@31:	mov	di,cx
	shr	ecx,16
	xor	al,cl
	mov	ecx,[newdata1+esi] ;ds
	add	si,4
	jmp	.@@21
	
.@@r1:	push	eax
	mov	ah,al
	test	di,1
	jz	.@@r11
	dec	cx
  mov [_shim_vram+edi], al
  inc edi
	;stosb
.@@r11:	shr	cx,1
  add edi,_shim_vram
  add esi,newdata1
	rep	stosw
	adc	cx,cx
	rep	stosb
  sub esi,newdata1
  sub edi,_shim_vram
	pop	eax
	pop	ecx
	jmp	.@@31
	
.@@22:	;cx=dx
	cmp	cx,-1
	je	.@@20
.@@23:	;dx<cx
	cmp	al,ah
	je	.@@32
	push	ecx
	mov	cx,dx
	sub	cx,di
	;cmp	cx,4
	;jae	.@@r2
	;rep	stosb
	fillmacro
	pop	ecx
.@@32:	mov	di,dx
	shr	edx,16
	xor	ah,dl
	mov	edx,[newdata1+ebx] ;ds
	add	bx,4
	jmp	.@@21
	
.@@r2:	push	ax
	mov	ah,al
	test	di,1
	jz	.@@r21
	dec	cx
	stosb
.@@r21:	shr	cx,1
  add edi,_shim_vram
  add esi,newdata1
	rep	stosw
	adc	cx,cx
	rep	stosb
  sub esi,newdata1
  sub edi,_shim_vram
	pop	eax
	pop	ecx
	jmp	.@@32
.@@20:	ret

	;mov	ax,0a000h
	;mov	es,ax
	;mov	esi,newdata1
	xor	di,di
	xor	ax,ax
	movzx	edx, word [ndp]
.@@1:	mov	cx,[esi]
	sub	cx,di
  add edi,_shim_vram
  add esi,newdata1
	rep	stosb
  sub esi,newdata1
  sub edi,_shim_vram
	xor	al,[esi+2]
	add	si,4
	cmp	si,dx
	jb	.@@1
	ret

ng_pass2:
	mov	ebp,nep
	mov	edi,nl
	mov	ecx,200 ;NROWS
	mov	dword [yrow],0
	mov	dword [yrowad],0
.@@1:	push	ecx
	;di=pointer to this row list end
	;bp=pointer to nep
	
	;add new items this row
	mov	bx,[ebp]
	jmp	.@@3
.@@2:	mov	[edi],bx
	add	di,2
	mov	bx,[ebx+NE_NEXT]
.@@3:	cmp	bx,0
	jne	.@@2

	;sort this row (insertion sort)
	push	ebp
	push	edi
	mov	ebp,edi
	mov	esi,nl+2
	jmp	.@@4
.@@5:	;for(k=1;k<listc;k++) {  // k=SI
	mov	bx,[esi] ;bx=list[k]
	mov	dx,bx ;dx=i
	mov	eax,[ebx+NE_X] ;eax=x
	mov	di,si
	sub	di,2 ;di=j
	jmp	.@@6
	;;;for(j=k-1;j>=0 && x<e[list[j]].x;j--) {
.@@9:	mov	[edi+2],bx	;bx=cs:di
	sub	di,2
.@@6:	cmp	edi,nl
	jge	.@@8
	jmp	.@@7
.@@8:	mov	bx,[edi]
	cmp	eax,[ebx+NE_X]
	jl	.@@9
.@@7:	;;;}
	mov	[edi+2],dx
	add	si,2
.@@4:	cmp	si,bp
	jb	.@@5
	;}
	pop	edi
	;bp=nl end
	
	;process list & kill finished lines
	
	mov	[siend],ebp
  ;TODO!
	;mov	ax,newdata1
	;mov	fs,ax
	mov	ebp,[ndp]
	mov	edx,[yrow]
	mov	ecx,8000h
	mov	esi,nl
	mov	edi,esi
	jmp	.@@10
.@@11:	movzx	ebx, word [esi]
	cmp	dx,[ebx+NE_Y2]
	jge	.@@12
	mov	[edi],bx
	add	di,2
	mov	eax,[ebx+NE_X]
	push	eax
	add	eax,[ebx+NE_DX]
	;sub	dword ptr [ebx+NE_DX],500
	mov	[ebx+NE_X],eax
	pop	eax
	shr	eax,16
	;clip X
	cmp	ax,319
	jle	.@@15
	mov	ax,319
.@@15:	cmp	ax,1
	jge	.@@16
	mov	ax,1
.@@16:	;
	cmp	cx,ax
	jne	.@@14
	;same x pos
	mov	ax,[ebx+NE_COLOR]
	xor	[newdata1+ebp-2],ax ;fs
	jmp	.@@12
.@@14:	;new x pos
	add	ax,[yrowad]
	mov	[newdata1+ebp+0],ax ;fs
	mov	ax,[ebx+NE_COLOR]
	mov	[newdata1+ebp+2],ax ;fs
	add	ebp,4
	mov	cx,ax
.@@12:	add	esi,2
.@@10:	cmp	esi,[siend]
	jb	.@@11
	mov	[ndp],ebp
	
	pop	ebp
	pop	ecx
	inc	dword [yrow]
	add	dword [yrowad],320
	add	bp,2
	LOOP_LARGE	.@@1
	mov	ebx,[ndp]
	mov	word [newdata1+ebx+0],63999 ;fs
	mov	word [newdata1+ebx+2],0
	add	ebx,4
	mov	word [newdata1+ebx+0],-1
	mov	word [newdata1+ebx+2],0
	add	ebx,4
	mov	[ndp],ebx
	ret

global __newgroup
__newgroup:
	;es:di=polygroup
	;sides,color,x,y,x,y,x,y,...
	;sides=0=end
	cmp	ax,0
	jne	.@@ng1
	call	ng_init
	ret
.@@ng1:	cmp	ax,1
	je	.@@ng2
	setborder 2
	call	ng_pass2
	setborder 3
	call	ng_pass3
	ret
.@@ng2:	setborder 1

	;add polygons to list
	mov	bp,[nec]
.@@2:	mov	cx,[edi] ;sides
	cmp	cx,0
	je	.@@1
	mov	ax,[edi+2] ;color
	mov	[tmp_color],ax
	mov	si,di
	add	di,4
	mov	[tmp_firstvx],di
.@@3:	add	si,4
	add	di,4
	cmp	cx,1
	jne	.@@4
	mov	di,[tmp_firstvx]
.@@4:	push	cx
	;dx=color, si->start, di->end
	mov	ax,[tmp_color]
	mov	[ebp+NE_COLOR],ax
	mov	bx,[esi+2] ;y1
	mov	cx,[edi+2] ;y2
	cmp	bx,cx 
	jg	.@@i1	;y1>y2
	mov	ax,[esi+0] ;x1
	mov	dx,[edi+0] ;x2
	jmp	.@@i0
.@@i1:	xchg	bx,cx
	mov	ax,[edi+0] ;x1
	mov	dx,[esi+0] ;x2	
.@@i0:	;ax,bx=xy1  dx,cx=xy2
.@@i9:	mov	[ebp+NE_Y1],bx
	mov	[ebp+NE_Y2],cx
	mov	word [ebp+NE_X],0
	mov	[ebp+NE_X+2],ax
	neg	ax
	add	ax,dx
	shl	eax,16
	cdq
	sub	cx,bx
	;cx=y2-y1,edx:eax=(x2-x1)<<16
	cmp	cx,0
	je	.@@n1 ;skip horizontal lines
	movzx	ecx,cx
	idiv	ecx
	mov	[ebp+NE_DX],eax
	;!!!if y1<0, clip
	cmp	bx,0
	jge	.@@nc
	mov	dx,[ebp+NE_Y2]
	cmp	dx,0
	jle	.@@n1
	neg	bx
	movzx	ebx,bx
	imul	ebx
	add	[ebp+NE_X],eax
	xor	bx,bx
	mov	[ebp+NE_Y1],bx
.@@nc:	;!!!
	shl	bx,1
	mov	ax,[nep+ebx]
	or	ax,ax
	jnz	.@@j1
	;first on this row
	mov	[nep+ebx],bp
	mov	word [ebp+NE_NEXT],0
	jmp	.@@j0	
.@@j1:	;add to this row
	;scan if already exists
	push	ax
	push	si
	mov	si,ax
	jmp	.@@h11
.@@h1:	mov	si,[esi+NE_NEXT]
.@@h11:	mov	ax,[ebp+NE_Y2]
	cmp	ax,[esi+NE_Y2]
	jne	.@@h2
	mov	eax,[ebp+NE_X]
	cmp	eax,[esi+NE_X]
	jne	.@@h2
	mov	eax,[ebp+NE_DX]
	cmp	eax,[esi+NE_DX]
	jne	.@@h2
	;duplicate line SI
	mov	al,[ebp+NE_COLOR]
	xor	[esi+NE_COLOR],al
	pop	si
	pop	ax
	jmp	.@@n1
.@@h2:	cmp	si,0
	jne	.@@h1 ;end of list
.@@h3:	pop	si
	pop	ax
	mov	[nep+ebx],bp
	mov	word [ebp+NE_NEXT],ax
.@@j0:	add	bp,16
.@@n1:	;next
	pop	cx
	LOOP_LARGE	.@@3
	add	si,4
	mov	di,si
	jmp	.@@2

.@@1:	mov	[nec],ebp
	sub	ebp,ne
	shr	ebp,4
	mov	[__ndebug1],ebp

	ret
