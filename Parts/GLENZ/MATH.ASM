%include "asm.inc"

section .data

%include "mathsin.inc"
	
;rotate sins/coss
rxsin	dw	0
rxcos	dw	0
rysin	dw	0
rycos	dw	0
rzsin	dw	0
rzcos	dw	0

section .code

;checkdeg MACRO reg
%macro checkdeg 1
	;local	l0,l1,l2
%%l0:	cmp	%1,3600
	jb	%%l1
	jl	%%l2
	;>3600
	sub	%1,3600
	jmp	%%l0
%%l2:	;<0
	add	%1,3600
	jmp	%%l0
%%l1:
%endmacro

global _cmatrix_yxz
_cmatrix_yxz:
	CBEG
	movpar	esi,12
  mov edi,esi
	movpar	ax,0 ;rotx
	mov	[esi+2],ax
	movpar	ax,4 ;roty
	mov	[esi+0],ax
	movpar	ax,8 ;rotz
	mov	[esi+4],ax
	call	calcmatrix
	CEND

calcmatrix: ;rY*rX*rZ
	;[esi+0]=rotx
	;[esi+2]=roty
	;[esi+4]=rotz
	;dest: [edi]
	;load values, check 'em and calc sin/cos
	;ROT-X
  xor ebx, ebx
	mov	bx,[esi]
	checkdeg bx
	mov	[esi],bx
	shl	bx,1
	mov	ax,[sintable16+ebx]
	mov	[rxsin],ax
	mov	ax,[costable16+ebx]
	mov	[rxcos],ax
	;ROT-Y
	mov	bx,[esi+2]
	checkdeg bx
	mov	[esi+2],bx
	shl	bx,1
	mov	ax,[sintable16+ebx]
	mov	[rysin],ax
	mov	ax,[costable16+ebx]
	mov	[rycos],ax
	;ROT-Z
	mov	bx,[esi+4]
	checkdeg bx
	mov	[esi+4],bx
	shl	bx,1
	mov	ax,[sintable16+ebx]
	mov	[rzsin],ax
	mov	ax,[costable16+ebx]
	mov	[rzcos],ax
	
	;matrix equations: rY*rX*rZ
	; 0=Ycos*Zcos-		 2=Xsin*Ysin*Zcos+	 4=-Xcos*Ysin
	;   Xsin*Ysin*Zsin	   Ycos*Zsin
	; 6=-Xcos*Zsin		 8=Xcos*Zcos		10=Xsin
	; 
	;12=Xsin*Ycos*Zsin+	14=Ysin*Zsin-		16=Xcos*Ycos
	;   Ysin*Zcos		   Xsin*Ycos*Zcos\

	mov	ax,[rysin]
	imul word	[rzsin]
	shld	dx,ax,1
	mov	[edi+14],dx ;14a
	
	mov	ax,[rycos]
	imul word	[rzcos]
	shld	dx,ax,1
	mov	[edi+0],dx ;0a
	
	mov	ax,dx
	imul word	[rxsin]
	shld	dx,ax,1
	sub	[edi+14],dx ;14b
	
	mov	ax,[rxsin]
	imul word	[rysin]
	shld	dx,ax,1
	mov	cx,dx
	
	mov	ax,[rzsin]
	imul word	dx
	shld	dx,ax,1
	sub	[edi+0],dx ;0b

	mov	ax,[rzcos]
	imul word	cx
	shld	dx,ax,1
	mov	[edi+2],dx ;2a
	
	mov	ax,[rycos]
	imul word	[rzsin]
	shld	dx,ax,1
	add	[edi+2],dx ;2b
	
	mov	ax,[rxsin]
	imul word	dx
	shld	dx,ax,1
	mov	[edi+12],dx ;12a
	
	mov	ax,[rysin]
	imul word	[rzcos]
	shld	dx,ax,1
	add	[edi+12],dx ;12b
	
	mov	ax,[rxcos]
	imul word	[rzsin]
	shld	dx,ax,1
	neg	dx
	mov	[edi+6],dx ;6

	mov	ax,[rxcos]
	imul word	[rzcos]
	shld	dx,ax,1
	mov	[edi+8],dx ;8

	mov	ax,[rxcos]
	imul word	[rysin]
	shld	dx,ax,1
	neg	dx
	mov	[edi+4],dx ;4

	mov	ax,[rxcos]
	imul word	[rycos]
	shld	dx,ax,1
	mov	[edi+16],dx ;16
	
	mov	ax,[rxsin]
	mov	[edi+10],ax ;10

	ret

