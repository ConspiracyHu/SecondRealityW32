;/****************************************************************************
;** MODULE:	adrawclp.asm
;** AUTHOR:	Sami Tammilehto / Fennosoftec OY
;** DOCUMENT:	?
;** VERSION:	1.0
;** REFERENCE:	-
;** REVISED BY:	-
;*****************************************************************************
;**
;** Polygon clipping (included to adraw.asm)
;** All routines take DS:SI as an entry list and write a clipped list to
;** ES:DI. The clipnear also returns in AX the orred visvf for the clipped
;** polygon since it might change during Z clipping.
;**
;****************************************************************************/

%include "a.inc"

section .data
newclipflip db 0,0
newclipprog dd 0
clipcount dw	0
clipzero dd	0
clipvisfl dw	0
vxseg dd	0

section .code
newclip_grd:
	;DS:BX->DS:SI is clipped at CX (BX end=0..16384=SI end)
	;resulted clip stored to ES:DI
	mov	ax,[ebx+POLYGR]
	sub	ax,[esi+POLYGR]
	imul	cx
	shld	dx,ax,2
	add	dx,[esi+POLYGR]
	mov	[edi+POLYGR],dx
	ret

	
%macro NEWCLIPCALC 2 ;clipped,other
	;local	l1,l2,l3,l4,l5,l6
	;DS:BX->DS:SI is clipped at (-,BP) with result stored to DS:DI
	push	esi
	push	ebx
	push	ebp
	mov	dx,[esi+%2]
	mov	cx,[esi+%1]
	mov	ax,[ebx+%2]
	mov	bx,[ebx+%1]
	mov	byte [newclipflip],0
	cmp	cx,bx
	jl	%%l3
	mov	byte [newclipflip],1
	xchg	cx,bx
	xchg	ax,dx
%%l3:	push	edx
	sub	bp,cx
	sub	ax,dx
	push	eax
	mov	dx,bp
	xor	ax,ax
	shrd	ax,dx,2
	sar	dx,2
	;dx:ax=short length*16384
	sub	bx,cx
	idiv	bx
	mov	bx,ax
	;bx=0..16384 multiplier 
	pop	eax
	imul	bx
	shld	dx,ax,2
	pop	eax
	add	dx,ax ;dx=clipped other
	pop	ebp
	mov	cx,bp
	cmp	[edi+%2-4],dx
	jne	%%l1
	cmp	[edi+%1-4],cx
	jne	%%l1
	jmp	%%l2
%%l1:	mov	[edi+%2],dx
	mov	[edi+%1],cx
	mov	cx,bx
	pop	ebx
	mov	eax,[newclipprog]
	or	eax,eax
	jz	%%l4
	mov	dl,[newclipflip]
	or	dl,dl
	jz	%%l6
	xchg	si,bx
%%l6:	call	eax ;also stores gouraud&texture clipped
%%l4:	add	edi,4
	jmp	%%l5
%%l2:	pop	ebx
%%l5:	pop	esi
%endmacro

%macro NEWCLIPNEXT 0 ;sets bx(last)=si(current) and loads si with next vertex
	;local	l1,l2
	mov	bx,si
	mov	dx,[clipcount]
	dec	dx
	cmp	dx,1
	jl	@@0 ;list ended, jmp to end of clip procedure
	mov	[clipcount],dx
	jg	%%l1
	;1 vertex left, means we rotated the list
	mov	esi,[clipzero]
	jmp	%%l2
%%l1:	add	si,4
%%l2:
%endmacro

%macro NEWCLIPCOPY 0 ;should copy also texture
	;local	l1
	mov	eax,[esi+POLYX] ;&POLYY
	cmp	[edi+POLYX-4],eax
	je	%%l1
	mov	[edi+POLYX],eax
	mov	ax,[esi+POLYGR]
	mov	[edi+POLYGR],ax
	add	di,4
