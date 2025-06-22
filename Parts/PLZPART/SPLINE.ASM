extern _kx
extern _ky
extern _kz
extern _dis
extern _tx
extern _ty
extern _ls_kx
extern _ls_ky
extern _ls_kz

section .data

buu:
%include 'rata.inc'

splinecoef:
%include "spline.inc"

section .code

global _getspl
_getspl:

	;ARG	position:word
  %define position esp+8

	push ebp

	mov	si, buu
	push	cs
	pop	ds
	mov	di, [position]

	;ds:si=pointer to spline
	;di=position in spline, add 256 for next point

	mov	ax,di
	shr	ax,8
	shl	ax, 4
	add	si,ax
	and	di,255
	shl	di,1

	%assign ccc 0
	%rep 8
	mov	ax,[esi+3*2*8+ccc]
	imul	word [splinecoef+edi]
	mov	bx,ax
	mov	cx,dx
	mov	ax,[esi+2*2*8+ccc]
	imul	word [splinecoef+edi+64*8]
	add	bx,ax
	adc	cx,dx
	mov	ax,[esi+1*2*8+ccc]
	imul	word [splinecoef+edi+128*8]
	add	bx,ax
	adc	cx,dx
	mov	ax,[esi+0*2*8+ccc]
	imul	word [splinecoef+edi+192*8]
	add	bx,ax
	adc	cx,dx
	shld	cx,bx,1
	push	cx
	%assign ccc ccc+2
	%endrep

	mov	ax, _kx
	mov	ds, ax
	pop	cx
	mov	[_ls_ky], cx
	pop	cx
	mov	[_ls_kx], cx
	pop	cx
	mov	[_kz], cx
	pop	cx
	mov	[_ky], cx
	pop	cx
	mov	[_kx], cx
	pop	cx
	mov	[_dis], cx
	pop	cx
	mov	[_ty], cx
	pop	cx
	mov	[_tx], cx

	pop ebp
	ret