calcmatrixsep: ;calc 3 separate matrices
	;[esi+0]=rotx
	;[esi+2]=roty
	;[esi+4]=rotz
	;dest: [edi]
	;load values, check 'em and calc sin/cos
	;ROT-X
	mov	bx,[esi]
	checkdeg bx
	mov	[esi],bx
	shl	bx,1
	mov	ax,[sintable16+bx]
	mov	[rxsin],ax
	mov	ax,[costable16+bx]
	mov	[rxcos],ax
	;ROT-Y
	mov	bx,[esi+2]
	checkdeg bx
	mov	[esi+2],bx
	shl	bx,1
	mov	ax,[sintable16+bx]
	mov	[rysin],ax
	mov	ax,[costable16+bx]
	mov	[rycos],ax
	;ROT-Z
	mov	bx,[esi+4]
	checkdeg bx
	mov	[esi+4],bx
	shl	bx,1
	mov	ax,[sintable16+bx]
	mov	[rzsin],ax
	mov	ax,[costable16+bx]
	mov	[rzcos],ax
	mov	bx,0
	mov	cx,32767
	
	;rX
	mov	[edi+0],cx
	mov	[edi+2],bx
	mov	[edi+4],bx
	mov	[edi+6],bx
	mov	ax,[rxcos]
	mov	[edi+8],ax
	mov	ax,[rxsin]
	mov	[edi+10],ax
	mov	[edi+12],bx
	mov	ax,[rxsin]
	neg	ax
	mov	[edi+14],ax
	mov	ax,[rxcos]
	mov	[edi+16],ax
	add	di,18
	
	;rY
	mov	ax,[rycos]
	mov	[edi+0],ax
	mov	[edi+2],bx
	mov	ax,[rysin]
	neg	ax
	mov	[edi+4],ax
	mov	[edi+6],bx
	mov	[edi+8],cx
	mov	[edi+10],bx
	mov	ax,[rysin]
	mov	[edi+12],ax
	mov	[edi+14],bx
	mov	ax,[rycos]
	mov	[edi+16],ax
	add	di,18
	
	;rZ
	mov	ax,[rzcos]
	mov	[edi+0],ax
	mov	ax,[rzsin]
	mov	[edi+2],ax
	mov	[edi+4],bx
	mov	ax,[rzsin]
	neg	ax
	mov	[edi+6],ax
	mov	ax,[rzcos]
	mov	[edi+8],ax
	mov	[edi+10],bx
	mov	[edi+12],bx
	mov	[edi+14],bx
	mov	[edi+16],cx
	add	di,18
	
	ret

