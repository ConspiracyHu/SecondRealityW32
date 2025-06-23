section .code
global _zoom
_zoom:
	push	bp
	mov	bp,sp
	push	si
	push	di
	push	ds
	
	les	di,[bp+6]
	lds	si,[bp+10]
	mov	ax,[bp+14]
	call	zoom
	
	pop	ds
	pop	di
	pop	si
	pop	bp
	ret

%include "zoomloop.inc"

section .data

global _glenz_sin1024
%include "sin1024.inc"
