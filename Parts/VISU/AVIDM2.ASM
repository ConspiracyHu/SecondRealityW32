;/****************************************************************************
;** MODULE:	avidm2.asm
;** AUTHOR:	Sami Tammilehto / Fennosoftec OY
;** DOCUMENT:	?
;** VERSION:	1.0
;** REFERENCE:	-
;** REVISED BY:	-
;*****************************************************************************
;**
;** Video driver for 640x400x256 (tweak)
;** included to avid.asm
;**
;****************************************************************************/

;======== public routines ========

section .code

m2_init:
	mov	word [_vramseg],0a000h
	call	tweak640x400
	mov	dx,640/4
	mov	cx,400
	call	setrows
	mov	word [vr+PSET],m2_pset
	mov	word [vr+CLEAR],m2_clear
	mov	word [vr+SWITCH],m2_switch
	mov	word [vr+WAITB],m2_waitb
	mov	dword [_projclipx+CLIPMIN],0
	mov	dword [_projclipx+CLIPMAX],639
	mov	dword [_projclipy+CLIPMIN],0
	mov	dword [_projclipy+CLIPMAX],399
	mov	dword [_projclipz+CLIPMIN],512*1
	mov	dword [_projclipz+CLIPMAX],1000000000
	mov	dword [_projmulx],480*1
	mov	dword [_projmuly],400*1
	mov	dword [_projaddx],320
	mov	dword [_projaddy],200
	mov	word [_projaspect],256
	ret


;======== public routines called through the vr[] pointers ========

;dx=X, bx=Y, ah=color
m2_pset:
	;requires ES=vram, OUT 3C4,2  [set by vidstart]
	shl	bx,1
	mov	bx,[_rows+ebx]
	mov	cx,3
	and	cx,dx
	sar	dx,2
	add	bx,dx
	mov	al,1
	shl	al,cl
	mov	dx,3c5h
	out	dx,al
	mov	[ebx],ah
	ret


m2_waitb:
	mov	dx,3dah
@@1:	in	al,dx
	test	al,8
	jnz	@@1
@@2:	in	al,dx
	test	al,8
	jz	@@2
	ret

section .data

;ALIGN 2
tmptest	dw	0

section .code

m2_clear: ;clear current page
	inc	word [tmptest]
	push	di
	cmp	ax,1
	je	@@sky
	mov	dx,3c4h
	mov	ax,0f02h
	out	dx,ax
	mov	cx,640*400/4/4
	xor	di,di
	xor	eax,eax
	rep	stosd
	pop	di
	ret
@@sky:	mov	dx,3c4h
	mov	ax,0f02h
	out	dx,ax
	mov	cx,400
	xor	di,di
@@1:	mov	al,[esi]
	cmp	al,1
	je	@@colr
	cmp	al,2
	je	@@bitm
	cmp	al,4
	je	@@depth
	jmp	@@noth
	
@@depth:
	push	si
	push	ds
	mov	dx,3c4h
	mov	ax,0f02h
	out	dx,ax
	mov	ax,[esi+2]
	xor	dx,dx
	mov	bx,320
	div	bx
	lds	ax,[esi+4]
	mov	si,ax
	add	si,dx
	%assign zzz 0
	%rep	640/4/4
	mov	eax,[esi+zzz]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	pop	ds
	pop	si
	jmp	@@noth

@@colr:	mov	al,[esi+2]
	mov	ah,al
	mov	bx,ax
	shl	eax,16
	mov	ax,bx
	%assign zzz 0
	%rep	640/4/4
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	jmp	@@noth

@@bitm:	push	cx
	push	ds
	push	si
@@bc:	lds	ax,[esi+4]
	mov	si,ax
	mov	ax,[tmptest]
	mov	dx,ax
	shr	dx,2
	add	si,dx
	and	ax,3
	shl	ax,11
	add	si,ax
	mov	cx,4
	mov	ax,0102h
@@b1:	push	ax
	mov	dx,3c4h
	out	dx,ax
	%assign zzz 0
	%rep	640/4/4
	mov	eax,[esi+zzz]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	add	si,2048
	cmp	si,8192
	jb	@@b3
	sub	si,8192-1
@@b3:	pop	ax
	shl	ah,1
	LOOP_LARGE	@@b1
	pop	si
	pop	ds
	pop	cx
	mov	dx,3c4h
	mov	ax,0f02h
	out	dx,ax
	jmp	@@noth

@@noth:	add	di,640/4
	add	si,8
	LOOP_LARGE	@@1
	pop	di
	ret

section .data

pagep	dw	0
wpage	dw	1,2,3
spage	dw	3,1,2

section .code

m2_switch:
	mov	ax,0a000h
	mov	[_vramseg],ax
	mov	bx,[pagep]
	inc	bx
	cmp	bx,3
	jb	sws1
	xor	bx,bx
sws1:	mov	[pagep],bx
	shl	bx,1
	mov	dx,3d4h
	mov	al,33h
	mov	ah,byte [spage+ebx]
	out	dx,ax ;spage
	;set wpage
	mov	al,byte [wpage+ebx]
	mov	ah,al
	rol	ah,4
	or	al,ah
	mov	dx,3cdh
	out	dx,al
	;page low offset
	mov	dx,3d4h
	mov	ax,000dh
	out	dx,ax
	mov	ax,000ch
	out	dx,ax
	ret


;======== internal routines ========

;sets up 640x400x256 tweak
tweak640x400:
	mov     ax,002fh
	int     10h
	mov	dx,3c8h
	mov	al,0
	out	dx,al
	inc	dx
	mov	cx,768
@@1:	out	dx,al
	loop	@@1
	mov     dx,3c4h
	mov     al,4
	out     dx,al
	inc     dx
	in      al,dx
	and     al,~08h      
	or      al,04h          
	out     dx,al
	mov     dx,3ceh
	mov     al,5
	out     dx,al
	inc     dx
	in      al,dx
	and     al,~10h      
	out     dx,al
	dec     dx
	mov     al,6
	out     dx,al
	inc     dx
	in      al,dx
	and     al,~02h      
	out     dx,al
	mov     dx,3d4h
	mov     al,9
	inc     dx
	and     al,~5fh 
	or      al,1
	dec     dx
	mov     al,14h
	out     dx,al
	inc     dx
	in      al,dx
	and     al,~40h
	out     dx,al
	dec     dx
	mov     al,17h
	out     dx,al
	inc     dx
	in      al,dx
	or      al,40h 
	out     dx,al
	ret

