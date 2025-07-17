;included to koe.asm

;.386

;include polyega.asm

extern _dis_waitb
extern _textpic

%define STARS	512
%define STARS2	1024

section .data

starvram  dw	0a000h
emmhandle dw	0
emmseg	dw	0
emmpage4 dw	0
starlimit dw	0
startxtopen dw	0
startxtclose dw	0
startxtp0 dw	0
starframe dw	0
starpalfade db	0,0
_nostar1 dw	200
_nostar2 dw	199

rows1	times 200 dw	0
rows	times 400 dw	0

star	times STARS2 dw	 0,0,0,0

muldivx	times 256 dw	0
muldivy	times 256 dw	0

seed	dd	0 ;12345678h

section .code

random:
	push	edx
	mov	eax,0343fdh
	mul	dword [seed]
	add	eax,269ec3h
	mov	dword [seed],eax
	mov	ax,dx
	pop	edx
	ret

setborder:
	push	ax
	mov	dx,3dah
	in	al,dx
	mov	dx,3c0h
	mov	al,11h+20h
	out	dx,al
	pop	ax
	out	dx,al
	ret	

global init_stars
init_stars:
	mov	ax,13
	int	10h
	
	mov	dx,3dah
	in	al,dx
	mov	dx,3c0h
	xor	al,al
	%rep 16
	out	dx,al
	out	dx,al
	inc	al
	%endrep
	mov	al,20h
	out	dx,al
	
	mov	dx,3d4h
	mov	al,9
	out	dx,al
	inc	dx
	in	al,dx
	and	al,127
	out	dx,al
	
	mov	ax,0a000h
	mov	es,ax
	xor	di,di
	mov	cx,32768
	xor	ax,ax
	rep	stosw
	
	mov	ah,43h
	mov	bx,32*2
	int	67h
	or	ah,ah
	jz	@@1
	mov	ax,4c00h
	int	21h
@@1:	mov	[emmhandle],dx
	
	mov	ah,41h
	int	67h
	mov	[emmseg],bx
	
	call	clearsbu

	mov	cx,200
	mov	ax,0
	mov	dx,320/8
	mov	bx,rows1
@@4:	mov	[ebx],ax
	add	ax,dx
	add	bx,2
	loop	@@4
	
	mov	cx,400
	mov	ax,0
	mov	dx,320/8
	mov	bx,rows
@@4b:	mov	[ebx],ax
	add	ax,dx
	add	bx,2
	loop	@@4b
	
	mov	ax,cs
	mov	es,ax
	
	mov	di,star
	mov	cx,STARS2
@@3:	mov	al,cl
	dec	al
	xor	ah,ah
	stosw
	call	random
	and	ax,1023
	sub	ax,512
	stosw
	call	random
	and	ax,1023
	sub	ax,512
	stosw
	xor	ax,ax
	stosw
	loop	@@3
	
	mov	di,muldivy
	mov	cx,256
	mov	bp,150
@@2b:	mov	dx,108
	xor	ax,ax
	div	bp
	shr	ax,1
	stosw
	add	bp,4
	loop	@@2b

	mov	di,muldivx
	mov	cx,256
	mov	bp,150
@@2c:	mov	dx,144
	xor	ax,ax
	div	bp
	shr	ax,1
	stosw
	add	bp,4
	loop	@@2c

	mov	word [starlimit],STARS
	mov	word [starpalfade],0
	
	mov	word [startxtopen],-9999
	mov	word [startxtclose],10000

	mov	cx,100
@@sa:	push	cx
	call	starfetch0
	call	staradd
	pop	cx
	loop	@@sa
	ret

global deinit_stars
deinit_stars:
	mov	ah,45h
	mov	dx,[emmhandle]
	int	67h
	ret

fetch4ax:
	shl	ax,1
	mov	bx,ax
	push	ax
	mov	ax,4400h
	shr	bx,2
	mov	dx,[emmhandle]
	int	67h
	pop	ax
	and	ax,3
	shl	ax,12-4
	add	ax,[emmseg]
	ret

fetch4ax2:
	shl	ax,1
	mov	bx,ax
	push	ax
	mov	ax,4401h
	shr	bx,2
	mov	dx,[emmhandle]
	int	67h
	pop	ax
	and	ax,3
	shl	ax,12-4
	add	ax,[emmseg]
	add	ax,400h
	ret

