section .data

global _back
_back	dw	0,0
global _rotpic
_rotpic	dw	0,0
global _rotpic90
_rotpic90 dw	0,0

section .code

global _shim_vram
extern _shim_vram

%macro DOWORD 2
	movsx	ebx, word [esi+(%2)]
	mov	al,[edi+ebx]
	movsx	ebx, word [esi+(%2)+2]
	mov	ah,[edi+ebx]
	or	ax,dx
	mov	[ebp+(%1)],ax
%endmacro ;=21

global _dorow
_dorow:
	push ebp

  ; ds:si => esi (lens)
  ; es:bp => ebp (vram)
  ; fs:di => edi (back)

	;mov	fs,cs:_back[2]
	;mov	ax,0a000h
	;mov	es,ax
	mov	esi,[esp+8] ; ptr/lens
	mov	edx,[esp+20] ; M
	mov	dh,dl
	mov	edi,[esp+12] ; U 
	mov	esi,[esp+16] ; Y
	shl	si,2
  add esi, [esp+8] ; +ds:
	mov	cx,[esi+2]
	movzx	esi, word [esi]
	cmp	cx,4
	jge	@@2
	jmp	@@0
@@2:
  add esi, [esp+8] ; +ds:
  mov ax,[esi]
  movsx eax, ax
  add edi, eax
	mov	ebp, edi
  add edi, [_back]
	add	esi,2
	test	ebp,1
	jz	@@1
	movsx	ebx, word [esi]
	add	esi,2
  add edi, ebx
	mov	al,[edi] ;fs
	or	ax,dx
	mov	[_shim_vram+ebp],al
	inc	ebp
	dec	ecx
@@1:	push	ecx
	shr	ecx,1
	sub	esi,320
	sub	ebp,320

  add ebp, _shim_vram

	;mov	eax,ecx ;*1
	;shl	ecx,2
	;add	eax,ecx ;*4
	;shl	ecx,2
	;add	eax,ecx ;*16

  mov eax, ecx
  mov ecx, 30 ; speedcode jump - was 21 in the original (above)
  push edx
  mul ecx
  pop edx

	neg	eax
	;bx=-count*21
	add	eax,@@l
	jmp	eax
	%assign zzz 64
	%rep	64
	%assign zzz zzz-1
	DOWORD	320+zzz*2,320+zzz*4
	%endrep
@@l:	pop	ecx
	test	cx,1
	jz	@@0
	and	cx,~1
	add	bp,cx
	add	cx,cx
	add	si,cx
	mov	bx,[esi+320]
	mov	al,[edi]
	or	ax,dx
	mov	[ebp+320],al
@@0:	
	pop ebp
	ret

global _dorow2
_dorow2:
	push ebp

  ; ds = back
  ; es = vram
  ; fs = ptr (lens)

	mov	esi,[esp+16] ; Y
	shl	esi,2
	add	esi,[esp+8] ; ptr
	mov	cx,[esi+2] ; fs
	movzx	esi, word [esi]   ; fs
	or	cx,cx
	jcxz	@@0

	mov	edx, [esp+20]    ; M
	mov	dh, dl

	mov	edi, [esp+12]    ; U
  push esi
  add esi, [esp+8+4] ; ptr
  add di, [esi]
  pop esi

	mov	eax, edi
	lea	ebp, [esi+2]
	mov	esi, eax

  add esi, _shim_vram
  add edi, [_back]
  add ebp, [esp+8] ; ptr

  ; ds:di => edi (back)
  ; es:si => esi (vram)
  ; fs:bp => ebp (lens)

@@3:
  movsx	ebx, word [ebp+2]
	mov	al, [ebx+edi]
	or	al, dl
	movsx	ebx, word [ebp]
	add	ebp, 4
	mov	[ebx+esi], al
	dec	cx
	jnz	@@3
	
@@0:
	pop ebp
	ret

global _dorow3
_dorow3:
	push ebp
	
	mov	esi,[esp+16] ; Y
	shl	esi,2
	add	esi,[esp+8] ; ptr
	mov	cx,[esi+2] ; fs
	movzx	esi, word [esi]   ; fs
  add	esi,[esp+8] ; ptr
	or	cx,cx
	jcxz	@@0
	mov	edi, [esp+12] ; U
	add	di, [esi] ; fs
	add	esi, 2

  push ebp
  mov ebp,[_back]
