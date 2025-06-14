section .data

global _jl_sin1024
%include "sin1024.inc"

section .code

global _jl_setborder
_jl_setborder:
	push	bp
	mov	bp,sp
	mov	dx,3dah
	in	al,dx
	mov	dx,3c0h
	mov	al,11h+32
	out	dx,al
	mov	al,[bp+6]
	out	dx,al
	pop	bp
	ret

global _inittwk
_inittwk:
	push	bp
	mov	bp,sp
	push	si
	push	di
	push	ds
	;clear palette
	mov	dx,3c8h
	xor	al,al
	out	dx,al
	inc	dx
	mov	cx,768
@@1:	out	dx,al
	loop	@@1
	;400 rows
	mov	dx,3d4h
	mov	ax,00009h
	out	dx,ax
	;tweak
	mov	dx,3d4h
	mov	ax,00014h
	out	dx,ax
	mov	ax,0e317h
	out	dx,ax
	mov	dx,3c4h
	mov	ax,0604h
	out	dx,ax
	;
	mov	dx,3c4h
	mov	ax,0f02h
	out	dx,ax
	mov	ax,0a000h
	mov	es,ax
	xor	di,di
	mov	cx,32768
	xor	ax,ax
	rep	stosw
	;
	pop	ds
	pop	di
	pop	si
	pop	bp
	ret

;global _lineblit
;_lineblit:
;	push	bp
;	mov	bp,sp
;	push	si
;	push	di
;	push	ds
;	mov	di,[bp+6]
;	mov	es,[bp+8]
;	mov	si,[bp+10]
;	mov	ds,[bp+12]
;
;  %assign zpl 0
;	%rep	4
;	mov	dx,3c4h
;	mov	ax,02h+(100h << zpl)
;	out	dx,ax
;	%assign zzz 0
;	%rep	80/2
;	mov	al,[esi+(zzz+0)*4+zpl]
;	mov	ah,[esi+(zzz+1)*4+zpl]
;	mov	[edi+zzz],ax
;	%assign zzz zzz+2
;	%endrep
;	%assign zpl zpl+1
;	%endrep
;
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
;	mov	si,[bp+6]
;	mov	ds,[bp+8]
;	mov	ax,[bp+10]
;	mov	dx,3c8h
;	out	dx,al
;	inc	dx
;	mov	cx,[bp+12]
;	shl	cx,1
;	add	cx,ax
;	rep	outsb
;	pop	ds
;	pop	di
;	pop	si
;	pop	bp
;	ret

%include "zoom.inc"

global _linezoom
_linezoom:
	push ebp
	mov edi,[esp+8]
	mov esi,[esp+12]
	mov	ebx,[esp+16]
	cmp	ebx,318
	jbe	@@1
	mov	ebx,318
@@1:	and	ebx,~1
  shl ebx,1
	;mov dx,3c4h
	;mov ax,0f02h
	;out dx,ax
	;inc dx
	xor eax,eax
  mov edx, [zoomt+ebx]
	call	edx
	pop	ebp
	ret