section code.

global _copyline
_copyline:

	;ARG	from:dword, to:dword, count:word

	push ebp
  mov ebp, esp
	push esi
  push edi

	mov esi, [ebp+8]
	mov edi, [ebp+12]
	mov	ecx, [ebp+16]
  shl ecx, 1 ; 4 pixels

	cld
	rep	movsw

	pop edi
  pop esi
	pop ebp
	ret