%%l1:
%endmacro

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	
%macro ZCLIPCLIP 0
	;local	l1,l41,l42,l43,l44
	;(fs:bp)-(fs:bx) is clipped at (-,-,ECX) with result stored to (DX,CX) & AX=visfl
	push	ebx
	push	ebp
	push	esi
	push	edi
	push	ecx
	;

  ; simulate FS
  mov eax, [vxseg]
  add ebx, eax
  add ebp, eax

	mov	eax,[ebx+vlist_z] ;fs
	mov	edx,[ebp+vlist_z] ;fs
	cmp	eax,edx
	jg	%%l1
	xchg	eax,edx
	xchg	ebx,ebp
%%l1:	;EAX=farther vertex (>EDX), BX=offset of farther vertex
	mov	esi,eax
	mov	edi,eax
	sub	esi,edx ;>=0 divver
	sub	edi,ecx ;>=0 muller, esi>edi
	;
	mov	eax,[ebp+vlist_x] ;fs
	sub	eax,[ebx+vlist_x] ;fs
	imul	edi
	idiv	esi
	add	eax,[ebx+vlist_x] ;fs
	push	eax
	;
	mov	eax,[ebp+vlist_y] ;fs
	sub	eax,[ebx+vlist_y] ;fs
	imul	edi
	idiv	esi
	add	eax,[ebx+vlist_y] ;fs
	;
	pop	esi ;X
	pop	ecx ;cliplimit
	xor	edi,edi
	;
	imul	dword [_projmuly]
	idiv	ecx
	add	eax,[_projaddy]
	cmp	eax,[_projclipy+CLIPMAX]
	jng	%%l41
	or	di,VF_DOWN
%%l41:	cmp	eax,[_projclipy+CLIPMIN]
	jnl	%%l42
	or	di,VF_UP
%%l42:	push	ax
	;
	mov	eax,esi
	imul	dword [_projmulx]
	idiv	ecx
	add	eax,[_projaddx]
	cmp	eax,[_projclipx+CLIPMAX]
	jng	%%l43
	or	di,VF_RIGHT
%%l43:	cmp	eax,[_projclipx+CLIPMIN]
	jnl	%%l44
	or	di,VF_LEFT
%%l44:	;
	mov	dx,ax
	mov	ax,di
	pop	cx
	;dx=x,cx=y,ax=visfl
	pop	edi
	pop	esi
	pop	ebp
	pop	ebx
	;NOTE: ECX was destroyed while clipping. It is used to return data.
	;It must be pushed by the 'calling' procedure after the macro and
	;the usage of the data the macro returned!
%endmacro 

%macro ZCLIPGETVX 0 ;reads to bx the offset of next vertex from DS:SI (copies last vx to bp) 
	;local	l1,l2
	mov	ebp,ebx
	movzx	edx, word [clipcount]
	dec	edx
	cmp	edx,1
	jl	@@0 ;list ended, jmp to end of clip procedure
	mov	[clipcount],dx
	jg	%%l1
	;1 vertex left, means we rotated the list
	mov	esi,[clipzero]
	jmp	%%l2
%%l1:	add	esi,4
%%l2:	movzx	ebx, word [esi+POLYVX]
%endmacro 

%macro ZCLIPADDVISVX 0 ;adds ds:si[bx+POLYX/Y] to list (the vx must be visible for this to work) at DS:DI
	;local	l1,l2
  push eax
	mov	dx,[esi+POLYX]
	mov	ax,[esi+POLYY]
	cmp	[edi+POLYX-4],dx
	jne	%%l1
	cmp	[edi+POLYY-4],ax
	jne	%%l1
	jmp	%%l2
%%l1:	mov	[edi+POLYX],dx
	mov	[edi+POLYY],ax
	mov	ax,[esi+POLYGR]
	mov	[edi+POLYGR],ax
	add	edi,4
  pop eax
%%l2:	;;;
%endmacro

