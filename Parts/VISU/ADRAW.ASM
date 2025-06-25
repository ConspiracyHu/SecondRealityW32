;/****************************************************************************
;** MODULE:	adraw.asm
;** AUTHOR:	Sami Tammilehto / Fennosoftec OY
;** DOCUMENT:	?
;** VERSION:	1.0
;** REFERENCE:	-
;** REVISED BY:	-
;*****************************************************************************
;**
;** Object drawing (and polygon calculations & clipping (included))
;**
;****************************************************************************/

%include "a.inc"

extern newclip

section .data

;ALIGN 2
newlight dw	12118,10603,3030

section .code

;entry: AX=polyflags,ES:DI=normal for which to calculate light
; exit:	AX=colorshade (based 0)
calclight:
	and	ax,F_SHADE32 ;=F_SHADE* orred together)
	jz	@@nc
	;lightsource
	push	ax
	call	normallight
	pop	dx
	shr	dx,10
	mov	cx,6
	sub	cx,dx
	shr	ax,cl ;0400=5, 0800=4, 0C00=3
@@mm:	cmp	ax,1
	jg	@@m1
	mov	ax,1
@@m1:	cmp	ax,30
	jl	@@m2
	mov	ax,30
@@m2:	ret
@@nc:	xor	ax,ax
	jmp	@@mm


normallight:
	;return: ax=relative brightness 0..255
	push	bp
	mov	ax,[edi+nlist_x]
	imul	word [newlight+0]
	mov	bp,ax
	mov	cx,dx
	mov	ax,[edi+nlist_y]
	imul	word [newlight+2]
	add	bp,ax
	adc	cx,dx
	mov	ax,[edi+nlist_z]
	imul	word [newlight+4]
	add	ax,bp
	adc	dx,cx
	mov	ax,dx
	sar	ax,2*unitshr-7-16
	add	ax,128
	cmp	ax,255
	jle	@@1
	mov	ax,255
@@1:	cmp	ax,0
	jge	@@2
	mov	ax,0
@@2:	pop	bp
	ret ;ax=0..255


checkculling:
	;es:di=normal
	;fs:si=vertex
	;ret: carry=1=hidden
	push	ebp
	movsx	eax,word [edi+nlist_x]
	imul	dword [esi+vlist_x]
	mov	ebp,eax
	mov	ecx,edx
	movsx	eax,word [edi+nlist_y]
	imul	dword [esi+vlist_y]
	add	ebp,eax
	adc	ecx,edx
	movsx	eax,word [edi+nlist_z]
	imul	dword [esi+vlist_z]
	add	ebp,eax
	adc	ecx,edx
	rcl	ecx,1 ;if cx<0, carry=1=visible
	cmc	;now carry=1 when invisible
	pop	ebp
	ret

section .data

;ALIGN 16
poly1:	;LABEL WORD
	times POLYSIZE db	0
;ALIGN; 16
poly2:	;LABEL WORD
	times POLYSIZE db	0

;%include "adrawclp.asm"

section .data
;ALIGN 16

extern _vid_drawfill
drawfill_routine dd	_vid_drawfill
drawfill_routine0 dd	_vid_drawfill ;nrm ;original (=NULL)

polyomin dw	0
polyomax dw	0
polycury dw	0
polylhig dw	0
polyrhig dw	0
polyoversample16 db 0
polyoversamplea db 0
polyoversamples db 0
polyoversample db 0

section .code

%macro POLYSIDECALC 2 ;fr,to
	;local	l1,l2
	;when entering, AX should be heigth
	push	ax
	mov	word [ebp-2],07777h
	movsx	edx,word [%1+POLYX]
	movzx	ecx,byte [polyoversample16] ;sets ECX hi to zero
	shl	edx,cl
	mov	dx,32768 ;NOOVERSAMPLECENTER
	mov	[ebp+0],edx ;Xstart
	movsx	eax,word [%2+POLYX]
	shl	eax,cl
	mov	ax,32768 ;NOOVERSAMPLECENTER
	sub	eax,edx
	cdq
	pop	cx
	idiv	ecx
	mov	cl,byte [polycury]
	and	cl,[polyoversamplea]
	jz	%%l1
