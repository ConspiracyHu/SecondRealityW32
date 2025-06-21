%include "clink.inc"

section .data

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
_bgpic times 64000 db 0

extern _shim_vram

global _depthtable1,_depthtable2,_depthtable3,_depthtable4
_depthtable1 times 128 dd 0
_depthtable2 times 128 dd 0
_depthtable3 times 128 dd 0
_depthtable4 times 128 dd 0

section .code

global _drawdots
_drawdots:
	CBEG

  ; ds:si = dot array
  ; es:di = video memory
  ; fs:di = background

  mov edi,_shim_vram

	movzx	ecx, word [_dotnum]
	mov	esi, dot
@@1:	push	ecx

	mov	ax,[esi+0] ;X
	imul	word [_rotsin]
	mov	ax,ax
	mov	cx,dx
	mov	ax,[esi+4] ;Z
	imul	word [_rotcos]
	sub	ax,bx
	sub	dx,cx
	movsx	ebp,dx
	add	ebp,9000
	
	mov	ax,[esi+0] ;X
	imul	word [_rotcos]
	mov	bx,ax
	mov	cx,dx
	mov	ax,[esi+4] ;Z
	imul	word [_rotsin]
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
	push	eax
	cmp	ax,319
	ja	@@2
	
	;shadow

	xor	ax,ax
	mov	dx,8
	idiv	bp
	add	ax,100
	cmp	ax,199
	ja	@@2
	movzx	ebx,ax
	shl	ebx,1
	mov	bx,[_rows+ebx]
	pop	eax
	add	bx,ax
	push	eax
	
	movzx	edi, word [esi+6]
	mov	ax,[_bgpic+edi]
	mov	[_shim_vram+edi],ax
	mov	ax,87+87*256
	mov	word [_shim_vram+ebx],ax
	mov	[esi+6],bx
	
	;ball
	
	mov	ax,[_gravity]
	add	[esi+14],ax
	mov	ax,[esi+2] ;Y
	add	ax,[esi+14]
	cmp	ax,[_gravitybottom]
	jl	@@4
	push	eax
	mov	ax,[esi+14]
	neg	ax
	imul	word [_gravityd]
	sar	ax,4
	mov	[esi+14],ax
	pop	eax
	add	ax,[esi+14]
@@4:	mov	[esi+2],ax
	cwd
	shld	dx,ax,6
	shl	ax,6
	idiv	bp
	add	ax,100
	cmp	ax,199
	ja	@@3
	movzx	ebx,ax
	shl	ebx,1
	mov	bx,[_rows+ebx]
	pop	eax
	add	bx,ax

	mov	di,[esi+8]
	mov	eax,[_bgpic+edi]
	mov	[_shim_vram+edi],eax
	add	di,320
	mov	eax,[_bgpic+edi]
	mov	[_shim_vram+edi],eax
	add	di,320
	mov	eax,[_bgpic+edi]
	mov	[_shim_vram+edi],eax
;	add	di,320
;	mov	eax,[_bgpic+edi]
;	mov	[_shim_vram+edi],eax
	shr	bp,6
	and	bp,~3
	
	cmp	bp,[_bpmin]
	jge	@@t1
	mov	[_bpmin],bp
@@t1:	cmp	bp,[_bpmax]
	jle	@@t2
	mov	[_bpmax],bp
@@t2:
	mov	ax,word [_depthtable1+ebp]
	mov	word [_shim_vram+ebx+1],ax
	mov	eax,[_depthtable2+ebp]
	mov	dword [_shim_vram+ebx+320],eax
	mov	ax,word [_depthtable3+ebp]
	mov	word [_shim_vram+ebx+641],ax
	mov	[esi+8],bx

@@z:	pop	ecx
	add	esi,16
	LOOP_LARGE	@@1
@@0:	CEND

@@2:	mov	di,[esi+8]
	mov	eax,[_bgpic+edi]
	mov	[_shim_vram+edi],eax
	add	di,320
	mov	eax,[_bgpic+edi]
	mov	[_shim_vram+edi],eax
	add	di,320
	mov	eax,[_bgpic+edi]
	mov	[_shim_vram+edi],eax
	mov	di,[esi+6]
	mov	[esi+6],ax
	mov	ax,[_bgpic+edi]
	mov	[_shim_vram+edi],ax
	pop	ebx
	pop	ecx
	add	esi,16
	LOOP_LARGE	@@1
	jmp	@@0
@@3:	mov	di,[esi+8]
	mov	eax,[_bgpic+edi]
	mov	[_shim_vram+edi],eax
	add	di,320
	mov	eax,[_bgpic+edi]
	mov	[_shim_vram+edi],eax
	add	di,320
	mov	eax,[_bgpic+edi]
	mov	[_shim_vram+edi],eax
	pop	ebx
	pop	ecx
	add	esi,16
	LOOP_LARGE	@@1
	jmp	@@0
  ret

section .data
_face:
global _face
%include "face.inc"
dw	30000,30000,30000

global _sin1024
%include "sin1024.inc"
