;/****************************************************************************
;** MODULE:	avidfill.asm
;** AUTHOR:	Sami Tammilehto / Fennosoftec OY
;** DOCUMENT:	?
;** VERSION:	1.0
;** REFERENCE:	-
;** REVISED BY:	-
;*****************************************************************************
;**
;** Assembler / Video (polygon filling)
;**
;****************************************************************************/

%include "a.inc"

extern vidstart

section .data

drawfill_progs:
dd drawfill_nrm
dd drawfill_grd

;ALIGN	4
leftside   db	1111b,1110b,1100b,1000b
rightside  db	0001b,0011b,0111b,1111b
middledot  db	0001b,0010b,0100b,1000b
;ALIGN 16
vdf_leftx	dd	0
vdf_lefta	dd	0
vdf_rightx	dd	0
vdf_righta	dd	0
vdf_count	dw	0
vdf_di		dd	0
vdf_color	db	0
;ALIGN 16
vdfg_color1	dw	0 
vdfg_color2	dw	0
vdfg_left	dw	0
vdfg_right	dw	0
vdfg_leftc	dw	0 ;c & ca must be in this order for 32 bit 
vdfg_leftca	dw	0 ;data transfer (seek for [32])
vdfg_rightc	dw	0
vdfg_rightca	dw	0
vdfg_lefts	dw	0
vdfg_left4	dw	0
vdfg_buf	times MAXCOLS db	 0

section .code

;北北北北 _vid_drawpolylist(...) 北北北北
;This call is obsolote. The correct call is to _draw_polylist.
extern _draw_polylist

_vid_drawpolylist:
	pop	cx ;retoffset
	pop	dx ;retsegment
	mov	ax,0f001h
	push	ax ;oflags
	push	dx ;retsegment
	push	cx ;retoffset
	jmp	_draw_polylist ;draw.asm


;北北北北 _vid_drawfill(char *drawdata) 北北北北
;entry:	[drawdata]=pointer to fill data stream
; exit: -
;descr: This routine fills a polygon on screen according to instructions in
;       the data stream. The 'nrm' stands for normal = flat shaded polygon.
;	Stream format: {FILL-DATA}

global _vid_drawfill
_vid_drawfill:
	CBEG
	call	vidstart
	lfspar	esi,0
	movzx	ebx, word [esi]
	cmp	ebx,1
	ja	@@1
	shl	ebx,2
	add	esi,2
	call	[drawfill_progs+ebx]
@@1:	CEND


extern _shim_vram

;北北北北 drawfill_nrm 北北北北
;entry:	DS:SI=pointer to {NORMAL-FILL-DATA} stream
; exit: -
drawfill_nrm:
	mov	ax,[esi]
	mov	[vdf_color],al
	movzx	ebx, word [esi+2] ;StartY
	add	esi,4
	shl	ebx,1
	movzx	eax,word [_rows+ebx]
  add eax, _shim_vram
	mov	[vdf_di],eax
	;es:vdf_di=dest
	jmp	@@dn1	
@@dn0:	ret

@@dn1:	movzx	eax, word [esi]
	add	esi,2
	or	ax,ax
	js	@@dn0
	jz	@@dn11
	mov	eax,[esi]
	mov	[vdf_leftx],eax
	mov	eax,[esi+4]
	mov	[vdf_lefta],eax
	add	esi,8
@@dn11:	mov	ax,[esi]
	add	esi,2
	or	ax,ax
	js	@@dn0
	jz	@@dn12
	mov	eax,[esi]
	mov	[vdf_rightx],eax
	mov	eax,[esi+4]
	mov	[vdf_righta],eax
	add	esi,8
@@dn12:	mov	ax,[esi]
	or	ax,ax
	jz	@@dn0 ;ERROR
	add	esi,2
	mov	[vdf_count],ax
	mov	edi,[vdf_di]
@@dn21:	;Fill loop
	;;
	mov	eax,[vdf_lefta]
	add	[vdf_leftx],eax
	mov	eax,[vdf_righta]
	add	[vdf_rightx],eax
	;
	movzx edx,word [vdf_leftx+2]
	movzx eax,word [vdf_rightx+2]
	;dx=leftx, ax=rightx
	;
	cmp	eax,edx
	je	@@dn20
	jl	@@dn22
	xchg	eax,edx
@@dn22:	;dec	edx ;don't fill the rightmost pixel

	mov	ecx,edx
	sub	ecx,eax
	add	edi,eax
  mov	al,[vdf_color]
  mov ah, al
  call	faststosb

