
;!!!!!! TRANSPARENT NEW COPPER !!!!!!

section .data

global __ndebug1
__ndebug1 dd 0

tmp_firstvx dw	0
tmp_color dw	0

yrow	dw	0
yrowad	dw	0
siend	dw	0

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

section .code

extern newdata1
extern _bgpic

ng_init:
	mov	dword [nec],ne
	mov	ax,[ndp0]
	xor	ax,8000h
	mov	[ndp0],ax
	mov	[ndp],ax
	mov	ecx,NROWS
	;mov	ax,cs
	;mov	es,ax
	xor	eax,eax
	mov	edi,nep
	rep	stosd
	mov	eax,newdata1
	cmp	word [eax],0
	jne	.@@j1
	mov	word [eax],-1
.@@j1:	cmp	word [eax+8000h],0
	jne	.@@j2
	mov	word [eax+8000h],-1
.@@j2:	ret

;ALIGN 2

%macro fillmacro 0;MACRO
	;local	l1,l2
	jcxz	%%l2
	push	ax
%%l1:	mov	ah,al
	or	ah,[edi]
	mov	[edi],ah
	inc	di
	loop	%%l1
	pop	ax
%%l2:
%endmacro 

ng_pass3:
	mov	esi, newdata1
	;mov	ax,0a000h
	;mov	es,ax
  ;TODO
	;mov	ax,_bgpic
	;mov	fs,ax
	xor	di,di
	mov	si,[ndp0]
	mov	bx,si
	xor	bx,8000h
	xor	ax,ax
	;si=new     bx=last
	;cx=newpos  dx=lastpos
	;al=newcol  ah=lastcol
	mov	edx,[ebx]
	add	bx,4
	mov	ecx,[esi]
	add	si,4
	;
.@@j21:	cmp	dx,cx
	jb	.@@j23
	je	.@@j22
	;cx<dx
	cmp	al,ah
	je	.@@j31
	push	cx
	sub	cx,di
	;cmp	cx,4
	;jae	.@@jr1
	;rep	stosb
	fillmacro
	pop	cx
.@@j31:	mov	di,cx
	shr	ecx,16
	xor	al,cl
	mov	ecx,[esi]
	add	si,4
	jmp	.@@j21
	
.@@jr1:	push	ax
	mov	ah,al
	test	di,1
	jz	.@@jr11
	dec	cx
	stosb
.@@jr11:	shr	cx,1
	rep	stosw
	adc	cx,cx
	rep	stosb
	pop	ax
	pop	cx
	jmp	.@@j31
	
.@@j22:	;cx=dx
	cmp	cx,-1
	je	.@@j20
.@@j23:	;dx<cx
	cmp	al,ah
	je	.@@j32
	push	cx
	mov	cx,dx
	sub	cx,di
	;cmp	cx,4
	;jae	.@@jr2
	;rep	stosb
	fillmacro
	pop	cx
.@@j32:	mov	di,dx
	shr	edx,16
	xor	ah,dl
	mov	edx,[ebx]
	add	bx,4
	jmp	.@@j21
	
.@@jr2:	push	ax
	mov	ah,al
	test	di,1
	jz	.@@jr21
	dec	cx
	stosb
.@@jr21:	shr	cx,1
	rep	stosw
	adc	cx,cx
	rep	stosb
	pop	ax
	pop	cx
	jmp	.@@j32
.@@j20:	ret

  ; TODO: VRAM
	;mov	ax,0a000h
	;mov	es,ax
	mov	esi,newdata1
	xor	di,di
	xor	ax,ax
	mov	dx,[ndp]
.@@j1:	mov	cx,[esi]
	sub	cx,di
	rep	stosb
	xor	al,[esi+2]
	add	si,4
	cmp	si,dx
	jb	.@@j1
	ret

ng_pass2:
	mov	ebp,nep
	mov	edi,nl
	mov	cx,200 ;NROWS
	mov	dword [yrow],0
	mov	dword [yrowad],0
.@@j1:	push	cx
	;di=pointer to this row list end
	;bp=pointer to nep
	
	;add new items this row
	mov	bx,[ebp]
	jmp	.@@j3
.@@j2:	mov	[edi],bx
	add	di,2
	mov	bx,[ebx+NE_NEXT]
.@@j3:	cmp	bx,0
	jne	.@@j2

	;sort this row (insertion sort)
	push	bp
	push	di
	mov	bp,di
	mov	esi,nl+2
	jmp	.@@j4
.@@j5:	;for(k=1;k<listc;k++) {  // k=SI
	mov	bx,[esi] ;bx=list[k]
	mov	dx,bx ;dx=i
	mov	eax,[ebx+NE_X] ;eax=x
	mov	di,si
	sub	di,2 ;di=j
	jmp	.@@j6
	;;;for(j=k-1;j>=0 && x<e[list[j]].x;j--) {
.@@j9:	mov	[edi+2],bx	;bx=cs:di
	sub	di,2
.@@j6:	cmp	edi,nl
	jge	.@@j8
	jmp	.@@j7
.@@j8:	mov	bx,[edi]
	cmp	eax,[ebx+NE_X]
	jl	.@@j9
.@@j7:	;;;}
	mov	[edi+2],dx
	add	si,2
.@@j4:	cmp	si,bp
	jb	.@@j5
	;}
	pop	di
	;bp=nl end
	
	;process list & kill finished lines
	
	mov	[siend],bp
  ;TODO!
	;mov	ax,newdata1
	;mov	fs,ax
	mov	bp,[ndp]
	mov	dx,[yrow]
	mov	cx,8000h
	mov	esi,nl
	mov	edi,esi
	jmp	.@@j10
