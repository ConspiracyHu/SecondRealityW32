section .data

%define PLZ(x) plz_y %+ ccc

%macro LOOP_LARGE 1
  loop %%notDone
  jmp %%done
  %%notDone:
  jmp %1
  %%done:
%endmacro

global _jmp_tau
_jmp_tau:
%assign ccc 0
%rep 200
;IRP ccc, <0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199>
dd PLZ(x)
%endrep

start_mask:
%rep 200
	db	1111b, 1110b, 1100b, 1000b
%endrep
end_mask:
%rep 200
	db	0001b, 0011b, 0111b, 1111b
%endrep

global _to
_to	  dd	0a0000000h
global _dseg
_dseg	dd	0
ycnt	dw	0

section .bss

global _xx
global _yy
global _yy1
global _xx1
global _yy2
global _xx2
global _ay1
global _ax1
global _ay2
global _ax2
global _txx1
global _txy1
global _txx2
global _txy2
global _tax1
global _tay1
global _tax2
global _tay2
global _from
global _ctau

_xx	  resw	1
_yy	  resw	1
_yy1	resd	1
_xx1	resd	1
_yy2	resd	1
_xx2	resd	1
_ay1	resd	1
_ax1	resd	1
_ay2	resd	1
_ax2	resd	1
_txx1	resd	1
_txy1	resd	1
_txx2	resd	1
_txy2	resd	1
_tax1	resd	1
_tay1	resd	1
_tax2	resd	1
_tay2	resd	1
_from	resd	1
_ctau	resd	1

_linecount	resw	1

section .code

global _do_block
_do_block:
	;ARG	ycount:word
  %define ycount esp+8
  push ebp

	mov	ax, [ycount]
	mov	[_linecount], ax
	cmp	ax, 0
	je	..@end

	; ds:bx = from
	; es:di = to (vram)
	; gs:si = ctau
	; fs = dseg

	mov ebx, _from
	mov edi, _to
	mov esi, _ctau
	;mov	fs, [_dseg]

..@doline:
	cmp	word [_yy], 0
	jl	..@endline
	cmp	word [_yy], 134
	jge	..@end				; y-clip

	mov	ebp, [_ctau]
	movsx	eax, word [_xx2+2]
	cmp	ax, [ebp]
	ja	..@l7
	mov	[ebp], ax			; x1..
..@l7:	shr	eax, 2
	add	edi, eax
	movsx	esi, word [_xx1+2]
	cmp	si, [ebp+2]
	jb	..@l8
	mov	[ebp+2], si			; x2..
..@l8:	shr	esi, 2
	sub	esi, eax			; si = bytes to copy
	jb	..@endline
	jz	..@singlebyte
	mov	ebp, esi
	dec	esi
	jz	..@twobyte

	mov	dx, 3c4h
	mov	ax, 0f02h
	;out	dx, ax

	mov	ebx, [_txy1-2]		; xlo
	mov	ecx, [_txx1-2]		; ylo

	movsx	esi, si
	mov	eax, [_txy2]
	sub	eax, [_txy1]
	cdq
	idiv	esi                   	; addy
	mov	ecx, eax
	mov	eax, [_txx2]
	sub	eax, [_txx1]
	cdq
	idiv   	esi			; addx

	mov	edx, ecx      		; look reg table
	rol	edx, 16		; y_add
	mov	dh, dl			; yah
	rol	eax, 16		; x_add
	mov	dl, al			; xah
	test	dl, 80h
	jz	..@l2
	dec	dh
..@l2:
	movzx	ebx, byte [_txx1+2]	; txt x
	mov	bh, byte [_txy1+2]       ; txt y
	test	si, 1
	jz	..@ll1

	add	ecx, eax
  mov eax, _dseg
	movzx	esi, byte [eax+ebx]		; out odd byte
  add esi, _from
	mov	al, [ebx+esi]
	adc	ebx, edx
	adc	bh, 0
	mov	[ebp+edi-1],al
	jmp	[_jmp_tau+ebp-4]

..@ll1:	jmp	[_jmp_tau+esi]		; and jump to rept

;		e	h	l
;	ax	x_add	data	data
;	bx	ylo	ty	tx
;	cx	xlo	-	-
;	dx	y_add	yah	xah
;	di	-
;	si	sinus inc

;	ALIGN	4
;IRP ccc, <200,199,198,197,196,195,194,193,192,191,190,189,188,187,186,185,184,183,182,181,180,179,178,177,176,175,174,173,172,171,170,169,168,167,166,165,164,163,162,161,160,159,158,157,156,155,154,153,152,151,150,149,148,147,146,145,144,143,142,141,140,139,138,137,136,135,134,133,132,131,130,129,128,127,126,125,124,123,122,121,120,119,118,117,116,115,114,113,112,111,110,109,108,107,106,105,104,103,102,101,100,99,98,97,96,95,94,93,92,91,90,89,88,87,86,85,84,83,82,81,80,79,78,77,76,75,74,73,72,71,70,69,68,67,66,65,64,63,62,61,60,59,58,57,56,55,54,53,52,51,50,49,48,47,46,45,44,43,42,41,40,39,38,37,36,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1>
  push ebp
  mov ebp, _dseg
%assign ccc 200
%rep 200

PLZ(x) :

	movzx	si, [ebp+ebx]
	add	ecx, eax
	mov	ah, [ebx+esi]
	adc	ebx, edx
	adc	bh, 0

	movzx	si, [ebp+ebx]
	add	ecx, eax
	mov	al, [ebx+esi]
	adc	ebx, edx
	adc	bh, 0			; immediate = y_hi

	mov	[edi+ccc*2-1], ax	; output byte
  %assign ccc ccc-1