calcmatrix0: ;rX*rY*rZ
	;[esi]=rotx
	;[esi]=roty
	;[esi]=rotz
	;dest: [edi]
	;load values, check 'em and calc sin/cos
	;ROT-X
	mov	bx,[esi]
	checkdeg bx
	mov	[esi],bx
	shl	bx,1
	mov	ax,[sintable16+bx]
	mov	[rxsin],ax
	mov	ax,[costable16+bx]
	mov	[rxcos],ax
	;ROT-Y
	mov	bx,[esi+2]
	checkdeg bx
	mov	[esi+2],bx
	shl	bx,1
	mov	ax,[sintable16+bx]
	mov	[rysin],ax
	mov	ax,[costable16+bx]
	mov	[rycos],ax
	;ROT-Z
	mov	bx,[esi+4]
	checkdeg bx
	mov	[esi+4],bx
	shl	bx,1
	mov	ax,[sintable16+bx]
	mov	[rzsin],ax
	mov	ax,[costable16+bx]
	mov	[rzcos],ax
	
	;matrix equations: rX*rY*rZ ;rZ*rY*rX
	; 0=Ycos*Zcos		 2=Ycos*Zsin		 4=-Ysin
	; 6=Xsin*Zcos*Ysin	 8=Xsin*Ysin*Zsin	10=Ycos*Xsin
	;   -Xcos*Zsin		   +Xcos*Zcos
	;12=Xcos*Zcos*Ysin	14=Xcos*Ysin*Zsin	16=Ycos*Xcos
	;   +Xsin*Zsin		   -Xsin*Zcos
	
	;calculate rotation matrix
	;0,2,10,16,4
	mov	bx,[rycos]
	mov	ax,[rzcos]
	imul	bx
	shld	dx,ax,1
	mov	[edi+0],dx
	;
	mov	ax,[rzsin]
	imul	bx
	shld	dx,ax,1
	mov	[edi+2],dx
	;
	mov	ax,[rxsin]
	imul	bx
	shld	dx,ax,1
	mov	[edi+10],dx
	;
	mov	ax,[rxcos]
	imul	bx
	shld	dx,ax,1
	mov	[edi+16],dx
	;
	mov	ax,[rysin]
	neg	ax
	mov	[edi+4],ax
	;6,8
	mov	ax,[rxsin]
	imul word	[rysin]
	shld	dx,ax,1
	mov	cx,dx
	;
	mov	ax,cx
	imul word	[rzcos]
	shld	dx,ax,1
	mov	[edi+6],dx
	;
	mov	ax,cx
	imul word	[rzsin]
	shld	dx,ax,1
	mov	[edi+8],dx
	;
	mov	bx,[rxcos]
	mov	ax,[rzsin]
	imul word	bx
	shld	dx,ax,1
	sub	[edi+6],dx
	;
	mov	ax,[rzcos]
	imul word	bx
	shld	dx,ax,1
	add	[edi+8],dx
	;12,14
	mov	ax,[rxcos]
	imul word	[rysin]
	shld	dx,ax,1
	mov	cx,dx
	;
	mov	ax,cx
	imul word	[rzcos]
	shld	dx,ax,1
	mov	[edi+12],dx
	;
	mov	ax,cx
	imul word	[rzsin]
	shld	dx,ax,1
	mov	[edi+14],dx
	;
	mov	bx,[rxsin]
	mov	ax,[rzsin]
	imul	bx
	shld	dx,ax,1
	add	[edi+12],dx
	;
	mov	ax,[rzcos]
	imul	bx
	shld	dx,ax,1
	sub	[edi+14],dx

	ret

%macro mulmacro 2;	row,col
	mov	ax,[esi+0+%1*6]
	imul	word [edi+0+%2*2]
	mov	cx,dx
	mov	bx,ax
	mov	ax,[esi+2+%1*6]
	imul	word [edi+6+%2*2]
	add	cx,dx
	add	bx,ax
	mov	ax,[esi+4+%1*6]
	imul	word [edi+12+%2*2]
	add	cx,dx
	add	bx,ax
	shld	cx,bx,1
%endmacro

mulmatrices:
	;ds:si=matrix1,es:di=matrix2 => ds:si (overwrite)
	mulmacro 0,0
	push	cx
	mulmacro 0,1
	push	cx
	mulmacro 0,2
	push	cx
	
	mulmacro 1,0
	push	cx
	mulmacro 1,1
	push	cx
	mulmacro 1,2
	push	cx
	
	mulmacro 2,0
	push	cx
	mulmacro 2,1
	push	cx
	mulmacro 2,2

	mov	[esi+4+12],cx
	pop	word [esi+2+12]
	pop	word [esi+0+12]
	pop	word [esi+4+6]
	pop	word [esi+2+6]
	pop	word [esi+0+6]
	pop	word [esi+4]
	pop	word [esi+2]
	pop	word [esi+0]
	ret