fetch4ax3:
	shl	ax,1
	mov	bx,ax
	push	ax
	mov	ax,4402h
	shr	bx,2
	mov	dx,[emmhandle]
	int	67h
	pop	ax
	and	ax,3
	shl	ax,12-4
	add	ax,[emmseg]
	add	ax,800h
	ret

clearsbu:
	mov	cx,128
	mov	ax,0
@@1:	push	cx
	push	ax
	call	fetch4ax
	mov	es,ax
	mov	cx,4096/4*2
	xor	eax,eax
	xor	di,di
	rep	stosd
	pop	ax
	pop	cx
	inc	ax
	loop	@@1
	ret

starfetch0:
	mov	ax,[emmpage4]
	inc	ax
	and	ax,63
	mov	[emmpage4],ax
	call	fetch4ax
	mov	es,ax
	ret

starfetch1:
	mov	ax,[emmpage4]
	add	ax,17
	and	ax,63
	call	fetch4ax2
	mov	fs,ax
	ret

starfetch2:
	mov	ax,[emmpage4]
	add	ax,43
	and	ax,63
	call	fetch4ax3
	mov	gs,ax
	ret

staradd:
	mov	ax,cs
	mov	ds,ax
	mov	ax,[starlimit]
	or	ax,ax
	jz	@@11
	dec	ax
	mov	[starlimit],ax
@@11:	mov	bp,STARS
	mov	si,star
@@1:	movzx	bx,[esi]
	sub	bl,2
	mov	[esi],bl
	jc	@@4
	cmp	bp,[starlimit]
	jb	@@2
	shl	bx,1
	mov	ax,[esi+4]
	imul	word [muldivy+ebx]
	shld	dx,ax,2
	add	dx,100
	cmp	dx,99
	ja	@@2
	mov	cx,dx
	mov	ax,[esi+2]
	imul	word [muldivx+ebx]
	mov	bx,cx
	shld	dx,ax,2
	add	dx,160
	cmp	dx,319
	ja	@@2
	mov	cl,dl
	and	cl,7
	shr	dx,3
	shl	bx,1
	mov	bx,[rows1+ebx]
	add	bx,dx
	mov	ch,80h
	shr	ch,cl
	mov	cl,[esi]
	cmp	cl,180
	jb	@@sc1
	or	byte [ebx],ch
	jmp	@@2
@@sc1:	cmp	cl,110
	jb	@@sc2
	or	byte [ebx+4096],ch
	jmp	@@2
@@sc2:	or	byte [ebx],ch
	or	byte [ebx+4096],ch
@@2:	add	si,8
	dec	bp
	jnz	@@1
	ret
@@4:	call	random
	and	ax,1023
	sub	ax,512
	mov	[esi+2],ax
	call	random
	and	ax,1023
	sub	ax,512
	mov	[esi+4],ax
	jmp	@@2

staradd2:
	call	starfetch1
	mov	ax,cs
	mov	ds,ax
	mov	ax,[starlimit]
	or	ax,ax
	jz	@@11
	sub	ax,4
	mov	[starlimit],ax
@@11:	mov	bp,STARS2
	mov	si,star
@@1:	movzx	bx,[esi]
	sub	bl,2
	mov	[esi],bl
	jc	@@4
	cmp	bp,[starlimit]
	jb	@@2
	shl	bx,1
	mov	ax,[esi+4]
	imul	word [muldivy+ebx]
	shld	dx,ax,2
	add	dx,100
	cmp	dx,99
	ja	@@2
	mov	cx,dx
	mov	ax,[esi+2]
	imul	word [muldivx+ebx]
	mov	bx,cx
	shld	dx,ax,2
	add	dx,160
	cmp	dx,319
	ja	@@2
	mov	cl,dl
	and	cl,7
	shr	dx,3
	shl	bx,1
	mov	bx,[rows1+ebx]
	add	bx,dx
	mov	ch,80h
	shr	ch,cl
	mov	cl,[esi]
	cmp	cl,180
	jb	@@sc1
	or	byte [ebx],ch
	or	byte [ebx],ch ;fs:
	jmp	@@2
@@sc1:	cmp	cl,110
	jb	@@sc2
	or	byte [ebx+4096],ch
	or	byte [ebx+4096],ch ; fs
	jmp	@@2
@@sc2:	or	byte [ebx],ch
	or	byte [ebx+4096],ch
	or	byte [ebx],ch ;fs
	or	byte [ebx+4096],ch ;fs
@@2:	add	si,8
	dec	bp
	jnz	@@1
	ret