%endrep
  pop ebp
plz_y0:

..@twobyte:
  push ebp
  mov ebp, _dseg
	movzx	ebx, byte [_txx2+2]	; txt x
	mov	bh, byte [_txy2+2]       ; txt y
	movzx	si, byte [ebp+ebx]
  add esi, _from
	mov	cl, [ebx+esi]
	movzx	ebx, byte [_txx1+2]	; txt x
	mov	bh, byte [_txy1+2]       ; txt y
	movzx	si, byte [ebp+ebx]
  add esi, _from
	mov	ch, [ebx+esi]
  pop ebp

	mov	bx, word [_xx2+2]
	and	bx, 3
	mov	ah, [start_mask+bx]
	mov	al, 02
	mov	dx, 3c4h
	;out	dx, ax
	mov	[es:di], cl

	mov	bx, word [_xx1+2]
	and	bx, 3
	mov	ah, [end_mask+bx]
	;out	dx, ax
	mov	[es:bp+di], ch

..@endline:
	add	word [_to], 160		; next line
	mov	di, word [_to]
	inc	word [_yy]
	add	word [_ctau], 4

	mov	eax, [_ax1]
	add	[_xx1], eax
	mov	eax, [_ax2]
	add	[_xx2], eax
	mov	eax, [_tay1]
	add	[_txy1], eax
	mov	eax, [_tax1]
	add	[_txx1], eax
	mov	eax, [_tay2]
	add	[_txy2], eax
	mov	eax, [_tax2]
	add	[_txx2], eax		; increment txt and line indexes

	dec	word [_linecount]
	jnz	..@doline

..@end:
	pop	ebp
	ret


..@singlebyte:
  mov ebp, _dseg
	movsx	ebx, byte [_txx2+2]	; txt x
  mov	bh, byte [_txy2+2]       ; txt y
	movzx	si, byte [ebp+ebx]
	mov	cl, [ebx+esi]

	mov	al, 02
	mov	dx, 3c4h
	mov	bx, word [_xx2+2]
	and	bx, 3
	mov	ah, [start_mask+ebx]
	mov	bx, word [_xx1+2]
	and	bx, 3
	and	ah, [end_mask+ebx]
	;out	dx, ax
	mov	[es:di], cl

	add	word [_to], 160		; next line
	mov	di, word [_to]
	inc	word [_yy]
	add	word [_ctau], 4

	mov	eax, [_ax1]
	add	[_xx1], eax
	mov	eax, [_ax2]
	add	[_xx2], eax
	mov	eax, [_tay1]
	add	[_txy1], eax
	mov	eax, [_tax1]
	add	[_txx1], eax
	mov	eax, [_tay2]
	add	[_txy2], eax
	mov	eax, [_tax2]
	add	[_txx2], eax		; increment txt and line indexes

	dec	word [_linecount]
	jnz	..@doline
	pop	ebp
	ret

global _shadepal
_shadepal:

	;ARG	fpal:dword, ppal:dword, shd:word
  %define fpal esp+8
  %define ppal esp+12
  %define shd esp+16

	push	ebp

	mov esi, [ppal]
	mov edi, [fpal]
	mov edx, [shd]
	mov	cx, 192/16
..@loop:
	%rep	16
	lodsb
	mul	dl
	shr	ax, 6
	stosb
	%endrep
	LOOP_LARGE	..@loop

	pop	ebp
	ret

global _do_clear
_do_clear:

;	ARG	vmem:dword, otau:dword, ntau:dword
  %define vmem esp+8
  %define otau esp+12
  %define ntau esp+16

	push	ebp

	mov	dx, 3c4h
	mov	ax, 0f02h
	;out	dx, ax

	mov edx, [vmem]
  mov edi, edx
	mov ebx, [otau]		; dx:bx-> otau
	mov esi, [ntau]
	sub	esi, ebx                  ; dx:bx+si-> ntau
	movzx	edx, byte [vmem]		; fill latches
	mov	word [ycnt], 134
	xor	eax, eax

..@lineloop:
	cmp	word [ebx], 640
	je	..@nextline

	movzx	edi, word [ebx]
	shr	edi, 2
	movzx	ecx, word [ebx+esi]
	shr	ecx, 2
	sub	ecx, edi
	jb	..@l1
	add	edi, edx
  add edi, [vmem]
	rep	stosb
..@l1:
	movzx	edi, word [ebx+esi+2]
	shr	edi, 2
	movzx	ecx, word [ebx+2]
	shr	ecx, 2
	sub	ecx, edi
	jb	..@nextline
	add	edi, edx
	inc	edi
  add edi, [vmem]
	rep	stosb

..@nextline:
	mov	word [ebx], 640
	mov	word [ebx+2], 0

	add	dx, 160
	add	bx, 4
	sub	word [ycnt], 1
	jae	..@lineloop

; Maskaa p„„t...

	mov edi, [vmem]
	mov esi, [ntau]		; dx:bx-> ntau
	mov	cx, 134
	mov	dx, 3c4h
	mov	ax, 0f02h
..@maskloop:
	movzx	ebx, word [esi]
	dec	bx
	mov	ah, [end_mask+ebx]
	;out	dx, ax
	shr	bx, 2
	mov	[ebx+edi], ch

	movzx	ebx, word [esi+2]
	inc	bx
	mov	ah, [start_mask+ebx]
	;out	dx, ax
	shr	bx, 2
	mov	[ebx+edi], ch

..@nextmask:
	add	si,4
	add	di, 160
	loop	..@maskloop

	pop	ebp
	ret
