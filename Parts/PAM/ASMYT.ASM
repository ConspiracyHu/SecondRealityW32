section .data

aseg	dd	0

;ntaulu	db	1000b,1100b,1110b,1111b
;taulu	db	1111b,0111b,0011b,0001b

ntaulu	db	0001b,0011b,0111b,1111b
taulu	db	1111b,1110b,1100b,1000b

ptaulu	db	1,2,4,8

section .code

global _shim_vram
extern _shim_vram

global _init_uframe
_init_uframe:

	;ARG	fseg:word
  push ebp
	mov	eax, [esp+8]
	mov	[aseg], eax
  pop ebp
	ret

global _ulosta_frame
_ulosta_frame:

	;ARG	scseg:word

	;push	ds di si
  push ebp

	;mov	edi, [esp+8]
	;mov	es, ax
  xor edi, edi
  xor esi, esi
	mov	ebp, [aseg]
  xor eax, eax
  xor ebx, ebx
  xor ecx, ecx
  xor edx, edx
	;mov	dx, 03c4h		; map mask... 03c4h, 02..

@@looppi:
	mov al, [ebp+esi]
  inc esi
	cmp	al, 0
	jg	@@outtaa
	je	@@over
@@skip:
	cbw
	sub	di, ax

	mov al, [ebp+esi]
  inc esi
	cmp	al, 0
	jl	@@skip
	je	@@over

@@outtaa:
	dec	al
	jz	@@single

	cbw
	mov	ebx, edi
	and	bx, 3
	add	bx, ax
	shr	bx, 2
	or	bx, bx
	jz	@@samebyte
	cmp	bx, 1
	je	@@twobytes

	mov	cx, ax
	mov	ebx, edi
	and	bx, 3
	mov	ah, [taulu+ebx]
	mov	al, 2
	;out	dx, ax
	mov	al, [ebp+esi]
	mov	bx, di
	shr	bx, 2
	mov	[_shim_vram+ebx], al

	push di
  push cx

	mov	ax, di
	add	cx, ax
	shr	cx, 2
	sub	cx, bx
	dec	cx
	shr	di, 2
	inc	di

	mov	ax, 0f02h
	;out	dx, ax
	mov	al, [ebp+esi]
	mov	ah, al
	shr	cx, 1
	jnc	@@l1
	mov [_shim_vram+edi], al
  inc edi
@@l1:   jcxz	@@l2
  add edi, _shim_vram
  add esi, ebp
	rep	stosw
  sub esi, ebp
  sub edi, _shim_vram 

@@l2:
  pop	cx
  pop di
	add	di, cx
	mov	ebx, edi
	and	bx, 3
	mov	ah, [ntaulu+ebx]
	mov	al, 2
	;out	dx, ax
	mov al, [ebp+esi]
  inc esi

	mov	bx, di
	shr	bx, 2
	mov	[_shim_vram+ebx], al

	inc	di

	mov al, [ebp+esi]
  inc esi

	cmp	al, 0
	jl	@@skip
	jg	@@outtaa
	je	@@over

@@twobytes:
	mov	ebx, edi
	and	bx, 3
	mov	cl, [taulu+ebx]
	add	di, ax
	mov	bx, di
	and	bx, 3
	mov	ch, [ntaulu+ebx]
	mov	ah, cl
	mov	al, 2
	;out	dx, ax
	mov	cl, [ebp+esi]
	mov	bx, di
	shr	bx, 2
	mov	[_shim_vram+ebx-1], cl
	mov	ah, ch
	;out	dx, ax
	mov	[_shim_vram+ebx], cl
	inc	edi
	inc	esi

	mov al, [ebp+esi]
  inc esi

	cmp	al, 0
	jl	@@skip
	jg	@@outtaa
	je	@@over


