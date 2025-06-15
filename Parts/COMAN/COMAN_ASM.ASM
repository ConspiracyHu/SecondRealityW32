global theloop
extern theloop

segment .data
global _wave1,_wave2,_vbuf,_cameralevel
_wave1	dw	0,0
_wave2	dw	0,0
_vbuf	dw	0,0
_cameralevel dw 0

global _shim_vram
extern _shim_vram

global _coman_sin1024
%include "sin1024.inc"

global _combguse
_combguse times 90*160 db 0

segment .code

;global _setborder
;_setborder:
;	push	bp
;	mov	bp,sp
;	mov	dx,3dah
;	in	al,dx
;	mov	dx,3c0h
;	mov	al,11h+32
;	out	dx,al
;	mov	al,[bp+6]
;	out	dx,al
;	pop	bp
;	ret

;global _inittwk
;_inittwk:
;	push	bp
;	mov	bp,sp
;	push	si
;	push	di
;	push	ds
;	;clear palette
;	mov	dx,3c8h
;	xor	al,al
;	out	dx,al
;	inc	dx
;	mov	cx,768
;@@1:	out	dx,al
;	loop	@@1
;	mov	dx,3d4h
;	;400 rows
;	;mov	ax,00009h
;	;out	dx,ax
;	;tweak
;	mov	ax,00014h
;	out	dx,ax
;	mov	ax,0e317h
;	out	dx,ax
;	mov	dx,3c4h
;	mov	ax,0604h
;	out	dx,ax
;	;
;	mov	dx,3c4h
;	mov	ax,0f02h
;	out	dx,ax
;	mov	ax,0a000h
;	mov	es,ax
;	xor	di,di
;	mov	cx,32768
;	xor	ax,ax
;	rep	stosw
;	;
;	pop	ds
;	pop	di
;	pop	si
;	pop	bp
;	ret

;global _setpalarea
;_setpalarea:
;	push	bp
;	mov	bp,sp
;	push	si
;	push	di
;	push	ds
;	lds	si,[bp+6]
;	mov	ax,[bp+10]
;	mov	dx,3c8h
;	out	dx,al
;	mov	cx,[bp+12]
;	mov	ax,cx
;	shl	cx,1
;	add	cx,ax
;	inc	dx
;	rep	outsb
;	sti
;	pop	ds
;	pop	di
;	pop	si
;	pop	bp
;	ret

global _docol
_docol:
	push	ebp
;	mov	es,[_vbuf+2]
;	mov	fs,[_wave1+2]
;	mov	gs,[_wave2+2]
	mov	eax,~1
	mov	esi,[esp+8]
	and	esi,eax
	mov	edi,[esp+12]
	and	edi,eax
	mov	ecx,[esp+16]
	and	ecx,eax
	mov	edx,[esp+20]
	and	edx,eax
	mov	ebp,[esp+24]
	mov	ax,[_cameralevel]
	call	theloop
	pop	ebp
	ret

global _docopy
_docopy:
	push	ebp

%ifdef PXLSUX
	mov	ax,cs
	mov	ds,ax
	mov	si,OFFSET _combguse
	mov	di,0
	mov	cx,60
	;
@@7:	mov	dx,3c4h
	mov	ax,0302h
	;out	dx,ax
	%assign zzz0
	%rep	20
	mov	eax,ds:[si+zzz]
	mov	es:[di+zzz],eax
	%assign zzz zzz+4
	%endrep
	mov	dx,3c4h
	mov	ax,0C02h
	;out	dx,ax
	%assign zzz 0
	%rep	20
	mov	eax,ds:[si+zzz+80]
	mov	es:[di+zzz],eax
	%assign zzz zzz+4
	%endrep
	add	si,160
	add	di,80
	dec	cx
	jnz	@@7
%endif

	mov	dx,3c4h
	mov	ax,0f02h
	;out	dx,ax
	mov	edi,[esp+8]
	mov	esi,_shim_vram
	add esi,60*160
	add	edi,52*80
	mov	ecx,18*80/4
	xor	eax,eax
	rep	stosd
	mov	ecx,140
	mov	bl,255
	mov	bh,bl
	mov	ax,bx
	shl	ebx,16
	mov	bx,ax
	;
@@1:	mov	dx,3c4h
	mov	ax,0302h
	;out	dx,ax
	%assign zzz 0
	%rep	20
	mov	eax,[esi+zzz]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	mov	dx,3c4h
	mov	ax,0C02h
	;out	dx,ax
	%assign zzz 0
	%rep	20
	mov	eax,[esi+zzz+80]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	add	esi,160
	add	edi,80
	dec	cx
	jnz	@@1

;	mov	ax,cs
;	mov	ds,ax
;	mov	si,OFFSET _combguse+60*160
	xor	eax,eax
	mov	edi,_shim_vram
	add edi,68*160
	mov	ecx,30*160/4/4
@@cl1:	mov	[edi],eax
	add	di,4
	mov	[edi],eax
	add	di,4
	mov	[edi],eax
	add	di,4
	mov	[edi],eax
	add	di,4
	dec	cx
	jnz	@@cl1
	
	pop	ebp
	ret