%macro ZCLIPADDVX 0 ;adds (DX,CX) to list at DS:DI
	;local	l1,l2
  push eax
	cmp	[edi+POLYX-4],dx
	jne	%%l1
	cmp	[edi+POLYY-4],cx
	jne	%%l1
	jmp	%%l2
%%l1:	mov	[edi+POLYX],dx
	mov	[edi+POLYY],cx
	mov	ax,[edi-4+POLYGR]
	mov	[edi+POLYGR],ax
	add	edi,4
  pop eax
%%l2:	;;;
%endmacro 

clipnear:
	;clips list DS:SI -> DS:DI (source list must NOT be empty)
	push	ebp
	push	esi
	push	edi
	mov	[clipzero],esi
	mov	ecx,[_projclipz+CLIPMIN] ;ECX=cliplimit
	mov	eax,[esi+POLYSIDES] ;&POLYCOLOR
	mov	[edi+POLYSIDES],eax
	inc	eax
	mov	[clipcount],ax
	mov	eax,[esi+POLYFLAGS] ;&POLYVXSEG
	mov	[edi+POLYFLAGS],eax
	mov	eax,[esi+POLYVXSEG] ;&POLYVXSEG
	mov	[edi+POLYVXSEG],eax
	mov	[vxseg],eax

	mov	word [edi+POLYX-4],07fffh ;for CLIPADDVX to surely do it's work

  push ebp
  mov	ebp,[vxseg]
	movzx	ebx,word [esi+POLYVX]
	cmp	ecx,[ebp+ebx+vlist_z] ;fs
	jle	@@2

@@1:	;LAST POINT HIDDEN
  pop ebp
	ZCLIPGETVX ; <- can jump to @@0

  push ebp
  mov	ebp,[vxseg]

	cmp	ecx,[ebp+ebx+vlist_z] ;fs
	jge	@@1

  pop ebp
	;this point visible, clip
	ZCLIPCLIP ;returns data in cx
	or	[clipvisfl],ax
	ZCLIPADDVX
	mov	ecx,[_projclipz+CLIPMIN] ;ECX was destroyed by ZCLIPCLIP
	
@@2:	;LAST POINT VISIBLE
  pop ebp

	ZCLIPADDVISVX
	ZCLIPGETVX ; <- can jump to @@0

  push ebp
  mov	ebp,[vxseg]

	cmp	ecx,[ebp+ebx+vlist_z] ;fs

	jle	@@2

  pop ebp

	;this point hidden, clip
	ZCLIPCLIP ;returns data in cx
	or	[clipvisfl],ax
	ZCLIPADDVX
	mov	ecx,[_projclipz+CLIPMIN] ;ECX was destroyed by ZCLIPCLIP

  push ebp
  mov	ebp,[esi+POLYVXSEG]

	jmp	@@1 ;to hidden

@@0:	pop	ebx
	sub	edi,ebx
	shr	edi,2
	mov	[ebx+POLYSIDES],di ;Sides in clipped polygon
	mov	edi,ebx
	pop	esi
	pop	ebp
	movzx	eax,word [clipvisfl]
	ret


;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

newclipup:
	;clips list DS:SI -> DS:DI (source list must NOT be empty)
	push	ebp
	push	esi
	push	edi
	mov	[clipzero],esi
	mov	bp,word [_projclipy+CLIPMIN]
	mov	eax,[esi+POLYSIDES] ;&POLYCOLOR
	mov	[edi+POLYSIDES],eax
	inc	ax
	mov	[clipcount],ax
	mov	eax,[esi+POLYFLAGS] ;&POLYVXSEG
	mov	[edi+POLYFLAGS],eax
	mov	eax,[esi+POLYVXSEG] ;&POLYVXSEG
	mov	[edi+POLYVXSEG],eax
	
	mov	word [edi+POLYX-4],07fffh ;for CLIPADDVX to surely do it's work

	;bx=last, si=current
	cmp	[esi+POLYY],bp
	jge	@@2
	