%if 0
	mov	ebx,eax
	sar	ebx,2
	mov	ecx,edx
	sar	ecx,2
	sub	ecx,ebx
	add	edi,ebx

	mov	ebp,3
	and	ebp,eax
	mov	bh,[leftside+ebp]
	mov	ebp,3
	and	ebp,edx
	mov	bl,[rightside+ebp]
	mov	dx,3c5h
	
	;(di..si,bx)
	cmp	ecx,0
	je	@@dn29 ;end and beg in same byte
	;left side
	mov	al,bh
	;out	dx,al
	mov	al,[vdf_color]
	mov	[edi],al
	inc	edi
	dec	ecx
	mov	ah,al
	;middle
	jcxz	@@dn24
	mov	al,0fh
	;out	dx,al
	mov	al,ah
	mov	bp,bx
	call	faststosb
	mov	bx,bp
@@dn24:	;right side
	mov	al,bl
	;out	dx,al
	mov	al,ah
	mov	[edi],al
	jmp	@@dn20
@@dn29:	;end and beg in same byte
	mov	al,bl
	and	al,bh
	;out	dx,al
	mov	al,[vdf_color]
	mov	[edi],al
	;;
%endif

@@dn20:	mov	edi,[vdf_di]
  movzx eax,word [_rowlen]
	add	edi,eax
	mov	[vdf_di],edi
	dec	word [vdf_count]
	jnz	@@dn21
	jmp	@@dn1


;北北北北 drawfill_grd 北北北北
;entry:	DS:SI=pointer to {GOURAUD-FILL-DATA} stream
; exit: -
drawfill_grd:
	movzx	ebx,word [esi+2] ;StartY
	add	esi,4
	shl	ebx,1
	movzx	eax,word [_rows+ebx]
  add eax, _shim_vram
	mov	[vdf_di],eax
	;es:vdf_di=dest
	jmp	dg1	
dg0:	ret

dg1:	movzx	eax,word [esi]
	add	esi,2
	or	ax,ax
	js	dg0
	jz	@@dg11
	mov	eax,[esi] ;c&ca
	mov	dword [vdfg_leftc],eax ;[32]
	mov	eax,[esi+4]
	mov	[vdf_leftx],eax
	mov	eax,[esi+8]
	mov	[vdf_lefta],eax
	add	esi,12
@@dg11:	mov	ax,[esi]
	add	esi,2
	or	ax,ax
	js	dg0
	jz	@@dg12
	mov	eax,[esi] ;c&ca
	mov	dword [vdfg_rightc],eax ;[32]
	mov	eax,[esi+4]
	mov	[vdf_rightx],eax
	mov	eax,[esi+8]
	mov	[vdf_righta],eax
	add	esi,12
@@dg12:	mov	ax,[esi]
	or	ax,ax
	jz	dg0 ;ERROR
	add	esi,2
	mov	[vdf_count],ax
	mov	edi,[vdf_di]
dg21:	;Fill loop
	;;
	mov	ax,[vdfg_leftca]
	add	[vdfg_leftc],ax
	mov	ax,[vdfg_rightca]
	add	[vdfg_rightc],ax
	mov	eax,[vdf_lefta]
	add	[vdf_leftx],eax
	mov	eax,[vdf_righta]
	add	[vdf_rightx],eax
	;
	movzx	edx,word [vdf_leftx+2]
	movzx	eax,word [vdf_rightx+2]
	movzx	ebx,word [vdfg_leftc]
	movzx	ecx,word [vdfg_rightc]
	;dx=leftx, ax=rightx
	;
	cmp	eax,edx
	je	dg20
	jl	@@dg22
	xchg	ebx,ecx
	xchg	eax,edx
@@dg22:	;dec	edx ;don't fill the rightmost pixel
	mov	[vdfg_color1],cx
	mov	[vdfg_color2],bx
	mov	[vdfg_left],ax
	mov	[vdfg_right],dx
%if 0
	;oint colors
	mov	dx,3c5h
	;end
	mov	bl,byte [vdfg_right]
	test	bl,1
	jnz	@@dgef2
	and	bx,3
	mov	al,[middledot+bx]
	;out	dx,al
	mov	bx,[vdfg_right]
	shr	bx,2
	add	bx,di
	mov	al,byte [vdfg_color2+1]
	mov	[ebx],al
