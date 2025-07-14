;/****************************************************************************
;** MODULE:	acalc.asm
;** AUTHOR:	Sami Tammilehto / Fennosoftec OY
;** DOCUMENT:	?
;** VERSION:	1.0
;** REFERENCE:	-
;** REVISED BY:	-
;*****************************************************************************
;**
;** Assembler / Calculations
;**
;****************************************************************************/

%include "a.inc"

segment .code

extern	_datanull
extern	_sintable
extern	_avistan
extern	_afilldiv

extern	_projclipx
extern	_projclipy
extern	_projclipz
extern	_projmulx
extern	_projmuly
extern	_projaddx
extern	_projaddy

;entry: bx=angle (0..65535)
; exit: ax=sin(angle) [range -unit..unit]
sin:
	movzx	ebx, bx
	shr	ebx,4-1
	and	ebx,(~1) & 0xFFFF
	movzx	eax, word [_sintable+ebx]
	ret

	
;entry: bx=angle (0..65535)
; exit: ax=cos(angle) [range -unit..unit]
cos:
	movzx	ebx, bx
	shr	ebx,4-1
	add	ebx,1024*2
	and	ebx,~ (8192 | 1)
	movzx	eax, word [_sintable+ebx]
	ret

	
;entry: bx=angle (0..65535)
; exit: ax=sin(angle) [range -unit..unit]
;       bx=cos(angle) [range -unit..unit]
sincos:
	movzx	ebx, bx
	shr	ebx,4-1
	and	ebx,(~1) & 0xFFFF
	movzx	eax, word [_sintable+ebx]
	add	ebx,1024*2
	and	ebx,~ (8192 | 1)
	movzx	ebx, word [_sintable+ebx]
	ret


;used for matrix multiply EXPECTS the matrices to be of integer size
%macro mulmacro 2 ; row,col
	mov	eax,[esi+0+%1*12]
	imul	dword [edi+0+%2*4]
	mov	ebx,eax
	mov	eax,[esi+4+%1*12]
	imul	dword [edi+12+%2*4]
	add	ebx,eax
	mov	eax,[esi+8+%1*12]
	imul	dword [edi+24+%2*4]
	add	ebx,eax
	sar	ebx,unitshr
%endmacro

;entry:	fs:si=matrix1, es:di=matrix2
; exit: fs:si=matrix1*matrix2 (matrix 1 overwritten)
mulmatrices:
;	push	ds
;	mov	ax,fs
;	mov	ds,ax
	
	mulmacro 0,0
	push	ebx
	mulmacro 0,1
	push	ebx
	mulmacro 0,2
	push	ebx
	
	mulmacro 1,0
	push	ebx
	mulmacro 1,1
	push	ebx
	mulmacro 1,2
	push	ebx
	
	mulmacro 2,0
	push	ebx
	mulmacro 2,1
	push	ebx
	mulmacro 2,2

	mov	      [esi+8+24],ebx
	pop	dword [esi+4+24]
	pop	dword [esi+0+24]
	pop	dword [esi+8+12]
	pop	dword [esi+4+12]
	pop	dword [esi+0+12]
	pop	dword [esi+8]
	pop	dword [esi+4]
	pop	dword [esi+0]
;	pop	ds
	ret


;entry:	fs:si=matrix1, es:di=matrix2
; exit: es:di=matrix1*matrix2 (matrix 2 overwritten)
mulmatrices2:
	;push	ds
	;mov	ax,fs
	;mov	ds,ax
	
	mulmacro 0,0
	push	ebx
	mulmacro 0,1
	push	ebx
	mulmacro 0,2
	push	ebx
	
	mulmacro 1,0
	push	ebx
	mulmacro 1,1
	push	ebx
	mulmacro 1,2
	push	ebx
	
	mulmacro 2,0
	push	ebx
	mulmacro 2,1
	push	ebx
	mulmacro 2,2

	mov	      [edi+8+24],ebx
	pop	dword [edi+4+24]
	pop	dword [edi+0+24]
	pop	dword [edi+8+12]
	pop	dword [edi+4+12]
	pop	dword [edi+0+12]
	pop	dword [edi+8]
	pop	dword [edi+4]
	pop	dword [edi+0]
	;pop	ds
	ret


