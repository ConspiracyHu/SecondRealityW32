section .data
mmask	dw	0102h,0202h,0402h,0802h,0102h,0202h,0402h,0802h
rmask	dw	0004h,0104h,0204h,0304h,0004h,0104h,0204h,0304h
mrol	dw	0

section .code

global _ascrolltext
_ascrolltext:

;	ARG	scrl:word, text:dword

	push ebp
	;push	0a000h
	;pop	es
	lds	si, [esp+12]
	mov	cx, 0
@@l1:

	mov	bx, cx
	add	ebx, [esp+8]
	and	bx, 3
	shl	bx, 1
	mov	ax, [mmask+bx]
	mov	dx, 3c4h
	;out	dx, ax
	mov	ax, [rmask+bx]
	mov	dx, 3ceh
	;out	dx, ax

	mov	di, cx
	add	edi, [esp+8]
	shr	di, 2
@@l3:
	%rep	20
	add	si, 4
	mov	bx, [esi-4]
	cmp	bx, -1
	je	@@l2
	mov	ax, [esi-2]
	xor	[bx+di], al
	%endrep
	jmp	@@l3
@@l2:
	inc	cx
	cmp	cx, 4
	jne	@@l1

	pop ebp
	ret

global _outline
_outline:

;	ARG	src:dword, dest:dword

	push ebp

	mov	word [mrol], 0802h
	mov	ecx, 4
@@l1:
	mov	dx, 3c4h
	mov	ax, [mrol]
	;out	dx, ax

	mov esi, [esp+8]
	add	esi, ecx
	dec	esi
	mov edi, [esp+12]
	xor	eax, eax
	mov	[edi-352], al
	mov	[edi-352+176], al

	%assign ccc 0
	%rep	75
	mov	al, [esi+ccc*640]
	mov	[edi+ccc*352], al
	mov	[edi+ccc*352+176], al
	%assign ccc ccc+1
	%endrep

	;mov	ax, ds
	add	ax, 75*40
	;mov	ds, ax

	%assign ccc 0
	%rep	75
	mov	al, [esi+ccc*640]
	mov	[edi+ccc*352+75*352], al
	mov	[edi+ccc*352+75*352+176], al
	%assign ccc ccc+1
	%endrep

	shr	word [mrol+1], 1
	dec	ecx
	jnz	@@l1


	pop ebp
	ret