%%l2:	sub	[ebp+0],eax
	dec	cl
	jnz	%%l2
%%l1:	mov	cl,[polyoversample]
	shl	eax,cl
	mov	[ebp+4],eax ;Xadd
	add	bp,8
%endmacro

poly_nrm:
	;handles a normal polygon (preclipped one)
	;polydata at DS:SI. SIDES must be >=3
	;drawing orders written to ES:DI
	;-------Calculate bounds for SI
	mov	bx,[esi+POLYSIDES]
	shl	bx,2
	lea	ax,[bx-4+si]
	mov	[polyomax],ax
	mov	[polyomin],si
	;the SI should always be in range POLYOMIN..POLYOMAX
	;-------Find uppermost vertex in polygon
	push	si
	mov	bx,si
	mov	dx,[esi+POLYY]
	mov	bp,dx
	mov	cx,[esi+POLYSIDES]
.11:	add	si,4
	dec	cx
	jz	.2
.1:	mov	ax,[esi+POLYY]
	cmp	ax,bp
	jle	.13
	mov	bp,ax
.13:	cmp	ax,dx
	jge	.11
	mov	dx,ax
	mov	bx,si
	jmp	.11
.2:	mov	cx,bp
	;DS:BX=uppermost vertex, DX=uppermost Y, CX=lowermost Y
	mov	[polycury],dx
	pop	si
	;-------Write the startup info to drawinfo
	push	cx
	mov	bp,di ;es:di was to drawinfo, now ES:BP is
	mov	ax,[esi+POLYCOLOR]
	mov	[ebp],ax
	mov	cl,[polyoversample]
	mov	ax,dx
	sar	ax,cl
	mov	[ebp+2],ax
	add	bp,4+2
	pop	cx
	cmp	dx,cx
	je	.d0 ;heigth zero, nothing to do
	sub	bp,2
	;-------Set up SI for left edge (--), DI for right edge (++)
	mov	si,bx
	mov	di,bx
	;-------Loop
.l1:	mov	word [ebp],0
	add	bp,2
	mov	ax,[esi+POLYY]
	cmp	ax,[polycury]
	jne	.a2
.a4:	;Left side reload
	lea	bx,[si-4] ;BX=SI--
	cmp	bx,[polyomin]
	jge	.a1
	mov	bx,[polyomax]
.a1:	mov	ax,[ebx+POLYY]
	sub	ax,[esi+POLYY]
	jc	.d0 ;turned upwards, end of polygon
	jnz	.a3
	mov	si,bx
	jmp	.a4
.a3:	mov	[polylhig],ax
	POLYSIDECALC si,bx
	mov	si,bx
.a2:	;
	mov	word [ebp],0
	add	bp,2
	mov	ax,[edi+POLYY]
	cmp	ax,[polycury]
	jne	.b2
.b4:	;Right side reload
	lea	bx,[di+4] ;BP=DI++
	cmp	bx,[polyomax]
	jle	.b1
	mov	bx,[polyomin]
.b1:	mov	ax,[ebx+POLYY]
	sub	ax,[edi+POLYY]
	jc	.d0 ;turned upwards, end of polygon
	jnz	.b3
	mov	di,bx
	jmp	.b4
.b3:	mov	[polyrhig],ax
	POLYSIDECALC di,bx
	mov	di,bx
.b2:	;	
	mov	ax,[polylhig]
	cmp	ax,[polyrhig]
	jl	.c1
	;right shorter
	mov	ax,[polyrhig]
.c1:	;AX=shorter
	mov	cl,[polyoversample]
	mov	dx,ax
	sar	dx,cl
	mov	[ebp],dx ;Ycount
	sub	[polylhig],ax
	sub	[polyrhig],ax
	add	bp,2
	add	[polycury],ax
	jmp	.l1
	