;entry:	ax=rotx, bx=roty, cx=rotz, es:di=rmatrix.m
; exit: (writes rmatrix.m)
calcmatrixsep: ;calc 3 separate matrices
	push	ebp
	mov	ebp,esp
	sub	esp,12 ;for local variables
	push	edi
	
	push	ebx
	push	ecx
	mov	ebx,eax
	neg	ebx
	call	sincos
	mov	[ebp-12+0],ax ;rxsin
	mov	[ebp-12+2],bx ;rxcos
	pop	ebx
	neg	ebx
	call	sincos
	mov	[ebp-12+4],ax ;rysin
	mov	[ebp-12+6],bx ;rycos
	pop	ebx
	neg	ebx
	call	sincos
	mov	[ebp-12+8],ax ;rzsin
	mov	[ebp-12+10],bx ;rzcos

	mov	ebx,0
	mov	ecx,unit
	
	;rX
	mov	[edi+2*0],ecx
	mov	[edi+2*2],ebx
	mov	[edi+2*4],ebx
	mov	[edi+2*6],ebx
	movsx	eax,word [ebp-12+2]
	mov	[edi+2*8],eax
	movsx	eax,word [ebp-12+0]
	mov	[edi+2*10],eax
	mov	[edi+2*12],ebx
	movsx	eax,word [ebp-12+0]
	neg	eax
	mov	[edi+2*14],eax
	movsx	eax,word [ebp-12+2]
	mov	[edi+2*16],eax
	add	edi,36
	
	;rY
	movsx	eax,word [ebp-12+6]
	mov	[edi+2*0],eax
	mov	[edi+2*2],ebx
	movsx	eax,word [ebp-12+4]
	neg	eax
	mov	[edi+2*4],eax
	mov	[edi+2*6],ebx
	mov	[edi+2*8],ecx
	mov	[edi+2*10],ebx
	movsx	eax,word [ebp-12+4]
	mov	[edi+2*12],eax
	mov	[edi+2*14],ebx
	movsx	eax,word [ebp-12+6]
	mov	[edi+2*16],eax
	add	edi,36
	
	;rZ
	movsx	eax,word [ebp-12+10]
	mov	[edi+2*0],eax
	movsx	eax,word [ebp-12+8]
	mov	[edi+2*2],eax
	mov	[edi+2*4],ebx
	movsx	eax,word [ebp-12+8]
	neg	eax
	mov	[edi+2*6],eax
	movsx	eax,word [ebp-12+10]
	mov	[edi+2*8],eax
	mov	[edi+2*10],ebx
	mov	[edi+2*12],ebx
	mov	[edi+2*14],ebx
	mov	[edi+2*16],ecx

	pop	edi
	mov	esp,ebp
	pop	ebp
	ret


;北北北北 _calc_setrmatrix_ident(rmatrix *matrix) 北北北北
;entry: matrix=destination matrix (only rotation fields modified)
; exit:	(data written to matrix)
;descr: Writes an identity rotation matrix to rmatrix
_calc_setrmatrix_ident:
	CBEG
	push	edi

	lespar	edi,0
	mov	edx,unit
	xor	eax,eax
	mov	[edi+rmatrix_m+0*4],edx
	mov	[edi+rmatrix_m+1*4],eax
	mov	[edi+rmatrix_m+2*4],eax
	mov	[edi+rmatrix_m+3*4],eax
	mov	[edi+rmatrix_m+4*4],edx
	mov	[edi+rmatrix_m+5*4],eax
	mov	[edi+rmatrix_m+6*4],eax
	mov	[edi+rmatrix_m+7*4],eax
	mov	[edi+rmatrix_m+8*4],edx

	pop	edi
	CEND


;北北北北 _calc_setrmatrix_rotyxz(rmatrix *matrix,angle rotx,angle roty,angle rotz) 北北北北
;entry: matrix=destination matrix (only rotation fields modified)
;	rotx/y/z=rotation angles
; exit:	(data written to matrix)
;descr: Calculates a rotation matrix
_calc_setrmatrix_rotyxz:
	CBEGR	36*3
;	mov	ax,ss
;	mov	es,ax
;	mov	fs,ax
	movpar	eax,1
	movpar	ebx,2
	movpar	ecx,3
	lea	edi,[ebp-36*3]
	call	calcmatrixsep
	lea	esi,[ebp-36*3+36*1]
	lea	edi,[ebp-36*3+36*0]
	call	mulmatrices ;Y*=X
	lea	esi,[ebp-36*3+36*1]
	lea	edi,[ebp-36*3+36*2]
	call	mulmatrices ;Y*=Z
	lespar	edi,0
	%assign zzz 0
	%rep 9
	mov	eax,[esi+zzz]
	mov	[edi+rmatrix_m+zzz],eax
	%assign zzz zzz+4
	%endrep
	CENDR


