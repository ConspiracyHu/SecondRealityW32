
%macro forcesetborder 1 ; color
	;local	l1
	push	ax
	push	dx
	mov	dx,3dah
	in	al,dx
	mov	dx,3c0h
	mov	al,11h+32
	out	dx,al
	mov	al,%1
	out	dx,al
	pop	dx
	pop	ax
%endmacro
	
global _setborder
_setborder:
	CBEG
	push	cx
	mov	cx,[bp+6]
	forcesetborder cl
	pop	cx
	CEND


fwaitborder:
	call	waitborder
	ret

	
waitborder:
	mov	dx,3dah
wbr1:	in	al,dx
	test	al,8
	jnz	wbr1
wbr2:	in	al,dx
	test	al,8
	jz	wbr2
	ret


clearpal:
	cli
	call	waitborder
	mov	dx,3c8h
	mov	al,0
	out	dx,al
	mov	cx,768
	inc	dx
clp1:	out	dx,al
	loop	clp1
	call	waitborder
	sti
	ret