.d0:	mov	word [ebp-2],0ffffh
	ret


%macro POLYSIDECALC_GRD 2 ;fr,to
	;local	l1,l2
	;when entering, AX should be heigth
	push	ax
	mov	word [ebp-2],07777h
	;
	mov	cx,ax
	mov	ax,word [%2+POLYGR]
	mov	dx,word [%1+POLYGR]
	mov	[ebp+0],dx ;COLORstart
	sub	ax,dx
	cwd
	idiv	cx
	mov	[ebp+2],ax ;COLORadd
	;
	movsx	edx,word [%1+POLYX]
	xor	ecx,ecx
	mov	cl,byte [polyoversample16]
	shl	edx,cl
	mov	dx,32768 ;NOOVERSAMPLECENTER
	mov	[ebp+4],edx ;Xstart
	movsx	eax,word [%2+POLYX]
	shl	eax,cl
	mov	ax,32768 ;NOOVERSAMPLECENTER
	sub	eax,edx
	cdq
	pop	cx
	idiv	ecx
	mov	cl,byte [polycury]
	and	cl,[polyoversamplea]
	jz	%%l1
%%l2:	sub	[ebp+0],eax
	dec	cl
	jnz	%%l2
%%l1:	mov	cl,[polyoversample]
	shl	eax,cl
	mov	[ebp+8],eax ;Xadd
	add	bp,12
%endmacro 

poly_grd:
	;handles a gouraud polygon (preclipped one)
	;polydata at DS:SI. SIDES must be >=3
	;drawing orders written to ES:DI
	;-------Calculate bounds for SI
	mov	bx,[esi+POLYSIDES]
	shl	bx,2
	lea	ax,[bx-4+si]
	mov	[polyomax],ax
	mov	[polyomin],si
	;the SI should always be in range POLYOMIN..POLYOMAX
	;-------Find uppermost vertex in polygon
	push	si
	mov	bx,si
	mov	dx,[esi+POLYY]
	mov	bp,dx
	mov	cx,[esi+POLYSIDES]
@@11:	add	si,4
	dec	cx
	jz	@@2
@@1:	mov	ax,[esi+POLYY]
	cmp	ax,bp
	jle	@@13
	mov	bp,ax
@@13:	cmp	ax,dx
	jge	@@11
	mov	dx,ax
	mov	bx,si
	jmp	@@11
@@2:	mov	cx,bp
	;DS:BX=uppermost vertex, DX=uppermost Y, CX=lowermost Y
	mov	[polycury],dx
	pop	si
	;-------Write the startup info to drawinfo
	push	cx
	mov	bp,di ;es:di was to drawinfo, now ES:BP is
	mov	ax,[esi+POLYCOLOR]
	mov	[ebp],ax
	mov	cl,[polyoversample]
	mov	ax,dx
	sar	ax,cl
	mov	[ebp+2],ax
	add	bp,4+2
	pop	cx
	cmp	dx,cx
	je	@@d0 ;heigth zero, nothing to do
	sub	bp,2
	;-------Set up SI for left edge (--), DI for right edge (++)
	mov	si,bx
	mov	di,bx
	;-------Loop
@@l1:	mov	word [ebp],0
	add	bp,2
	mov	ax,[esi+POLYY]
	cmp	ax,[polycury]
	jne	@@a2
@@a4:	;Left side reload
	lea	bx,[si-4] ;BX=SI--
	cmp	bx,[polyomin]
	jge	@@a1
	mov	bx,[polyomax]
@@a1:	mov	ax,[ebx+POLYY]
	sub	ax,[esi+POLYY]
	jc	@@d0 ;turned upwards, end of polygon
	jnz	@@a3
	mov	si,bx
	jmp	@@a4
@@a3:	mov	[polylhig],ax
	POLYSIDECALC_GRD si,bx
	mov	si,bx
@@a2:	;
	mov	word [ebp],0
	add	bp,2
	mov	ax,[edi+POLYY]
	cmp	ax,[polycury]
	jne	@@b2