;北北北北 _calc_setrmatrix_rotxyz(rmatrix *matrix,angle rotx,angle roty,angle rotz) 北北北北
;entry: matrix=destination matrix (only rotation fields modified)
;	rotx/y/z=rotation angles
; exit:	(data written to matrix)
;descr: Calculates a rotation matrix
_calc_setrmatrix_rotxyz:
	CBEGR	36*3
	;mov	ax,ss
	;mov	es,ax
	;mov	fs,ax
	movpar	eax,1
	movpar	ebx,2
	movpar	ecx,3
	lea	edi,[ebp-36*3]
	call	calcmatrixsep
	lea	esi,[ebp-36*3+36*0]
	lea	edi,[ebp-36*3+36*1]
	call	mulmatrices ;X*=Y
	lea	esi,[ebp-36*3+36*0]
	lea	edi,[ebp-36*3+36*2]
	call	mulmatrices ;X*=Z
	lespar	edi,0
	%assign zzz 0
	%rep	9
	mov	eax,[esi+zzz]
	mov	[edi+rmatrix_m+zzz],eax
	%assign zzz zzz+4
	%endrep
	CENDR


;北北北北 _calc_setrmatrix_rotzyx(rmatrix *matrix,
;                angle rotx,angle roty,angle rotz) 北北北北
;entry: matrix=destination matrix (only rotation fields modified)
;	rotx/y/z=rotation angles
; exit:	(data written to matrix)
;descr: Calculates a rotation matrix
_calc_setrmatrix_rotzyx:
	CBEGR	36*3
	;mov	ax,ss
	;mov	es,ax
	;mov	fs,ax
	movpar	eax,1
	movpar	ebx,2
	movpar	ecx,3
	lea	edi,[ebp-36*3]
	call	calcmatrixsep
	lea	esi,[ebp-36*3+36*2]
	lea	edi,[ebp-36*3+36*1]
	call	mulmatrices ;Z*=Y
	lea	esi,[ebp-36*3+36*2]
	lea	edi,[ebp-36*3+36*0]
	call	mulmatrices ;Z*=X
	lespar	edi,0
	%assign zzz 0
	%rep	9
	mov	eax,[esi+zzz]
	mov	[edi+rmatrix_m+zzz],eax
	%assign zzz zzz+4
	%endrep
	CENDR


;北北北北 _calc_mulrmatrix(rmatrix *dest, rmatrix *source) 北北北北
;entry: dest=destination matrix (matrix modified)
;	source=source matrix (modifying matrix)
; exit:	(data written to dest matrix)
;descr: dest=source*dest. Transposition first, rotation second.
_calc_mulrmatrix:
	CBEG
	;fs:si=dest, es:di=source
	lfspar	si,0
	lespar	di,2
	call	mulmatrices
	;fs:si now has the new rotation matrix, next rotate position
	push	bp
	lespar	di,0
	add	di,rmatrix_x
	ldspar	si,2 ;DS destroyed
	lfspar	bp,0
	add	bp,rmatrix_x
	call	rotatesingle
	pop	bp
	;translate (inverse)
	lespar	di,2
	lfspar	si,0
	mov	eax,[edi+rmatrix_x]
	add	[esi+rmatrix_x],eax
	mov	eax,[edi+rmatrix_y]
	add	[esi+rmatrix_y],eax
	mov	eax,[edi+rmatrix_z]
	add	[esi+rmatrix_z],eax
@@x:	CEND


;北北北北 _calc_applyrmatrix(rmatrix *dest, rmatrix *apply) 北北北北
;entry: dest=destination matrix (matrix modified)
;	apply=apply matrix (modifying matrix)
; exit:	(data written to dest matrix)
;descr: The apply matrix is the camera matrix, the dest contains
;	the objects own rotation/position, which is modified
;	according to the camera.
_calc_applyrmatrix:
	CBEG
	push	esi
	push	edi
	push	ebx

	;fs:si=source, es:di=dest
	lfspar	esi,1
	lespar	edi,0
	call	mulmatrices2
	;es:di now has the new rotation matrix, next rotate position
	push	ebp
	lespar	edi,0
	add	edi,rmatrix_x
	ldspar	esi,1 ;rotate according to apply matrix
	lfspar	ebp,0
	add	ebp,rmatrix_x
	call	rotatesingle
	pop	ebp
	;translate
	lespar	edi,1
	lfspar	esi,0
	mov	eax,[edi+rmatrix_x]
	add	[esi+rmatrix_x],eax
	mov	eax,[edi+rmatrix_y]
	add	[esi+rmatrix_y],eax
	mov	eax,[edi+rmatrix_z]
	add	[esi+rmatrix_z],eax