@@4:	call	random
	and	ax,1023
	sub	ax,512
	mov	[esi+2],ax
	call	random
	and	ax,1023
	sub	ax,512
	mov	[esi+4],ax
	jmp	@@2

risetext:
	mov	ax,[startxtopen]
	cmp	ax,99
	jge	@@12
	inc	ax
	mov	[startxtopen],ax
@@12:	mov	dx,[startxtclose]
	cmp	dx,0
	jle	@@21
	dec	dx
	mov	[startxtclose],dx
@@21:	cmp	dx,ax
	jge	@@22
	mov	ax,dx
@@22:	;ax=startxtuse

	cmp	ax,0
	jg	@@tcc
	jmp	@@tc0
@@tcc:	cmp	ax,1
	jg	@@tnz
	mov	ax,2
@@tnz:	push	ax
	mov	di,150
	sub	di,ax
	mov	[_nostar2],ax
	mov	ax,80
	mul	di
	mov	di,ax
	mov	[_nostar1],di
	mov	ax,_textpic
	mov	ds,ax
	mov	si,040h
	add	si,[startxtp0]
	pop	cx
	dec	cx

	sub	di,40	
	mov	dx,3c4h
	mov	ax,0f02h
	out	dx,ax
	xor	eax,eax
	%assign zzz 0
	%rep	40/4
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	add	di,80
	dec	cx
	jz	@@tc0c
	
	mov	dx,3c4h
	mov	ax,0f02h
	out	dx,ax
	mov	eax,0
	%assign zzz 0
	%rep	40/4
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	add	di,80
	dec	cx
	jz	@@tc0
	dec	cx
	jz	@@tc0b

	mov	dx,3ceh
	mov	ax,0400h
	out	dx,ax
	mov	ax,01h+400h+800h
	out	dx,ax

@@tc1:	mov	dx,3c4h
	mov	ax,0102h+400h+800h
	out	dx,ax
	%assign zzz 0
	%rep	40/4
	mov	eax,[esi+zzz]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	add	si,40
	mov	dx,3c4h
	mov	ax,0202h+400h+800h
	out	dx,ax
	%assign zzz 0
	%rep	40/4
	mov	eax,[esi+zzz]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	add	si,40
	add	di,80
	dec	cx
	jz	@@tc0b
	jmp	@@tc1
	
@@tc0b:	mov	dx,3ceh
	mov	ax,0001h
	out	dx,ax

	mov	dx,3c4h
	mov	ax,0f02h
	out	dx,ax
	mov	eax,0
	%assign zzz 0
	%rep	40/4
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	add	di,80

	dec	di
	mov	[_nostar2],di
@@tc0:	ret
@@tc0c:	mov	dx,3c4h
	mov	ax,0f02h
	out	dx,ax
	xor	eax,eax
	%assign zzz 0
	%rep	80/4
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	ret

global do_stars
do_stars:
@@aga:	mov	al,0
	;call	setborder

	mov	dx,3d4h
	mov	ax,[starvram]
	cmp	ax,0a000h
	je	@@sw1
	mov	word [starvram],0a000h
	mov	ax,400ch
	jmp	@@sw0
@@sw1:	mov	word [starvram],0a400h
	mov	ax,000ch
@@sw0:	out	dx,ax
	call	_dis_waitb
	
	mov	al,1
	;call	setborder
	
	cmp	word [starpalfade],32
	ja	@@p1
	
	mov	bl,[starpalfade]
	inc	bl
	mov	[starpalfade],bl
	shl	bl,3
	jnc	@@p2
	mov	bl,255
@@p2:
	mov	dx,3c8h
	xor	al,al
	out	dx,al
	inc	dx
	
	mov	al,0
	out	dx,al
	mov	al,0
	out	dx,al
	mov	al,0
	out	dx,al
	
	mov	al,25*70/100
	mul	bl
	mov	al,ah
	out	dx,al
	mov	al,31*70/100
	mul	bl
	mov	al,ah
	out	dx,al
	mov	al,38*70/100
	mul	bl
	mov	al,ah
	out	dx,al
	
	mov	al,45*56/100
	mul	bl
	mov	al,ah
	out	dx,al
	mov	al,58*56/100
	mul	bl
	mov	al,ah
	out	dx,al
	mov	al,69*56/100
	mul	bl
	mov	al,ah
	out	dx,al

	mov	al,67*64/100
	mul	bl
	mov	al,ah
	out	dx,al
	mov	al,84*64/100
	mul	bl
	mov	al,ah
	out	dx,al
	mov	al,99*64/100
	mul	bl
	mov	al,ah
	out	dx,al

	;-----

	mov	al,0
	out	dx,al
	mov	al,0
	out	dx,al
	mov	al,0
	out	dx,al

	mov	al,10
	out	dx,al
	mov	al,20
	out	dx,al
	mov	al,35
	out	dx,al

	mov	al,20
	out	dx,al
	mov	al,30
	out	dx,al
	mov	al,45
	out	dx,al

	mov	al,30
	out	dx,al
	mov	al,40
	out	dx,al
	mov	al,60
	out	dx,al