@@b4:	;Right side reload
	lea	bx,[di+4] ;BP=DI++
	cmp	bx,[polyomax]
	jle	@@b1
	mov	bx,[polyomin]
@@b1:	mov	ax,[ebx+POLYY]
	sub	ax,[edi+POLYY]
	jc	@@d0 ;turned upwards, end of polygon
	jnz	@@b3
	mov	di,bx
	jmp	@@b4
@@b3:	mov	[polyrhig],ax
	POLYSIDECALC_GRD di,bx
	mov	di,bx
@@b2:	;	
	mov	ax,[polylhig]
	cmp	ax,[polyrhig]
	jl	@@c1
	;right shorter
	mov	ax,[polyrhig]
@@c1:	;AX=shorter
	mov	cl,[polyoversample]
	mov	dx,ax
	sar	dx,cl
	mov	[ebp],dx ;Ycount
	sub	[polylhig],ax
	sub	[polyrhig],ax
	add	bp,2
	add	[polycury],ax
	jmp	@@l1
	
@@d0:	mov	word [ebp-2],0ffffh
	ret


;北北北北 _draw_setfillroutine(void (*fillroutine)(int *)) 北北北北
;entry:	Pointer to a routine to handle polygon filling
; exit: - 
;descr: The specified function will be called for each polygon drawed
;	with a pointer to {NORMAL-FILL-DATA} of the polygon.
_draw_setfillroutine:
	CBEG
	movpar	eax,0
	or	ax,ax
	jnz	@@1
	mov	eax,[drawfill_routine0]
@@1:	mov	dword [drawfill_routine],eax
	CEND


;北北北北 _draw_polylist(polylist *l,polydata *d,vlist *v,pvlist *pv,
;                                                      nlist *n,int f) 北北北北
;entry:	0 l=pointer to a polygon list (in polylist format)
;	2 d=pointer to polygon data (to which polylist points using indices)
;	4 v=pointer to rotated 3D vertices (for 3D clipping)
;	6 pv=pointer to projected vertices (for drawing)
;	8 n=pointer to normals (for culling)
;	10 f=object flags
; exit: -
;descr: draw the contents of the polylist.
_draw_polylist:
	CBEG
	movpar	eax,5
	test	eax,1
	jz	@@invi ;F_VISIBLE not set
	;set poly oversampling
	mov	eax,16
	mov	ecx,[_projoversampleshr]
	mov	[polyoversample],cl
	sub	eax,ecx
	mov	[polyoversample16],al
	mov	al,1
	shl	al,cl
	mov	[polyoversamples],al
	dec	al
	mov	[polyoversamplea],al
	;start with the actual work
	movpar	esi,0
	add	esi,4 ;skip count - sort vertex
@@1:
  ;movpar	ds,0+1
	push	esi
	movzx	esi, word [esi]
	cmp	si,0
	je	@@0 ;end of list
	movpar	eax,2
	add	esi,eax
	;movpar	ds,2+1
	;ds:si points to polydata/polygon we are now drawing
	mov	cx,[esi+0]
	movpar	eax,5
	or	eax,0f00h
	and	eax,ecx
	mov	[poly1+POLYFLAGS],ax
	and	ecx,0ffh
	mov	[poly1+POLYSIDES],cx
	push	esi
	movzx	eax, word [esi+4] ;normal
	movzx	ebx, word [esi+6] ;first point
	cmp	word [esi+2],-1 ;color
	je 	@@cull2
	shl	ebx,vlist_sizeshl
	lfspar	esi,2 ;rotated vertices
	add	esi,ebx
	mov	ebx,eax ;normal
	shl	ebx,nlist_sizeshl
	lespar	edi,4 ;rotated normals
	add	edi,ebx
	test	word [poly1+POLYFLAGS],F_2SIDE
	jnz	@@2side
	call	checkculling
	pop	esi
	jc	@@cull
	jmp	@@nocl