@@dgef2:	;start
	mov	bl,byte [vdfg_left]
	test	bl,1
	jz	@@dgef1
	and	bx,3
	mov	al,[middledot+ebx]
	;out	dx,al
	movzx	ebx,word [vdfg_left]
	shr	ebx,2
	add	ebx,edi
	mov	al,byte [vdfg_color1+1]
	mov	[ebx],al
@@dgef1:	;calc length & beg
%endif
	movzx	eax,word [vdfg_left]
	movzx	edx,word [vdfg_right]
	;inc	eax
	;shr	eax,1
	mov	[vdfg_lefts],ax
	;dec	edx
	;shr	edx,1
	;
	;mov	ecx,eax
	;shr	ecx,1
	add	edi,eax
	;
	mov	ecx,edx
	sub	ecx,eax
	;inc	ecx ;cx=number of 2 byte blocks to fill
	cmp	ecx,0
	jg	@@dg2f2
	;ends only
	jmp	dg20
@@dg2f2:
	push	esi
	movzx	eax, word [vdfg_color1]
	sub	eax,[vdfg_color2]
	jge	@@dg2f3
	neg	eax
	mov	ebx,ecx
	add	ebx,ebx
	mul	word [_afilldiv+ebx]
	neg	edx
	jmp	@@dg2f4
@@dg2f3:	mov	ebx,ecx
	add	ebx,ebx
	mul	word [_afilldiv+ebx]
@@dg2f4:	mov	esi,ecx

@@dgd0:	;dx=coloradder, cx=len (in 2 byte blocks)
	cmp	edx,128
	jge	gouraud12
	cmp	edx,-128
	jle	gouraud12
	jmp	gouraud4
gouraud12:
	cmp	edx,400
	jge	gouraud1
	cmp	edx,-400
	jle	gouraud1
	jmp	gouraud2

;----------------------------------------------------------------

gouraud1: ;1 pixel accuray
	sar	edx,1
	;add	ecx,ecx
	;
	mov	eax,ecx
	shl	ecx,3
	add	eax,ecx
  neg eax
	;ax=-cx*9
	add	eax,@@dgvdfg_fcode
	mov	ebx,[vdfg_color2]
	jmp	eax
	
%assign zzz MAXCOLS
%rep	MAXCOLS+1
	add	bx,dx			;3 bytes
	mov	[vdfg_buf+ (zzz & 3)*(MAXCOLS/4) + (zzz >> 2) ],bh	;6 bytes
	%assign zzz zzz-1
%endrep
	;mov ax,bx			;2 bytes, 1 clock (filler)
@@dgvdfg_fcode:
	;push	ds
	;mov	ax,cs
	;mov	ds,ax
	mov	ecx,esi
	;add	ecx,ecx
  mov	esi,vdfg_buf
  call	fastmovsb
	;
%if 0
@@dgf1:	mov	al,00010001b
	test	word [vdfg_lefts],1
	jz	@@dgf2
	mov	al,01000100b
@@dgf2:	;
	%assign zzz 0
	add	ecx,3
	%rep 4
	;local	l1
	push	ecx
	shr	cx,2
%define ZZZ(x) gour1_ %+ zzz
	jz	ZZZ(x)
	push	eax
	push	edi
	mov	dx,3c5h
	;out	dx,al
	mov	esi,vdfg_buf+zzz*(MAXCOLS/4)
	call	fastmovsb
	pop	edi
	pop	eax
ZZZ(x) :	pop	ecx
	dec	ecx
	rol	al,1
	adc	di,0
	%assign zzz zzz+1
	%endrep
	;
@@dgf0:	;pop	ds
%endif

	pop	esi
	jmp	zzz20


;----------------------------------------------------------------

gouraud2: ;2 pixel accuray
	mov	eax,ecx
	shl	ecx,3
	add	eax,ecx
  neg eax
	;ax=-cx*9
	add	eax,@@dgvdfg_fcode
	mov	ebx,[vdfg_color2]
	jmp	eax
	
%assign zzz MAXCOLS
%rep	MAXCOLS+1
	add	bx,dx			;3 bytes
	mov	[vdfg_buf+ (zzz & 1)*(MAXCOLS/2) + (zzz >> 1) ],bh	;6 bytes
	%assign zzz zzz-1
%endrep
	;mov ax,bx			;2 bytes, 1 clock (filler)
@@dgvdfg_fcode:
	;push	ds
	;mov	ax,cs
	;mov	ds,ax
	mov	ecx,esi
	jcxz	@@dgf0
	mov	esi,vdfg_buf
	call	fastmovsb
	;
