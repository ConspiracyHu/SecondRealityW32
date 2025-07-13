section code.

extern _shutdown_vram

global _copyline
_copyline:

	;ARG	from:dword, to:dword, count:word
%define from ebp+8
%define to ebp+12
%define count ebp+16

	push ebp
	mov ebp, esp
	push esi
	push edi

	mov esi, [from]
	shl esi, 2
	add esi, _shutdown_vram
	mov edi, [to]
	shl edi, 2
	add edi, _shutdown_vram
	mov ecx, [count]
	shl ecx, 1 ; 4 pixels

	cld
	rep	movsw

	pop edi
	pop esi
	pop ebp
	ret