@@samebyte:
	mov	ebx, edi
	and    	bx, 3
	mov	cl, [taulu+ebx]
	add	di, ax
	mov	bx, di
	and	bx, 3
	and	cl, [ntaulu+ebx]
	mov	ah, cl
	mov	al, 02h
	;out	dx, ax
	mov al, [ebp+esi]
  inc esi

	mov	bx, di
	shr	bx, 2
	mov	[_shim_vram+ebx], al
	inc	di

	mov al, [ebp+esi]
  inc esi
	cmp	al, 0
	jl	@@skip
	jg	@@outtaa
	je	@@over


@@single:
	mov	bx, di
	and	bx, 3
	mov	ah, [ptaulu+ebx]
	mov	al, 2
	;out	dx, ax
	mov al, [ebp+esi]
  inc esi
	mov	bx, di
	shr	bx, 2
	mov	[_shim_vram+ebx], al
	inc	di

;-------------
	mov al, [ebp+esi]
  inc esi
	cmp	al, 0
	jl	@@skip
	jg	@@outtaa
	je	@@over

@@over:
	mov	edi, esi
	;shr	esi, 4
	mov	eax, ebp
	add	eax, esi
	and	edi, 15
	jz	@@exit
	inc	eax
@@exit:
	mov	[aseg], eax

	pop ebp

	ret


ruudulle:
	dec	al
	jz	@@single

	cbw
	mov	bx, di
	and	bx, 3
	add	bx, ax
	shr	bx, 2
	or	bx, bx
	jz	@@samebyte
	cmp	bx, 1
	je	@@twobytes

	mov	cx, ax
	mov	bx, di
	and	bx, 3
	mov	ah, [taulu+ebx]
	mov	al, 2
	;out	dx, ax
	mov	al, [ebp+esi]
	mov	bx, di
	shr	bx, 2
	mov	[_shim_vram+ebx], al

	push di
  push cx

	mov	ax, di
	add	cx, ax
	shr	cx, 2
	sub	cx, bx
	dec	cx
	shr	di, 2
	inc	di

	mov	ax, 0f02h
	;out	dx, ax
	mov	al, [esi]
	mov	ah, al
	shr	cx, 1
	jnc	@@l1
	mov [_shim_vram+edi], al
  inc edi
@@l1:   jcxz	@@l2
  add edi, _shim_vram
	rep	stosw
  sub edi, _shim_vram

@@l2:
  pop	cx
  pop	di

	add	di, cx
	mov	bx, di
	and	bx, 3
	mov	ah, [ntaulu+ebx]
	mov	al, 2
	;out	dx, ax
	mov al, [ebp+esi]
  inc esi
	mov	bx, di
	shr	bx, 2
	mov	[es:bx], al

	inc	di
	ret

@@twobytes:
	mov	ebx, edi
	and	bx, 3
	mov	cl, [taulu+ebx]
	add	di, ax
	mov	bx, di
	and	bx, 3
	mov	ch, [ntaulu+bx]
	mov	ah, cl
	mov	al, 2
	;out	dx, ax
	mov	cl, [esi]
	mov	bx, di
	shr	bx, 2
	mov	[_shim_vram+ebx-1], cl
	mov	ah, ch
	;out	dx, ax
	mov	[_shim_vram+ebx], cl
	inc	di
	inc	si
	ret

@@samebyte:
	mov	ebx, edi
	and    	bx, 3
	mov	cl, [taulu+ebx]
	add	di, ax
	mov	bx, di
	and	bx, 3
	and	cl, [ntaulu+ebx]
	mov	ah, cl
	mov	al, 02h
	;out	dx, ax
	mov al, [ebp+esi]
  inc esi
	mov	bx, di
	shr	bx, 2
	mov	[_shim_vram+ebx], al
	inc	di
	ret

@@single:
	mov	ebx, edi
	and	bx, 3
	mov	ah, [ptaulu+ebx]
	mov	al, 2
	;out	dx, ax
	mov al, [ebp+esi]
  inc esi
	mov	bx, di
	shr	bx, 2
	mov	[_shim_vram+ebx], al
	inc	di

	ret