@@x:
	pop	ebx
	pop	edi
	pop	esi
	CEND


rotatesingle:
	;ds:si=rmatrix
	;fs:bp=source[]: x,y,z (long)
	;es:di=destination[]: x,y,z (long)
	;destination and source can be same
	mov	eax,[ebp+0]
	imul	dword [esi+rmatrix_m+2*0]
	mov	ebx,eax
	mov	ecx,edx
	mov	eax,[ebp+4]
	imul	dword [esi+rmatrix_m+2*2]
	add	ebx,eax
	adc	ecx,edx
	mov	eax,[ebp+8]
	imul	dword [esi+rmatrix_m+2*4]
	add	ebx,eax
	adc	ecx,edx
	shrd	ebx,ecx,unitshr
	push	ebx
	
	mov	eax,[ebp+0]
	imul	dword [esi+rmatrix_m+2*6]
	mov	ebx,eax
	mov	ecx,edx
	mov	eax,[ebp+4]
	imul	dword [esi+rmatrix_m+2*8]
	add	ebx,eax
	adc	ecx,edx
	mov	eax,[ebp+8]
	imul	dword [esi+rmatrix_m+2*10]
	add	ebx,eax
	adc	ecx,edx
	shrd	ebx,ecx,unitshr
	push	ebx
	
	mov	eax,[ebp+0]
	imul	dword [esi+rmatrix_m+2*12]
	mov	ebx,eax
	mov	ecx,edx
	mov	eax,[ebp+4]
	imul	dword [esi+rmatrix_m+2*14]
	add	ebx,eax
	adc	ecx,edx
	mov	eax,[ebp+8]
	imul	dword [esi+rmatrix_m+2*16]
	add	ebx,eax
	adc	ecx,edx
	shrd	ebx,ecx,unitshr

	mov	          [edi+8],ebx
	pop	dword [edi+4]
	pop	dword [edi+0]
	ret


;北北北北 _calc_sftranslate(int count,vlist *dest,long tx,long ty,long tz) 北北北北
;entry:	count=number of vertices to sftranslate
;	dest=destination 3D list
;	matrix=rmatrix containing rotation / moving
; exit: -
;descr: Translates dest with matrix and and (starfield)
_calc_sftranslate:
	CBEG
	movpar	ax,0
	or	ax,ax
	jz	@@0
	ldspar	si,1 ;destination
	movpar	bx,3
	movpar	cx,5
	movpar	dx,7
	mov	bp,ax
@@1:
	mov	ax,[esi+vlist_x]
	add	ax,bx
	mov	[esi+vlist_x],ax

	mov	ax,[esi+vlist_y]
	add	ax,cx
	mov	[esi+vlist_y],ax

	mov	ax,[esi+vlist_z]
	add	ax,dx
	mov	[esi+vlist_z],ax

	add	si,vlist_size
	dec	bp
	jnz	@@1
@@0:	CEND


;北北北北 _calc_rotate(int count,vlist *dest,vlist *source,rmatrix *matrix) 北北北北
;entry:	count=number of vertices to rotate/move
;	dest=destination 3D list
;	source=source 3D list
;	matrix=rmatrix containing rotation / moving
; exit: -
;descr: Rotates (and moves) the given list
_calc_rotate:
	CBEG
	push	esi
	push	edi
	push	ebx

	movpar	ecx,0
	JCXZ_LARGE	@@0
	lespar	edi,1 ;destination
	ldspar	esi,3 ;matrix - dataseg not used in procedure, so DS can be used
	lfspar	ebp,2 ;source - NOTE: bp/parameter pointer destroyed!
