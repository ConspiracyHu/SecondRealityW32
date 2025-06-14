section .code
	
;global_inittwk
;_inittwk PROC FAR
;	push	bp
;	mov	bp,sp
;	push	si
;	push	di
;	push	ds
;	;clear palette
;;	mov	dx,3c8h
;;	xor	al,al
;;	out	dx,al
;;	inc	dx
;;	mov	cx,768
;;@@1:	out	dx,al
;;	loop	@@1
;	;400 rows
;	mov	dx,3d4h
;	mov	ax,00009h
;	out	dx,ax
;	;tweak
;	mov	dx,3d4h
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

global _lineblit
_lineblit:
	push	ebp
	mov	edi,[esp+8]
	mov	esi,[esp+12]
	%assign zpl 0
	%rep	4
	;mov	dx,3c4h
	;mov	ax,02h+(100h << zpl)
	;out	dx,ax
	%assign zzz 0
	%rep	80/2
	mov	al,[esi+(zzz+0)*4+zpl]
	mov	ah,[esi+(zzz+1)*4+zpl]
	mov	[edi+zzz],ax
	%assign zzz zzz+2
	%endrep
	%assign zpl zpl+1
	%endrep
	pop	ebp
	ret

;REPOUTSB MACRO
;	local l1
;l1:	mov	al,ds:[si]
;	inc	si
;	out	dx,al
;	dec	cx
;	jnz	l1
;	ENDM

;global_setpalarea
;_setpalarea PROC FAR
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
;	REPOUTSB
;	pop	ds
;	pop	di
;	pop	si
;	pop	bp
;	ret
;_setpalarea ENDP