%if 0
@@dgf1:	mov	al,00110011b
	test	word [vdfg_lefts],1
	jz	@@dgf2
	mov	al,11001100b
@@dgf2:	;
	mov	esi,vdfg_buf
	push	ecx
	push	edi
	push	eax
	inc	cx
	shr	cx,1
	mov	dx,3c5h
	;out	dx,al
	call	fastmovsb
	pop	eax
	pop	edi
	pop	ecx
	rol	al,2
	jnc	@@dgf3
	inc	di
@@dgf3:	mov	esi,vdfg_buf+MAXCOLS/2
	shr	ecx,1
	jz	@@dgf0
	mov	dx,3c5h
	;out	dx,al
	call	fastmovsb
	;
%endif

@@dgf0:	;pop	ds
	pop	esi
	jmp	zzz20


;----------------------------------------------------------------

gouraud4: ;4 pixel accuray
	cmp	ecx,4
	jl	gouraud2
	sal	edx,1
	;
	mov	[vdfg_left4],cx
	;shr	ecx,1 ;rescale
	;inc	ecx ;one extra
	mov	eax,ecx
	shl	ecx,3
	add	eax,ecx
  neg eax
	;ax=-cx*9
	add	eax,@@dgvdfg_fcode
	mov	ebx,[vdfg_color2]
	sub	ebx,edx ;one extra
	jmp	eax
	
%assign zzz MAXCOLS
%rep	MAXCOLS+1
	add	bx,dx			;3 bytes
	mov	[vdfg_buf+zzz],bh	;6 bytes
	%assign zzz zzz-1
%endrep
	;mov eax,ebx			;2 bytes, 1 clock (filler)
@@dgvdfg_fcode: 
	;push	ds
	;mov	dx,cs
	;mov	ds,dx
	mov	ecx,esi
	mov	esi,vdfg_buf
	call	fastmovsb
	pop	esi
	jmp	zzz20

  %if 0
	;
@@dgf1:	mov	esi,vdfg_buf
	test	word [vdfg_lefts],1
	jnz	@@dgf3
	inc	ecx
@@dgf4:	shr	ecx,1
	jnc	@@dgf5
	mov	dx,3c5h
	mov	al,0fh
	;out	dx,al
	call	fastmovsb
@@dgf0:	;pop	ds
	pop	esi
	jmp	zzz20

@@dgf5:	dec	ecx
	mov	dx,3c5h
	mov	al,0fh
	;out	dx,al
	call	fastmovsb
	mov	dx,3c5h
	mov	al,03h
	;out	dx,al
	movsb
	;pop	ds
	pop	esi
	jmp	zzz20

@@dgf3:	mov	dx,3c5h
	mov	al,0ch
	;out	dx,al
	movsb
  %endif

;	jmp	@@dgf4


;----------------------------------------------------------------
	
zzz20:	;;
dg20:	mov	edi,[vdf_di]
	movzx eax,word [_rowlen]
  add	edi, eax
	mov	[vdf_di],edi
	dec	word [vdf_count]
	jnz	dg21
	jmp	dg1


;北北北北 fastmovsb 北北北北
;entry:	DS:SI=pointer to source data
;	ES:DI=pointer to destination (screen)
;	CX=number of bytes to copy (MUST BE <512*4)
;exit:	copies data like REP MOVSB but uses 32 bit moves and aligns
;	destination to dword boundary.
ALIGN 16;
fastmovsb_bt:
	dd	fastmovsb_b0
	dd	fastmovsb_b1
	dd	fastmovsb_b2
	dd	fastmovsb_b3
fastmovsb_b1:
	mov	al,[esi]
	sub	ecx,3
	mov	[edi],al
	mov	ax,[esi+1]
	add	esi,3
	mov	[edi+1],ax
	add	edi,3
	jmp	fastmovsb_b0
fastmovsb_b2:
	mov	ax,[esi]
	sub	ecx,2
	add	esi,2
	mov	[edi],ax
	add	di,2
	jmp	fastmovsb_b0
fastmovsb_b3:
	mov	al,[esi]
	dec	ecx
	inc	esi
	mov	[edi],al
	inc	edi
	jmp	fastmovsb_b0
ALIGN 16
fastmovsb_et:
	dd fastmovsb_e0
	dd fastmovsb_e1
	dd fastmovsb_e2
	dd fastmovsb_e3