@@1:	push	ecx

	movsx	eax,word [esi+rmatrix_m+2*0]
	imul	dword [ebp+vlist_x]
	mov	ebx,eax
	mov	ecx,edx
	movsx	eax,word [esi+rmatrix_m+2*2]
	imul	dword [ebp+vlist_y]
	add	ebx,eax
	adc	ecx,edx
	movsx	eax,word [esi+rmatrix_m+2*4]
	imul	dword [ebp+vlist_z]
	add	ebx,eax
	adc	ecx,edx
	shrd	ebx,ecx,unitshr
	add	ebx,[esi+rmatrix_x]
	mov	dword [edi+vlist_x],ebx
	
	movsx	eax,word [esi+rmatrix_m+2*6]
	imul	dword [ebp+vlist_x]
	mov	ebx,eax
	mov	ecx,edx
	movsx	eax,word [esi+rmatrix_m+2*8]
	imul	dword [ebp+vlist_y]
	add	ebx,eax
	adc	ecx,edx
	movsx	eax,word [esi+rmatrix_m+2*10]
	imul	dword [ebp+vlist_z]
	add	ebx,eax
	adc	ecx,edx
	shrd	ebx,ecx,unitshr
	add	ebx,[esi+rmatrix_y]
	mov	dword [edi+vlist_y],ebx
	
	movsx	eax,word [esi+rmatrix_m+2*12]
	imul	dword [ebp+vlist_x]
	mov	ebx,eax
	mov	ecx,edx
	movsx	eax,word [esi+rmatrix_m+2*14]
	imul	dword [ebp+vlist_y]
	add	ebx,eax
	adc	ecx,edx
	movsx	eax,word [esi+rmatrix_m+2*16]
	imul	dword [ebp+vlist_z]
	add	ebx,eax
	adc	ecx,edx
	shrd	ebx,ecx,unitshr
	add	ebx,[esi+rmatrix_z]
	mov	dword [edi+vlist_z],ebx

	mov	ax,word [ebp+vlist_normal]
	mov	word [edi+vlist_normal],ax
	
	;next point
	add	ebp,vlist_size
	add	edi,vlist_size
	pop	ecx
	LOOP_LARGE	@@1
@@0:
	pop	ebx
	pop	edi
	pop	esi
	CEND


;北北北北 _calc_singlez(int vertex,vlist *vertexlist,rmatrix *matrix) 北北北北
;entry:	vertex=number of vertex to process
;	vertexlist=list from which to pick the vertex
; exit: -
;descr: Rotates the single vertex and returns the resulting Z coordinate.
_calc_singlez:
	CBEG
	push	esi
	push	edi
	push	ebx

	ldspar	esi,2 ;matrix - dataseg not used in procedure, so DS can be used
	movpar	eax,0
	lfspar	ebp,1 ;source - NOTE: bp/parameter pointer destroyed!
	shl	ax,vlist_sizeshl
	add	bp,ax

	mov	eax,[esi+rmatrix_m+24]
	imul	dword [ebp+vlist_x]
	mov	ebx,eax
	mov	ecx,edx
	mov	eax,[esi+rmatrix_m+28]
	imul	dword [ebp+vlist_y]
	add	ebx,eax
	adc	ecx,edx
	mov	eax,[esi+rmatrix_m+32]
	imul	dword [ebp+vlist_z]
	add	ebx,eax
	adc	ecx,edx
	shrd	ebx,ecx,unitshr
	add	ebx,[esi+rmatrix_z]

	mov	eax,ebx
	;shr	ebx,16
	;mov	dx,bx

	pop	ebx
	pop	edi
	pop	esi
	CEND


;北北北北 _calc_nrotate(int count,nlist *dest,nlist *source,rmatrix *matrix) 北北北北
;entry:	count=number of normals to rotate
;	dest=destination 3Dnormal list
;	source=source 3Dnormal list
;	matrix=rmatrix containing rotation (moving part of rmatrix not used)
; exit: -
;descr: Rotates the given normal list
_calc_nrotate:
	CBEG
	push	esi
	push	edi
	push	ebx

	movpar	ecx,0
	JCXZ_LARGE	@@0
	lespar	edi,1 ;destination
	ldspar	esi,3 ;matrix - dataseg not used in procedure, so DS can be used
	lfspar	ebp,2 ;source - NOTE: bp/parameter pointer destroyed!