.@@j11:	mov	bx,[esi]
	cmp	dx,[ebx+NE_Y2]
	jge	.@@j12
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
	jle	.@@j15
	mov	ax,319
.@@j15:	cmp	ax,1
	jge	.@@j16
	mov	ax,1
.@@j16:	;
	cmp	cx,ax
	jne	.@@j14
	;same x pos
	mov	ax,[ebx+NE_COLOR]
	xor	[ebp-2],ax
	jmp	.@@j12
.@@j14:	;new x pos
	add	ax,[yrowad]
	mov	[ebp+0],ax
	mov	ax,[ebx+NE_COLOR]
	mov	[ebp+2],ax
	add	bp,4
	mov	cx,ax
.@@j12:	add	si,2
.@@j10:	cmp	si,[siend]
	jb	.@@j11
	mov	[ndp],bp
	
	pop	bp
	pop	cx
	inc	dword [yrow]
	add	dword [yrowad],320
	add	bp,2
	LOOP_LARGE	.@@j1
	mov	ebx,[ndp]
	mov	word [ebx+0],63999
	mov	word [ebx+2],0
	add	ebx,4
	mov	word [ebx+0],-1
	mov	word [ebx+2],0
	add	ebx,4
	mov	[ndp],bx
	ret

global __newgroup
__newgroup:
	;es:di=polygroup
	;sides,color,x,y,x,y,x,y,...
	;sides=0=end
	cmp	ax,0
	jne	.@@jng1
	call	ng_init
	ret
.@@jng1:	cmp	ax,1
	je	.@@jng2
	setborder 2
	call	ng_pass2
	setborder 3
	call	ng_pass3
	ret
.@@jng2:	setborder 1

	;add polygons to list
	mov	bp,[nec]
.@@j2:	mov	cx,[edi] ;sides
	cmp	cx,0
	je	.@@j1
	mov	ax,[edi+2] ;color
	mov	[tmp_color],ax
	mov	si,di
	add	di,4
	mov	[tmp_firstvx],di
.@@j3:	add	si,4
	add	di,4
	cmp	cx,1
	jne	.@@j4
	mov	di,[tmp_firstvx]
.@@j4:	push	cx
	;dx=color, si->start, di->end
	mov	ax,[tmp_color]
	mov	[ebp+NE_COLOR],ax
	mov	bx,[esi+2] ;y1
	mov	cx,[edi+2] ;y2
	cmp	bx,cx 
	jg	.@@ji1	;y1>y2
	mov	ax,[esi+0] ;x1
	mov	dx,[edi+0] ;x2
	jmp	.@@ji0
.@@ji1:	xchg	bx,cx
	mov	ax,[edi+0] ;x1
	mov	dx,[esi+0] ;x2	
.@@ji0:	;ax,bx=xy1  dx,cx=xy2
.@@ji9:	mov	[ebp+NE_Y1],bx
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
	je	.@@jn1 ;skip horizontal lines
	movzx	ecx,cx
	idiv	ecx
	mov	[ebp+NE_DX],eax
	;!!!if y1<0, clip
	cmp	bx,0
	jge	.@@jnc
	mov	dx,[ebp+NE_Y2]
	cmp	dx,0
	jle	.@@jn1
	neg	bx
	movzx	ebx,bx
	imul	ebx
	add	[ebp+NE_X],eax
	xor	bx,bx
	mov	[ebp+NE_Y1],bx
.@@jnc:	;!!!
	shl	bx,1
	mov	ax,[nep+ebx]
	or	ax,ax
	jnz	.@@jj1
	;first on this row
	mov	[nep+ebx],bp
	mov	word [ebp+NE_NEXT],0
	jmp	.@@jj0	
.@@jj1:	;add to this row
	;scan if already exists
	push	ax
	push	si
	mov	si,ax
	jmp	.@@jh11
.@@jh1:	mov	si,[esi+NE_NEXT]
.@@jh11:	mov	ax,[ebp+NE_Y2]
	cmp	ax,[esi+NE_Y2]
	jne	.@@jh2
	mov	eax,[ebp+NE_X]
	cmp	eax,[esi+NE_X]
	jne	.@@jh2
	mov	eax,[ebp+NE_DX]
	cmp	eax,[esi+NE_DX]
	jne	.@@jh2
	;duplicate line SI
	mov	al,[ebp+NE_COLOR]
	xor	[esi+NE_COLOR],al
	pop	si
	pop	ax
	jmp	.@@jn1
.@@jh2:	cmp	si,0
	jne	.@@jh1 ;end of list
.@@jh3:	pop	si
	pop	ax
	mov	[nep+ebx],bp
	mov	word [ebp+NE_NEXT],ax
.@@jj0:	add	bp,16
.@@jn1:	;next
	pop	cx
	LOOP_LARGE	.@@j3
	add	si,4
	mov	di,si
	jmp	.@@j2

.@@j1:	mov	[nec],ebp
	sub	ebp,ne
	shr	ebp,4
	mov	[__ndebug1],ebp

	ret
