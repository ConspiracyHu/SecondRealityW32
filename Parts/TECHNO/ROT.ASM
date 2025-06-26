section .code

start:
  call	_rol
	mov	ax,4c00h
	int	21h
	
waitb:
	mov	dx,3dah
@@1:	in	al,dx
	test	al,8
	jnz	@@1
@@2:	in	al,dx
	test	al,8
	jnz	@@2
	ret

_rol:
	call	waitb
	
	ret
	