@@1:	push	ecx

	mov	ax,word [ebp+nlist_x]
	imul	word [esi+rmatrix_m+2*0]
	mov	bx,ax
	mov	cx,dx
	mov	ax,word [ebp+nlist_y]
	imul	word [esi+rmatrix_m+2*2]
	add	bx,ax
	adc	cx,dx
	mov	ax,word [ebp+nlist_z]
	imul	word [esi+rmatrix_m+2*4]
	add	bx,ax
	adc	cx,dx
	shrd	bx,cx,unitshr
	mov	word [edi+nlist_x],bx
	
	mov	ax,word [ebp+nlist_x]
	imul	word [esi+rmatrix_m+2*6]
	mov	bx,ax
	mov	cx,dx
	mov	ax,word [ebp+nlist_y]
	imul	word [esi+rmatrix_m+2*8]
	add	bx,ax
	adc	cx,dx
	mov	ax,word [ebp+nlist_z]
	imul	word [esi+rmatrix_m+2*10]
	add	bx,ax
	adc	cx,dx
	shrd	bx,cx,unitshr
	mov	word [edi+nlist_y],bx
	
	mov	ax,word [ebp+nlist_x]
	imul	word [esi+rmatrix_m+2*12]
	mov	bx,ax
	mov	cx,dx
	mov	ax,word [ebp+nlist_y]
	imul	word [esi+rmatrix_m+2*14]
	add	bx,ax
	adc	cx,dx
	mov	ax,word [ebp+nlist_z]
	imul	word [esi+rmatrix_m+2*16]
	add	bx,ax
	adc	cx,dx
	shrd	bx,cx,unitshr
	mov	word [edi+nlist_z],bx

	;next point
	add	ebp,nlist_size
	add	edi,nlist_size
	pop	ecx
	LOOP_LARGE	@@1
@@0:
	pop	ebx
	pop	edi
	pop	esi
	CEND


;北北北北 _calc_rotate16(int count,nlist *dest,nlist *source,rmatrix *matrix) 北北北北
;entry:	count=number of normals to rotate
;	dest=destination 3Dnormal list
;	source=source 3Dnormal list
;	matrix=rmatrix containing rotation (moving part of rmatrix not used)
; exit: -
;descr: Rotates the given normal list
_calc_rotate16:
	CBEG
	movpar	cx,0
	JCXZ_LARGE	@@0
	lespar	di,1 ;destination
	ldspar	si,5 ;matrix - dataseg not used in procedure, so DS can be used
	lfspar	bp,3 ;source - NOTE: bp/parameter pointer destroyed!
@@1:	push	cx

	mov	ax,word [ebp+vlist_x]
	imul	word [esi+rmatrix_m+2*0]
	mov	bx,ax
	mov	cx,dx
	mov	ax,word [ebp+vlist_y]
	imul	word [esi+rmatrix_m+2*2]
	add	bx,ax
	adc	cx,dx
	mov	ax,word [ebp+vlist_z]
	imul	word [esi+rmatrix_m+2*4]
	add	bx,ax
	adc	cx,dx
	shrd	bx,cx,unitshr
	mov	word [edi+vlist_x],bx
	
	mov	ax,word [ebp+vlist_x]
	imul	word [esi+rmatrix_m+2*6]
	mov	bx,ax
	mov	cx,dx
	mov	ax,word [ebp+vlist_y]
	imul	word [esi+rmatrix_m+2*8]
	add	bx,ax
	adc	cx,dx
	mov	ax,word [ebp+vlist_z]
	imul	word [esi+rmatrix_m+2*10]
	add	bx,ax
	adc	cx,dx
	shrd	bx,cx,unitshr
	mov	word [edi+vlist_y],bx
	
	mov	ax,word [ebp+vlist_x]
	imul	word [esi+rmatrix_m+2*12]
	mov	bx,ax
	mov	cx,dx
	mov	ax,word [ebp+vlist_y]
	imul	word [esi+rmatrix_m+2*14]
	add	bx,ax
	adc	cx,dx
	mov	ax,word [ebp+vlist_z]
	imul	word [esi+rmatrix_m+2*16]
	add	bx,ax
	adc	cx,dx
	shrd	bx,cx,unitshr
	mov	word [edi+vlist_z],bx

	;next point
	add	bp,vlist_size
	add	di,vlist_size
	pop	cx
	LOOP_LARGE	@@1
@@0:	CEND


;北北北北 _calc_project(int count,pvlist *dest,vlist *source) 北北北北
;entry:	count=number of vertices to project
;	dest=destination projected list
;	source=source 3D list
;	(_proj* variables in data segment define the projection)
; exit: logical and of visibility flags for all vertices (!=0 == object invis.)
;descr: Projects the given list = does perspective transformation
_calc_project:
	CBEG
	push	esi
	push	edi
	push	ebx

	lfspar	esi,2
	lespar	edi,1
	mov	eax,0ffffh
	movpar	ecx,0
	JCXZ_LARGE	@@0
