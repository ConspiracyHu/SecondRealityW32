%include "clink.inc"

section .code

%define MAXDOTS 1024

%define BOTTOM 8000

global _gravitybottom
_gravitybottom dw BOTTOM

global _bpmin,_bpmax
_bpmin dw	30000
_bpmax dw	-30000

global _gravity
_gravity dw	0

global _dotnum
_dotnum dw	0

global _gravityd
_gravityd dw	16

dw -1280
dw -960
dw -640
dw -320
global _rows
_rows	times 200 dw 0

global _dot
_dot:
dot times MAXDOTS dw	0,0,0,0,0,0,0,0 ;x,y,z,oldposshadow,oldpos,-,-,-

global _rotsin,_rotcos
_rotsin dw 0
_rotcos dw 0

global _bgpic
_bgpic	dw 0,0

global _depthtable1,_depthtable2,_depthtable3,_depthtable4
_depthtable1 times 128 dd 0
_depthtable2 times 128 dd 0
_depthtable3 times 128 dd 0
_depthtable4 times 128 dd 0

global _drawdots
_drawdots:
	CBEG
	mov	ax,0a000h
	mov	es,ax
	mov	ax,cs
	mov	ds,ax
	mov	fs,[cs:_bgpic+2]
	mov	cx,[cs:_dotnum]
	mov	si,dot
@@1:	push	cx

	mov	ax,[ds:si+0] ;X
	imul	word [ds:_rotsin]
	mov	ax,ax
	mov	cx,dx
	mov	ax,[ds:si+4] ;Z
	imul	word [ds:_rotcos]
	sub	ax,bx
	sub	dx,cx
	mov	bp,dx
	add	bp,9000
	
	mov	ax,[ds:si+0] ;X
	imul	word [ds:_rotcos]
	mov	bx,ax
	mov	cx,dx
	mov	ax,[ds:si+4] ;Z
	imul	word [ds:_rotsin]
	add	ax,bx
	adc	dx,cx
	shrd	ax,dx,8
	sar	dx,8
	
	mov	bx,ax
	mov	cx,dx
	shrd	ax,dx,3
	sar	dx,3
	add	ax,bx
	adc	dx,cx
	
	idiv	bp
	add	ax,160
	push	ax
	cmp	ax,319
	ja	@@2
	
	;shadow

	xor	ax,ax
	mov	dx,8
	idiv	bp
	add	ax,100
	cmp	ax,199
	ja	@@2
	mov	bx,ax
	shl	bx,1
	mov	bx,[ds:_rows+bx]
	pop	ax
	add	bx,ax
	push	ax
	
	mov	di,[ds:si+6]
	mov	ax,[fs:di]
	mov	[es:di],ax
	mov	ax,87+87*256
	mov	word [es:bx],ax
	mov	[ds:si+6],bx
	
	;ball
	
	mov	ax,[ds:_gravity]
	add	[ds:si+14],ax
	mov	ax,[ds:si+2] ;Y
	add	ax,[ds:si+14]
	cmp	ax,[ds:_gravitybottom]
	jl	@@4
	push	ax
	mov	ax,[ds:si+14]
	neg	ax
	imul	word [cs:_gravityd]
	sar	ax,4
	mov	[ds:si+14],ax
	pop	ax
	add	ax,[ds:si+14]
@@4:	mov	[ds:si+2],ax
	cwd
	shld	dx,ax,6
	shl	ax,6
	idiv	bp
	add	ax,100
	cmp	ax,199
	ja	@@3
	mov	bx,ax
	shl	bx,1
	mov	bx,[ds:_rows+bx]
	pop	ax
	add	bx,ax

	mov	di,[ds:si+8]
	mov	eax,[fs:di]
	mov	[es:di],eax
	add	di,320
	mov	eax,[fs:di]
	mov	[es:di],eax
	add	di,320
	mov	eax,[fs:di]
	mov	[es:di],eax
;	add	di,320
;	mov	eax,[fs:di]
;	mov	[es:di],eax
	shr	bp,6
	and	bp,~3
	
	cmp	bp,[cs:_bpmin]
	jge	@@t1
	mov	[cs:_bpmin],bp
@@t1:	cmp	bp,[cs:_bpmax]
	jle	@@t2
	mov	[cs:_bpmax],bp
@@t2:
	mov	ax,word [ds:_depthtable1+bp]
	mov	word [es:bx+1],ax
	mov	eax,[ds:_depthtable2+bp]
	mov	dword [es:bx+320],eax
	mov	ax,word [ds:_depthtable3+bp]
	mov	word [es:bx+641],ax
	mov	[ds:si+8],bx

@@z:	pop	cx
	add	si,16
	loop	@@1
@@0:	CEND

@@2:	mov	di,[ds:si+8]
	mov	eax,[fs:di]
	mov	[es:di],eax
	add	di,320
	mov	eax,[fs:di]
	mov	[es:di],eax
	add	di,320
	mov	eax,[fs:di]
	mov	[es:di],eax
	mov	di,[ds:si+6]
	mov	[ds:si+6],ax
	mov	ax,[fs:di]
	mov	[es:di],ax
	pop	bx
	pop	cx
	add	si,16
	loop	@@1
	jmp	@@0
@@3:	mov	di,[ds:si+8]
	mov	eax,[fs:di]
	mov	[es:di],eax
	add	di,320
	mov	eax,[fs:di]
	mov	[es:di],eax
	add	di,320
	mov	eax,[fs:di]
	mov	[es:di],eax
	pop	bx
	pop	cx
	add	si,16
	loop	@@1
	jmp	@@0
  ret

global _setpalette
_setpalette:
	push	bp
	mov	bp,sp
	push	si
	push	di
	push	ds
	mov	si,[bp+6]
	mov	ds,[bp+8]
	mov	dx,3c8h
	mov	al,0
	out	dx,al
	inc	dx
	mov	cx,768
	rep	outsb
	pop	ds
	pop	di
	pop	si
	pop	bp
	ret

_face:
global _face
%include "face.inc"
dw	30000,30000,30000

global _sin1024
%include "sin1024.inc"