fastmovsb_e1:
	mov	al,[esi]
	inc	esi
	mov	[edi],al
	inc	edi
	ret
fastmovsb_e3:
	mov	ax,[esi]
	mov	[edi],ax
	mov	al,[esi+2]
	add	esi,3
	mov	[edi+2],al
	add	edi,3
	ret
fastmovsb_e2:
	mov	ax,[esi]
	add	esi,2
	mov	[edi],ax
	add	edi,2
fastmovsb_e0:
	ret
;ALIGN 16
fastmovsb:
	;copies CX bytes of data from DS:SI to ES:DI aligning destination
	;si/di will point to the correct position after this (cx won't)
	cmp	ecx,4
	jb	fmb4
	mov	ebx,edi
	and	ebx,3
	shl	ebx,2
	jmp	[fastmovsb_bt+ebx]
fastmovsb_b0:
	mov	ebx,ecx
  shr ebx,2
  neg ebx
	;add	ebx,ebx
	;add	ebx,ebx
	;and	ebx,~ 15
	;neg	ebx
	;bx=-cx*8
	add	ebx,fmbjmp
	jmp	ebx
	%rep	512
	;db	66h,8bh,84h,00h,00h	;mov	eax,ds:[si+0000h]
	;db	83h,0c6h,04h		;add	si,4
	;db	66h,26h,89h,05h		;mov	es:[di],eax
	;db	81h,0c7h,04h,00h	;add	di,0004h
  ;mov	eax,[esi+0000h]
  ;add	esi,4
  ;mov	[edi],eax
  ;add	edi,0004h
  movsd
	%endrep	;total 16 bytes
fmbjmp:	movzx	ebx,cx
	and	ebx,3
	shl	ebx,2
	jmp	[fastmovsb_et+ebx]
fmb4:	movzx	ebx,cx
	shl	ebx,2
	jmp	[fastmovsb_et+ebx]


;北北北北 faststosb 北北北北
;entry:	ES:DI=pointer to destination (screen)
;	AX=word fill (lo/hi byte MUST be same)
;	CX=number of bytes to fill (MUST BE <512*4)
;exit:	fills data like REP STOSB but uses 32 bit moves and aligns
;	destination to dword boundary.
;	NOTE: BX modified
;ALIGN 16
faststosb_bt:
	dd	faststosb_b0
	dd	faststosb_b1
	dd	faststosb_b2
	dd	faststosb_b3
faststosb_b1:
	mov	[edi],al
	sub	ecx,3
	mov	[edi+1],ax
	add	edi,3
	jmp	faststosb_b0
faststosb_b2:
	sub	cx,2
	mov	[edi],ax
	add	edi,2
	jmp	faststosb_b0
faststosb_b3:
	dec	cx
	mov	[edi],al
	inc	edi
	jmp	faststosb_b0
;ALIGN 16
faststosb_et:
	dd faststosb_e0
	dd faststosb_e1
	dd faststosb_e2
	dd faststosb_e3
faststosb_e1:
	mov	[edi],al
	inc	edi
	ret
faststosb_e3:
	mov	[edi],ax
	mov	[edi+2],al
	add	edi,3
	ret
faststosb_e2:
	mov	[edi],ax
	add	edi,2
faststosb_e0:
	ret
;ALIGN 16
faststosb:
	;fills CX bytes of data with AX to ES:DI aligning destination
	;di will point to the correct position after this (cx won't)
	cmp	ecx,4
	jb	fsb4
	mov	ebx,edi
	and	ebx,3
	shl	ebx,2
	jmp	[faststosb_bt+ebx]
faststosb_b0:
	mov	ebx,eax
	shl	eax,16
	mov	ax,bx
	;eax=filler
	mov	ebx,ecx
  shr ebx,2
	;add	ebx,ebx
	;and	ebx,~ 7
	neg	ebx
	;bx=-cx*8
	add	ebx,fsbjmp
	jmp	ebx
	%rep 512
	;db	66h,26h,89h,05h		;mov	es:[di],eax
	;db	81h,0c7h,04h,00h	;add	di,0004h
  ;mov	[edi],eax
  ;add	edi,0004h
  stosd
	%endrep	;total 8 bytes
fsbjmp:	movzx	ebx,cx
	and	ebx,3
	shl	ebx,2
	jmp	[faststosb_et+ebx]
fsb4:	movzx	ebx,cx
	shl	ebx,2
	jmp	[faststosb_et+ebx]