@@cull2: pop	esi
	jmp	@@cull
	;es:di=still normal
@@2side: pop	esi	
@@nocl:	;lightsource
	mov	ax,[poly1+POLYFLAGS]
	test	eax,F_GOURAUD
	jnz	@@nosh
	call	calclight
	add	al,[esi+2]
	mov	byte [poly1+POLYCOLOR],al
	jmp	@@yosh
@@nosh:	mov	al,[esi+2]
	mov	byte [poly1+POLYCOLOR],al
@@yosh:	;
	mov	cx,[poly1+POLYSIDES]
	lespar	edi,3 ;projected vertices
	mov	dx,0ff00h ;for vf calc
	push	ebp
	movpar	eax,2
	;movpar	bp,4+0
	xchg	ebp,edi
	mov	[poly1+POLYVXSEG],eax
	;ds:bp=projected vertices
	;??:di=rotated vertices
	%assign zzs 0
	%assign zzd 0
	%rep	MAXPOLYSIDES ;max sides in polygon
	movzx	ebx, word [esi+6+zzs]
	shl	bx,pvlist_sizeshl ;==vlist_sizeshl (required) [!!]
	lea	ax,[ebx+edi]
	mov	word [poly1+POLYVX+zzd],ax
	add	ebx,ebp
	mov	al,[ebx+pvlist_vf]
	and	dh,al ;if anded!=0, out of screen
	or	dl,al ;if orred!=0, must clip
	mov	eax,[ebx+pvlist_x]
	mov	dword [poly1+POLYX+zzd],eax
	dec	cx
	jz	@@2
	%assign zzs zzs+2
	%assign zzd zzd+4
	%endrep
@@2:
  pop	ebp
	push	ebp
	push	edx
	;gouraud color calcs
	mov	ax,[poly1+POLYFLAGS]
	test	ax,F_GOURAUD
	jz	@@nogr
	;
	mov	cx,[poly1+POLYSIDES]
	lespar	edi,4 ;rotated normals
  push eax
	mov	eax,[poly1+POLYVXSEG]
	mov	ebp,poly1
@@gr1:
  push	ecx
	push	edi
	movzx	ebx, word [POLYVX+ebp]
	movzx	ebx, word [eax+ebx+vlist_normal]
	shl	ebx,nlist_sizeshl
	add	edi,ebx
	;es:di=now normal for which to calculate
	mov	ax,[poly1+POLYFLAGS]
	call	calclight
	add	al,byte [poly1+POLYCOLOR]
	shl	ax,8
	mov	[POLYGR+ebp],ax
	pop	edi
	pop	ecx
	add	bp,4
	loop	@@gr1
	pop	eax
@@nogr:	;
	pop	edx
	pop	ebp
	LOADDS
	push	ebp
	;push	eds
	;mov	ax,cs
	;mov	ds,ax
	mov	esi,poly1
	or	dh,dh ;dh=visfl anded
	jnz	@@cl0 ;entire polygon invisible
	or	dl,dl ;dl=visfl orred
	jz	@@cl4 ;no clipping
	mov	edi,poly2
	mov	ax,[esi+POLYFLAGS]
	call	newclip
	cmp	word [esi+POLYSIDES],0
	je	@@cl0 ;entire polygon clipped away, nothing to draw
	;
@@cl4:	LOADES
	mov	edi,_polydrw
	test	word [esi+POLYFLAGS],F_GOURAUD
	jz	@@ngrd
	mov	word [edi],1 ;gouraud fill
	add	edi,2
	call	poly_grd
	jmp	@@pgdn
@@ngrd:	mov	word [edi],0 ;normal fill
	add	edi,2
	call	poly_nrm
@@pgdn:	
	;push	es
	push	_polydrw
	call	[drawfill_routine]
	add	esp,4
	
@@cl0:
  ;pop	ds
	pop	ebp
@@cull:
  pop	esi
	add	esi,2
	jmp	@@1
@@0:
  pop	esi
@@invi:	CEND