@@3:
  movsx	ebx, word [esi] ; fs
  add ebx, edi
	add	esi, 2
	mov	al,[ebp+ebx] ; ds
	mov	[_shim_vram+ebx],al ; es
	dec	cx
	jnz	@@3
  pop ebp
	
@@0:
	pop ebp
	ret

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
;
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
;	;400 rows
;	mov	dx,3d4h
;	mov	ax,00009h
;	out	dx,ax
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
;	;set 4 x vertical
;	mov	dx,3d4h
;	mov	al,9
;	out	dx,al
;	inc	dx
;	in	al,dx
;	and	al,~31
;	or	al,3
;	out	dx,al
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

section .data
_xpos	dd	0
_ypos	dd	0
_xadd	dd	0
_yadd	dd	0

%define ZOOMXW	160
%define ZOOMYW	100

section .code

global _rotate
_rotate:
	push	ebp
	
	mov	eax,[esp+8] ; x
	shl	eax,16
	mov	[_xpos],eax
	mov	eax,[esp+12]  ; y
	shl	eax,16
	mov	[_ypos],eax
	
	mov	eax,[esp+16] ; xa
	cwde
	shl	eax,6
	mov	ebx,eax
	mov	eax,[esp+20] ; ya
	cwde
	shl	eax,6
	
	mov	ecx,eax
	mov	edx,ebx
	
	mov	ebp,[_rotpic]
	cmp	ecx,0
	jge	@@s1
	neg	ecx
@@s1:	cmp	edx,0
	jge	@@s2
	neg	edx
@@s2:	cmp	ecx,edx
	jle	@@s3
	
	mov	ebp,[_rotpic90]
	xchg	eax,ebx
	neg	eax
	mov	ecx,[_xpos]
	mov	edx,[_ypos]
	xchg	ecx,edx
	neg	ecx
	mov	[_xpos],ecx
	mov	[_ypos],edx
	
@@s3:
  mov	[_xadd],eax
	mov	[_yadd],ebx
	
	xor	ax,ax
	mov	cx,[_yadd+0]
	mov	dx,[_xadd+0]
	mov	bl,[_yadd+2]
	mov	bh,[_xadd+2]
	neg	bh
	neg	dx
	sbb	bh,0
	xor	si,si
	xor	di,di
	;si=lowx,di=lowy,ax=y/x
	;cx=addx,dx=addy,bx=yah/xah
	%assign zzz 0
	%rep	ZOOMXW/4
	add	si,cx
	adc	al,bl
	add	di,dx
	adc	ah,bh
  cwde
	mov	dword [@@moda+zzz+3],eax
	add	si,cx
	adc	al,bl
	add	di,dx
	adc	ah,bh
  cwde
	mov	dword [@@modb+zzz+3],eax
	add	si,cx
	adc	al,bl
	add	di,dx
	adc	ah,bh
  cwde
	mov	dword [@@moda+zzz+10],eax
	add	si,cx
	adc	al,bl
	add	di,dx
	adc	ah,bh
  cwde
	mov	dword [@@modb+zzz+10],eax
	%assign zzz zzz+3*7
	%endrep
	
	;aspect ratio
	mov	eax,307
	mul	dword [_xadd]
	sar	eax,8
	mov	[_xadd],eax
	mov	eax,307
	mul	dword [_yadd]
	sar	eax,8
	mov	[_yadd],eax
	
	mov edi,_shim_vram
	add edi,-1000h
	
	mov	cx,ZOOMYW
@@2:	mov	ebx,[_ypos]
	add	ebx,[_yadd]
	mov	[_ypos],ebx
	shr	ebx,8
	mov	eax,[_xpos]
	add	eax,[_xadd]
	mov	[_xpos],eax
	shr	eax,16
	mov	bl,al
	movzx	esi,bx
	;
	;mov	dx,3c4h
	;mov	ax,0302h
	;out	dx,ax
@@moda:
  %assign zzz 1000h
	%rep	ZOOMXW/4
	mov	al,[ebp+esi+1234h]	;4
	mov	ah,[ebp+esi+1234h]	;4
	mov	[edi+zzz],ax		;5
	%assign zzz zzz+2
	%endrep
	;mov	dx,3c4h
	;mov	ax,0c02h
	;out	dx,ax