@@1:	;LAST POINT HIDDEN
	NEWCLIPNEXT
	cmp	[esi+POLYY],bp
	jle	@@1
	;this point visible, clip
	NEWCLIPCALC POLYY,POLYX
	
@@2:	;LAST POINT VISIBLE
	NEWCLIPCOPY ;copies always also texture & gouraud
	NEWCLIPNEXT
	cmp	[esi+POLYY],bp
	jge	@@2
	;this point hidden, clip
	NEWCLIPCALC POLYY,POLYX
	jmp	@@1 ;to hidden

@@0:	pop	ebx
	sub	edi,ebx
	shr	edi,2
	mov	[ebx+POLYSIDES],di ;Sides in clipped polygon
	mov	edi,ebx
	pop	esi
	pop	ebp
	ret


newclipdown:
	;clips list DS:SI -> DS:DI (source list must NOT be empty)
	push	ebp
	push	esi
	push	edi
	mov	[clipzero],esi
	mov	bp,word [_projclipy+CLIPMAX]
	mov	eax,[esi+POLYSIDES] ;&POLYCOLOR
	mov	[edi+POLYSIDES],eax
	inc	ax
	mov	[clipcount],ax
	mov	eax,[esi+POLYFLAGS] ;&POLYVXSEG
	mov	[edi+POLYFLAGS],eax
	mov	eax,[esi+POLYVXSEG] ;&POLYVXSEG
	mov	[edi+POLYVXSEG],eax
	
	mov	word [edi+POLYX-4],07fffh ;for CLIPADDVX to surely do it's work

	;bx=last, si=current
	cmp	[esi+POLYY],bp
	jle	@@2
	
@@1:	;LAST POINT HIDDEN
	NEWCLIPNEXT
	cmp	[esi+POLYY],bp
	jge	@@1
	;this point visible, clip
	NEWCLIPCALC POLYY,POLYX
	
@@2:	;LAST POINT VISIBLE
	NEWCLIPCOPY ;copies always also texture & gouraud
	NEWCLIPNEXT
	cmp	[esi+POLYY],bp
	jle	@@2
	;this point hidden, clip
	NEWCLIPCALC POLYY,POLYX
	jmp	@@1 ;to hidden

@@0:	pop	ebx
	sub	edi,ebx
	shr	edi,2
	mov	[ebx+POLYSIDES],di ;Sides in clipped polygon
	mov	edi,ebx
	pop	esi
	pop	ebp
	ret

	
newclipleft:
	;clips list DS:SI -> DS:DI (source list must NOT be empty)
	push	ebp
	push	esi
	push	edi
	mov	[clipzero],esi
	mov	bp,word [_projclipx+CLIPMIN]
	mov	eax,[esi+POLYSIDES] ;&POLYCOLOR
	mov	[edi+POLYSIDES],eax
	inc	ax
	mov	[clipcount],ax
	mov	eax,[esi+POLYFLAGS] ;&POLYVXSEG
	mov	[edi+POLYFLAGS],eax
	mov	eax,[esi+POLYVXSEG] ;&POLYVXSEG
	mov	[edi+POLYVXSEG],eax
	
	mov	word [edi+POLYX-4],07fffh ;for CLIPADDVX to surely do it's work

	;bx=last, si=current
	cmp	[esi+POLYX],bp
	jge	@@2
	
@@1:	;LAST POINT HIDDEN
	NEWCLIPNEXT
	cmp	[esi+POLYX],bp
	jle	@@1
	;this point visible, clip
	NEWCLIPCALC POLYX,POLYY
	
@@2:	;LAST POINT VISIBLE
	NEWCLIPCOPY ;copies always also texture & gouraud
	NEWCLIPNEXT
	cmp	[esi+POLYX],bp
	jge	@@2
	;this point hidden, clip
	NEWCLIPCALC POLYX,POLYY
	jmp	@@1 ;to hidden

@@0:	pop	ebx
	sub	edi,ebx
	shr	edi,2
	mov	[ebx+POLYSIDES],di ;Sides in clipped polygon
	mov	edi,ebx
	pop	esi
	pop	ebp
	ret