@@p1:	
	mov	ax,[starframe]
	inc	ax
	mov	[starframe],ax
	cmp	ax,1200
	jne	@@st1
	mov	word [startxtp0],80
	mov	word [startxtopen],-256
	mov	word [startxtclose],1500
@@st1:	cmp	ax,3200
	jne	@@st2
	mov	word [startxtp0],101*80
	mov	word [startxtopen],-256
	mov	word [startxtclose],1500
@@st2:	cmp	ax,1500
	jne	@@st3
	mov	word [starlimit],STARS2
@@st3:
	call	risetext

	call	starfetch0
	cmp	word [starframe],1200
	ja	@@stz
	cmp	word [starframe],900
	ja	@@stz0
	call	staradd
	jmp	@@stz0
@@stz:	call	staradd2
	;mov	al,1
	;call	setborder
@@stz0:
	mov	ax,es
	mov	ds,ax
	
	mov	ax,[starvram]
	mov	es,ax
	xor	di,di
	mov	dx,3c4h
	mov	ax,0102h
	out	dx,ax
	mov	si,0
	mov	cx,100
@@3:
	%assign zzz 0
;	cmp	di,cs:_nostar1
;	jl	@@3g
;	cmp	di,cs:_nostar2
;	jg	@@3g
;	jmp	@@3s
@@3g:
	%rep	40/4
	mov	eax,[esi+zzz]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
@@3s:	add	si,40
	add	di,80
	loop	@@3
	xor	di,di
	mov	si,4096
	mov	dx,3c4h
	mov	ax,0202h
	out	dx,ax
	mov	cx,100
@@7:
	%assign zzz 0
;	cmp	di,cs:_nostar1
;	jl	@@7g
;	cmp	di,cs:_nostar2
;	jg	@@7g
;	jmp	@@7s
@@7g:
	%rep	40/4
	mov	eax,[esi+zzz]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
@@7s:	add	si,40
	add	di,80
	loop	@@7

	mov	ax,[emmpage4]
	add	ax,32
	and	ax,63
	call	fetch4ax
	mov	ds,ax
	mov	di,200*40
	mov	si,99*40
	mov	dx,3c4h
	mov	ax,0102h
	out	dx,ax
	mov	cx,100
@@5:
	%assign zzz 0
;	cmp	di,cs:_nostar1
;	jl	@@5g
;	cmp	di,cs:_nostar2
;	jg	@@5g
;	jmp	@@5s
@@5g:
	%rep	40/4
	mov	eax,[esi+zzz]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
@@5s:	sub	si,40
	add	di,80
	loop	@@5
	mov	di,200*40
	mov	si,99*40+4096
	mov	dx,3c4h
	mov	ax,0202h
	out	dx,ax
	mov	cx,100
@@8:
	%assign zzz 0
;	cmp	di,cs:_nostar1
;	jl	@@8g
;	cmp	di,cs:_nostar2
;	jg	@@8g
;	jmp	@@8s
@@8g:
	%rep	40/4
	mov	eax,[esi+zzz]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
@@8s:	sub	si,40
	add	di,80
	loop	@@8
	
	mov	bx,2
	int	0fch
	or	ax,ax
	jz	@@aga
	ret
	
	mov	ax,0a000h
	mov	ds,ax
	xor	si,si
	mov	cx,40*400
	mov	dx,0
@@1:	lodsb
	shl	al,1
	adc	dx,0
	shl	al,1
	adc	dx,0
	shl	al,1
	adc	dx,0
	shl	al,1
	adc	dx,0
	shl	al,1
	adc	dx,0
	shl	al,1
	adc	dx,0
	shl	al,1
	adc	dx,0
	shl	al,1
	adc	dx,0
	loop	@@1
	int	3
	ret
