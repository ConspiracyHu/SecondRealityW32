section .data
mmask	dw	0102h,0202h,0402h,0802h,0102h,0202h,0402h,0802h
rmask	dw	0004h,0104h,0204h,0304h,0004h,0104h,0204h,0304h
mrol	dd	0

section .code

extern _alku_planar_vram

global _ascrolltext
_ascrolltext:

;	ARG	scrl:word, text:dword

%define scrl ebp+8
%define text ebp+12

	push ebp
	mov ebp, esp
	push esi
	push ebx
	;push	0a000h
	;pop	es
	mov esi, [text]
	mov	ecx, 0
.@@l1:

	;mov	ebx, ecx
	;and	ebx, 3
	;shl	ebx, 1
	;mov	ax, [mmask+ebx]
	;mov	dx, 3c4h
	;out	dx, ax
	;mov	ax, [rmask+ebx]
	;mov	dx, 3ceh
	;out	dx, ax

	;mov	edi, ecx
	;add	edi, [scrl]
	;shr	edi, 2
.@@l3:
	%rep	20
	add	si, 4
	movzx	ebx, word [esi-4]
	cmp	bx, -1
	je	.@@l2
  add ebx, 100*352
	add	ebx, [scrl]
	movzx	eax, word [esi-2]
	xor	[_alku_planar_vram+ebx-1], al
	%endrep
	jmp	.@@l3
.@@l2:
;	inc	ecx
;	cmp	ecx, 4
;	jne	.@@l1

	pop ebx
	pop esi
	pop ebp
	ret

global _outline
_outline:

;	ARG	src:dword, dest:dword
%define src ebp+8
%define dest ebp+12

	push ebp
	mov ebp, esp
	push esi
	push edi

	;mov	word [mrol], 0802h
	mov	ecx, 4
.@@l1:
	;mov	dx, 3c4h
	;mov	ax, [mrol]
	;out	dx, ax

	mov esi, [src]
	add	esi, ecx
	;dec	esi
	mov edi, [dest]
	add	edi, ecx

	;xor	eax, eax
	;mov	[edi-352], al
	;mov	[edi-352+176], al

  ; x = esi
  ; y = ccc
	%assign ccc 0
	%rep	75
	mov	al, [esi+ccc*640]
	mov	[edi+ccc*352*2], al
	mov	[edi+ccc*352*2+352], al
	%assign ccc ccc+1
	%endrep

	;mov	ax, ds
	;add	ax, 75*40
	;mov	ds, ax
  add esi, 75*40*16

	%assign ccc 0
	%rep	75
	mov	al, [esi+ccc*640]
	mov	[edi+ccc*352*2+75*352*2], al
	mov	[edi+ccc*352*2+75*352*2+352], al
	%assign ccc ccc+1
	%endrep

	;shr	word [mrol+1], 1
	dec	ecx
	jnz	.@@l1

	pop edi
	pop esi
	pop ebp
	ret