newclipright:
	;clips list DS:SI -> DS:DI (source list must NOT be empty)
	push	ebp
	push	esi
	push	edi
	mov	[clipzero],esi
	mov	bp,word [_projclipx+CLIPMAX]
	mov	eax,[esi+POLYSIDES] ;&POLYCOLOR
	mov	[edi+POLYSIDES],eax
	inc	ax
	mov	[clipcount],ax
	mov	eax,[esi+POLYFLAGS] ;&POLYVXSEG
	mov	[edi+POLYFLAGS],eax
	mov	eax,[esi+POLYVXSEG] ;&POLYVXSEG
	mov	[edi+POLYVXSEG],eax
	
	mov	word [edi+POLYX-4],07fffh ;for CLIPADDVX to surely do it's work

	;bx=last, si=current
	cmp	[esi+POLYX],bp
	jle	@@2
	
@@1:	;LAST POINT HIDDEN
	NEWCLIPNEXT
	cmp	[esi+POLYX],bp
	jge	@@1
	;this point visible, clip
	NEWCLIPCALC POLYX,POLYY
	
@@2:	;LAST POINT VISIBLE
	NEWCLIPCOPY ;copies always also texture & gouraud
	NEWCLIPNEXT
	cmp	[esi+POLYX],bp
	jle	@@2
	;this point hidden, clip
	NEWCLIPCALC POLYX,POLYY
	jmp	@@1 ;to hidden

@@0:	pop	ebx
	sub	edi,ebx
	shr	edi,2
	mov	[ebx+POLYSIDES],di ;Sides in clipped polygon
	mov	edi,ebx
	pop	esi
	pop	ebp
	ret

global newclip
newclip:
	;ENTRY:
	;ds:si=pointer to list to be clipped
	;ds:di=pointer to temporary list
	;dx=visibility flag for polygon
	;ax=flags for polygon (determines if texture and/or gouraud is clipped)
	;EXIT:
	;ds:si=clipped list (could be either of the entry lists)
	xor	ebx,ebx
	test	ax,F_GOURAUD
	jz	@@f1
	mov	ebx,newclip_grd
@@f1:	mov	[newclipprog],ebx
	;
	LOADGS
	test	dh,VF_FAR	;If *ANY* vertex is 'far', entire polygon is
	jnz	@@cl7		;skipped (no clipping visible far away)
	test	dl,VF_NEAR 	;ClipNear must be done first, for in NEAR case 
	jz	@@cl6		;not all vertices are even calculated!
	cmp	word [esi+POLYSIDES],0
	je	@@cl6
	push	edx
	call	clipnear
	xchg	esi,edi
	pop	edx	;  clipnear return in ax the visfl for new vertices. 
	or	dl,al 	;<-this is done so that if the new vertices are outside the screen they'll be clipped
@@cl6:	;
	test	dl,VF_UP
	jz	@@cl1
	cmp	word [esi+POLYSIDES],0
	je	@@cl1
	push	dx
	call	newclipup
	xchg	si,di
	pop	dx
@@cl1:	;
	test	dl,VF_DOWN
	jz	@@cl2
	cmp	word [esi+POLYSIDES],0
	je	@@cl2
	push	dx
	call	newclipdown
	xchg	si,di
	pop	dx
@@cl2:	;
	test	dl,VF_LEFT
	jz	@@cl3
	cmp	word [esi+POLYSIDES],0
	je	@@cl3
	push	dx
	call	newclipleft
	xchg	si,di
	pop	dx
@@cl3:	;
	test	dl,VF_RIGHT
	jz	@@cl4
	cmp	word [esi+POLYSIDES],0
	je	@@cl4
	push	dx
	call	newclipright
	xchg	si,di
	pop	dx
	;
@@cl4:	ret
@@cl7:	;polygon marked invisible:
	mov	word [esi+POLYSIDES],0
	ret