@@1:	push	ecx
	push	eax
	
	mov	ecx,[esi+vlist_x]
	mov	eax,[esi+vlist_y]
	mov	ebx,[esi+vlist_z]
	
	xor	ebp,ebp
	cmp	ebx,[_projclipz+CLIPMIN]
	jge	@@21
	or	ebp,VF_NEAR
	mov	ebx,[_projclipz+CLIPMIN]
	jmp	@@22
@@21:	cmp	ebx,[_projclipz+CLIPMAX]
	jle	@@22
	or	ebp,VF_FAR
@@22:	;
	imul	dword [_projmuly]
	idiv	ebx
	add	eax,[_projaddy]
	cmp	eax,[_projclipy+CLIPMAX]
	jng	@@41
	or	ebp,VF_DOWN
@@41:	cmp	eax,[_projclipy+CLIPMIN]
	jnl	@@42
	or	ebp,VF_UP
@@42:	mov	[edi+pvlist_y],ax ;store Y
	;
	mov	eax,[_projmulx]
	imul	ecx
	idiv	ebx
	add	eax,[_projaddx]
	cmp	eax,[_projclipx+CLIPMAX]
	jng	@@43
	or	ebp,VF_RIGHT
@@43:	cmp	eax,[_projclipx+CLIPMIN]
	jnl	@@44
	or	ebp,VF_LEFT
@@44:	mov	[edi+pvlist_x],ax ;store X

@@5:	mov	[edi+pvlist_vf],bp ;store visiblity flags
	
	;next point
	add	esi,vlist_size
	add	edi,pvlist_size

	pop	eax	
	pop	ecx
	and	eax,ebp
	LOOP_LARGE	@@1
@@0:
	pop	ebx
	pop	edi
	pop	esi
	CEND

	
;北北北北 _calc_project16(int count,pvlist *dest,vlist *source) 北北北北
;entry:	count=number of vertices to project
;	dest=destination projected list
;	source=source 3D list
;	(_proj* variables in data segment define the projection)
; exit: logical and of visibility flags for all vertices (!=0 == object invis.)
;descr: Projects the given list = does perspective transformation
_calc_project16:
	CBEG
	push	esi
	push	edi
	push	ebx

	lfspar	esi,2
	lespar	edi,1
	mov	eax,0ffffh
	movpar	ecx,0
	JCXZ_LARGE	@@0
@@1:	push	ecx
	push	eax
	
	movsx	ecx,word [esi+vlist_x]
	movsx	eax,word [esi+vlist_y]
	movsx	ebx,word [esi+vlist_z]
	
	xor	ebp,ebp
	cmp	ebx,[_projclipz+CLIPMIN]
	jge	@@21
	or	ebp,VF_NEAR
	mov	ebx,[_projclipz+CLIPMIN]
	jmp	@@22
@@21:	cmp	ebx,[_projclipz+CLIPMAX]
	jle	@@22
	or	ebp,VF_FAR
@@22:	;
	imul	dword [_projmuly]
	idiv	ebx
	add	eax,[_projaddy]
	cmp	eax,[_projclipy+CLIPMAX]
	jng	@@41
	or	ebp,VF_DOWN
@@41:	cmp	eax,[_projclipy+CLIPMIN]
	jnl	@@42
	or	ebp,VF_UP
@@42:	mov	[edi+pvlist_y],ax ;store Y
	;
	mov	eax,[_projmulx]
	imul	ecx
	idiv	ebx
	add	eax,[_projaddx]
	cmp	eax,[_projclipx+CLIPMAX]
	jng	@@43
	or	ebp,VF_RIGHT
@@43:	cmp	eax,[_projclipx+CLIPMIN]
	jnl	@@44
	or	ebp,VF_LEFT
@@44:	mov	[edi+pvlist_x],ax ;store X

@@5:	mov	[edi+pvlist_vf],bp ;store visiblity flags
	
	;next point
	add	esi,vlist_size
	add	edi,pvlist_size

	pop	eax	
	pop	ecx
	and	eax,ebp
	LOOP_LARGE	@@1
@@0:
	pop	ebx
	pop	edi
	pop	esi
	CEND