@@modb:
  %assign zzz 1000h
	%rep	ZOOMXW/4
	mov	al,[ebp+esi+1234h]	;4
	mov	ah,[ebp+esi+1234h]	;4
	mov	[edi+zzz],ax		;5
	%assign zzz zzz+2
	%endrep
	;
	add	di,80
	dec	cx
	jz	@@1
	jmp	@@2
@@1:	
	pop	ebp
	ret
	
global _rotatez
_rotatez:
	push	bp
	mov	bp,sp
	push	si
	push	di
	push	ds
	
	mov	ax,[bp+6]
	shl	eax,16
	mov	[_xpos],eax
	mov	ax,[bp+8]
	shl	eax,16
	mov	[_ypos],eax
	
	mov	ax,[bp+12]
	cwde
	shl	eax,6
	mov	ebx,eax
	mov	ax,[bp+10]
	cwde
	shl	eax,6
	
	mov	ecx,eax
	mov	edx,ebx
	
	mov	ds,[_rotpic+2]
	cmp	ecx,0
	jge	@@s1
	neg	ecx
@@s1:	cmp	edx,0
	jge	@@s2
	neg	edx
@@s2:	cmp	ecx,edx
	jle	@@s3
	
	mov	ds,[_rotpic90+2]
	xchg	eax,ebx
	neg	eax
	mov	ecx,[_xpos]
	mov	edx,[_ypos]
	xchg	ecx,edx
	neg	ecx
	mov	[_xpos],ecx
	mov	[_ypos],edx
	
@@s3:	mov	[_xadd],eax
	mov	[_yadd],ebx
	
	xor	ax,ax
	mov	cx,word [_yadd+0]
	mov	dx,word [_xadd+0]
	mov	bl,byte [_yadd+2]
	mov	bh,byte [_xadd+2]
	neg	bh
	neg	dx
	sbb	bh,0
	xor	si,si
	xor	di,di
	;si=lowx,di=lowy,ax=y/x
	;cx=addx,dx=addy,bx=yah/xah
	%assign zzz 0
	%rep	ZOOMXW/4
	add	si,cx
	adc	al,bl
	add	di,dx
	adc	ah,bh
	mov	word [@@moda+zzz+2],ax
	add	si,cx
	adc	al,bl
	add	di,dx
	adc	ah,bh
	mov	word [@@modb+zzz+2],ax
	add	si,cx
	adc	al,bl
	add	di,dx
	adc	ah,bh
	mov	word [@@moda+zzz+6],ax
	add	si,cx
	adc	al,bl
	add	di,dx
	adc	ah,bh
	mov	word [@@modb+zzz+6],ax
	%assign zzz zzz+13
	%endrep
	
	;aspect ratio
	mov	eax,307
	mul	dword [_xadd]
	sar	eax,8
	mov	[_xadd],eax
	mov	eax,307
	mul	dword [_yadd]
	sar	eax,8
	mov	[_yadd],eax
	
	mov edi, _shim_vram
	add edi,-1000h
	
	mov	cx,ZOOMYW
@@2:	mov	ebx,[_ypos]
	add	ebx,[_yadd]
	mov	[_ypos],ebx
	shr	ebx,8
	mov	eax,[_xpos]
	add	eax,[_xadd]
	mov	[_xpos],eax
	add	dword [_xadd],256
	sub	dword [_yadd],256
	shr	eax,16
	mov	bl,al
	mov	si,bx
	;
	mov	dx,3c4h
	mov	ax,0302h
	out	dx,ax
@@moda:
  %assign zzz 1000h
	%rep	ZOOMXW/4
	mov	al,[esi+1234h]	;4
	mov	ah,[esi+1234h]	;4
	mov	[edi+zzz],ax		;5
	%assign zzz zzz+2
	%endrep
	mov	dx,3c4h
	mov	ax,0c02h
	out	dx,ax
@@modb:
  %assign zzz 1000h
	%rep	ZOOMXW/4
	mov	al,[esi+1234h]	;4
	mov	ah,[esi+1234h]	;4
	mov	[edi+zzz],ax		;5
	%assign zzz zzz+2
	%endrep
	;
	add	di,80
	dec	cx
	jz	@@1
	jmp	@@2
@@1:	
	pop	ds
	pop	di
	pop	si
	pop	bp
	ret
