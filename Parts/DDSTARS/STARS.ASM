;included to koe.asm

;.386

;include polyega.asm

extern _dis_exit
extern _dis_waitb
extern _textpic
extern _shim_vram
extern _demo_blit
extern _shim_outp_naked

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

%define PLANE_SIZE (80*400)
_ddstars_planar times PLANE_SIZE*4 db 0

section .bss

%define PAGESIZE (16*1024)

emmdata resb 32*2*PAGESIZE
curemmptr0 resd 1
curemmptr1 resd 1
curemmptr2 resd 1

section .code

_resolve_planar:
  mov edi, _shim_vram
  mov esi, _ddstars_planar
  mov edx, 320
  mov bl, 0x80
  shr bl, cl
  mov ecx, 320*400
  resolve_byte:
    xor al, al
    test [esi+PLANE_SIZE*0], bl
    jz nah1
      or al, 1
    nah1:
    test [esi+PLANE_SIZE*1], bl
    jz nah2
      or al, 2
    nah2:
    test [esi+PLANE_SIZE*2], bl
    jz nah3
      or al, 4
    nah3:
    test [esi+PLANE_SIZE*3], bl
    jz nah4
      or al, 8
    nah4:
    stosb
    ror bl,1
    test bl,0x80
    jz nextbyte
      inc esi
    nextbyte:
    ;dec edx
    ;cmp edx, 0
    ;jne nextrow
    ;  add esi, 40
    ;  mov edx, 320
    ;nextrow:
  loop resolve_byte
  ret

random:
	push	edx
	mov	eax,0343fdh
	mul	dword [seed]
	add	eax,269ec3h
	mov	dword [seed],eax
	mov	ax,dx
	pop	edx
	ret

;setborder:
;	push	ax
;	mov	dx,3dah
;	in	al,dx
;	mov	dx,3c0h
;	mov	al,11h+20h
;	out	dx,al
;	pop	ax
;	out	dx,al
;	ret	

global init_stars
init_stars:
	;mov	ax,13
	;int	10h
	
	;mov	dx,3dah
	;in	al,dx
	;mov	dx,3c0h
	;xor	al,al
	;%rep 16
	;out	dx,al
	;out	dx,al
	;inc	al
	;%endrep
	;mov	al,20h
	;out	dx,al
	;
	;mov	dx,3d4h
	;mov	al,9
	;out	dx,al
	;inc	dx
	;in	al,dx
	;and	al,127
	;out	dx,al
	
	;mov	ax,0a000h
	;mov	es,ax
	mov	edi, _shim_vram
	mov	cx,32768
	xor	ax,ax
	rep	stosw
	
;	mov	ah,43h
;	mov	bx,32*2
;	int	67h
;	or	ah,ah
;	jz	@@1
;	mov	ax,4c00h
;	int	21h
;@@1:	mov	[emmhandle],dx
;	
;	mov	ah,41h
;	int	67h
;	mov	[emmseg],bx
	
	call	clearsbu

	mov	ecx,200
	mov	eax,0
	mov	edx,320/8
	mov	ebx,rows1
@@4:	mov	[ebx],ax
	add	eax,edx
	add	ebx,2
	loop	@@4
	
	mov	ecx,400
	mov	eax,0
	mov	edx,320/8
	mov	ebx,rows
@@4b:	mov	[ebx],ax
	add	eax,edx
	add	ebx,2
	loop	@@4b
	
	;mov	ax,cs
	;mov	es,ax
	
	mov	edi,star
	mov	ecx,STARS2
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
	
	mov	edi,muldivy
	mov	ecx,256
	mov	ebp,150
@@2b:	mov	edx,108
	xor	eax,eax
	div	ebp
	shr	eax,1
	stosw
	add	ebp,4
	loop	@@2b

	mov	edi,muldivx
	mov	ecx,256
	mov	ebp,150
@@2c:	mov	edx,144
	xor	eax,eax
	div	ebp
	shr	eax,1
	stosw
	add	ebp,4
	loop	@@2c

	mov	word [starlimit],STARS
	mov	word [starpalfade],0
	
	mov	word [startxtopen],-9999
	mov	word [startxtclose],10000

	mov	ecx,100
@@sa:	push	ecx
	call	starfetch0
	call	staradd
	pop	ecx
	loop	@@sa
	ret

global deinit_stars
deinit_stars:
;	mov	ah,45h
;	mov	dx,[emmhandle]
;	int	67h
	ret

fetch4ax:
	;shl	ax,1
	;mov	bx,ax
	;push	ax
	;mov	ax,4400h
	;shr	bx,2
	;mov	dx,[emmhandle]
	;int	67h
	;pop	ax
	;and	ax,3
	;shl	ax,12-4
	;add	ax,[emmseg]
	movzx	eax, ax
	shl	eax, 16
	;add	eax, 0
	mov	eax, emmdata
	ret

fetch4ax2:
	;shl	ax,1
	;mov	bx,ax
	;push	ax
	;mov	ax,4401h
	;shr	bx,2
	;mov	dx,[emmhandle]
	;int	67h
	;pop	ax
	;and	ax,3
	;shl	ax,12-4
	;add	ax,[emmseg]
	;add	ax,400h
	movzx	eax, ax
	shl	eax, 16
	add	eax, 0x4000
	mov	eax, emmdata
	ret

fetch4ax3:
	;shl	ax,1
	;mov	bx,ax
	;push	ax
	;mov	ax,4402h
	;shr	bx,2
	;mov	dx,[emmhandle]
	;int	67h
	;pop	ax
	;and	ax,3
	;shl	ax,12-4
	;add	ax,[emmseg]
	;add	ax,800h
	movzx	eax, ax
	shl	eax, 16
	add	eax, 0x8000
	mov	eax, emmdata
	ret

clearsbu:
	mov	ecx,128
	mov	eax,0
@@1:	push	ecx
	push	eax
	call	fetch4ax
	;mov	es,ax
	mov	edi, eax
	mov	cx,4096/4*2
	xor	eax,eax
	rep	stosd
	pop	eax
	pop	ecx
	inc	eax
	loop	@@1
	ret

starfetch0:
	movzx	eax,word [emmpage4]
	inc	eax
	and	eax,63
	mov	[emmpage4],ax
	call	fetch4ax
	mov	[curemmptr0], eax
	;mov	es,ax
	ret

starfetch1:
	movzx	eax,word [emmpage4]
	add	ax,17
	and	ax,63
	call	fetch4ax2
	mov	[curemmptr1], eax
	;mov	fs,ax
	ret

starfetch2:
	movzx	eax,word [emmpage4]
	add	eax,43
	and	eax,63
	mov	[curemmptr2], eax
	call	fetch4ax3
	;mov	gs,ax
	ret

staradd:
	;mov	ax,cs
	;mov	ds,ax
	movzx	eax, word [starlimit]
	or	ax,ax
	jz	@@11
	dec	eax
	mov	[starlimit],ax
@@11:	mov	ebp,STARS
	mov	esi,star
@@1:	movzx	ebx, byte [esi]
	sub	bl,2
	mov	[esi],bl
	jc	@@4
	cmp	bp,[starlimit]
	jb	@@2
	shl	ebx,1
	movzx	eax, word [esi+4]
	imul	word [muldivy+ebx]
	movsx   eax, ax
	movsx   edx, dx
	shld	edx,eax,2
	add	edx,100
	cmp	edx,99
	ja	@@2
	mov	ecx,edx
	movzx	eax,word [esi+2]
	imul	word [muldivx+ebx]
	movsx   eax, ax
	movsx   edx, dx
	mov	ebx,ecx
	shld	edx,eax,2
	add	edx,160
	cmp	edx,319
	ja	@@2
	mov	cl,dl
	and	cl,7
	shr	edx,3
	shl	ebx,1
	movzx	ebx, word [rows1+ebx]
	add	ebx,edx
	mov	ch,80h
	shr	ch,cl
	mov	cl,[esi]
	cmp	cl,180
	jb	@@sc1
	mov	eax, [curemmptr0]
	or	byte [eax+ebx],ch
	jmp	@@2
@@sc1:	cmp	cl,110
	jb	@@sc2
	mov	eax, [curemmptr0]
	or	byte [eax+ebx+4096],ch
	jmp	@@2
@@sc2:
	mov	eax, [curemmptr0]
	or	byte [eax+ebx],ch
	or	byte [eax+ebx+4096],ch
@@2:	add	esi,8
	dec	ebp
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
	;mov	ax,cs
	;mov	ds,ax
	movzx	eax, word [starlimit]
	or	ax,ax
	jz	@@11
	sub	eax,4
	mov	[starlimit],ax
@@11:	mov	ebp,STARS2
	mov	esi,star
@@1:	movzx	ebx, byte [esi]
	sub	bl,2
	mov	[esi],bl
	jc	@@4
	cmp	bp,[starlimit]
	jb	@@2
	shl	ebx,1
	movzx	eax, word [esi+4]
	imul	word [muldivy+ebx]
	movsx   eax, ax
	movsx   edx, dx
	shld	edx,eax,2
	add	edx,100
	cmp	edx,99
	ja	@@2
	mov	ecx,edx
	movzx	eax, word [esi+2]
	imul	word [muldivx+ebx]
	movsx   eax, ax
	movsx   edx, dx
	mov	ebx,ecx
	shld	edx,eax,2
	add	edx,160
	cmp	edx,319
	ja	@@2
	mov	cl,dl
	and	cl,7
	shr	edx,3
	shl	ebx,1
	movzx	ebx, word [rows1+ebx]
	add	ebx,edx
	mov	ch,80h
	shr	ch,cl
	mov	cl,[esi]
	cmp	cl,180
	jb	@@sc1
	mov	eax, [curemmptr0]
	or	byte [eax+ebx],ch
	mov	eax, [curemmptr1]
	or	byte [eax+ebx],ch ;fs:
	jmp	@@2
@@sc1:	cmp	cl,110
	jb	@@sc2
	mov	eax, [curemmptr0]
	or	byte [eax+ebx+4096],ch
	mov	eax, [curemmptr1]
	or	byte [eax+ebx+4096],ch ; fs
	jmp	@@2
@@sc2:
	mov	eax, [curemmptr0]
	or	byte [eax+ebx],ch
	or	byte [eax+ebx+4096],ch
	mov	eax, [curemmptr1]
	or	byte [eax+ebx],ch ;fs
	or	byte [eax+ebx+4096],ch ;fs
@@2:	add	esi,8
	dec	ebp
	jnz	@@1
	ret
@@4:	call	random
	and	eax,1023
	sub	eax,512
	mov	[esi+2],ax
	call	random
	and	eax,1023
	sub	eax,512
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
	mov	eax,2
@@tnz:	push	eax
	mov	edi,150
	sub	edi,eax
	mov	[_nostar2],ax
	mov	eax,80
	mul	edi
	mov	edi,eax
	mov	[_nostar1],di
	add	edi, _ddstars_planar
	;mov	ax,_textpic
	;mov	ds,ax
	;mov	si,040h
	mov	esi, _textpic + 040h
	movzx	eax, word [startxtp0]
	add	esi, eax
	pop	ecx
	dec	ecx

	sub	edi,40	
	;mov	dx,3c4h
	;mov	ax,0f02h
	;out	dx,ax
	xor	eax,eax
	%assign zzz 0
	%rep	40/4
	mov	[edi+zzz+PLANE_SIZE*0],eax
	mov	[edi+zzz+PLANE_SIZE*1],eax
	mov	[edi+zzz+PLANE_SIZE*2],eax
	mov	[edi+zzz+PLANE_SIZE*3],eax
	%assign zzz zzz+4
	%endrep
	add	edi,80
	dec	ecx
	jz	@@tc0c
	
	;mov	dx,3c4h
	;mov	ax,0f02h
	;out	dx,ax
	mov	eax,0
	%assign zzz 0
	%rep	40/4
	mov	[edi+zzz+PLANE_SIZE*0],eax
	mov	[edi+zzz+PLANE_SIZE*1],eax
	mov	[edi+zzz+PLANE_SIZE*2],eax
	mov	[edi+zzz+PLANE_SIZE*3],eax
	%assign zzz zzz+4
	%endrep
	add	edi,80
	dec	ecx
	jz	@@tc0
	dec	ecx
	jz	@@tc0b

	;mov	dx,3ceh
	;mov	ax,0400h
	;out	dx,ax
	;mov	eax,01h+400h+800h
	;out	dx,ax

@@tc1:	;mov	dx,3c4h
	;mov	ax,0102h+400h+800h
	;out	dx,ax
	%assign zzz 0
	%rep	40/4
	mov	eax,[esi+zzz]
	mov	[edi+zzz+PLANE_SIZE*0],eax
	;mov	[edi+zzz+PLANE_SIZE*1],eax
	mov	[edi+zzz+PLANE_SIZE*2],eax
	mov	[edi+zzz+PLANE_SIZE*3],eax
	%assign zzz zzz+4
	%endrep
	add	esi,40
	;mov	dx,3c4h
	;mov	ax,0202h+400h+800h
	;out	dx,ax
	%assign zzz 0
	%rep	40/4
	mov	eax,[esi+zzz]
	mov	[edi+zzz+PLANE_SIZE*1],eax
	%assign zzz zzz+4
	%endrep
	add	esi,40
	add	edi,80
	dec	ecx
	jz	@@tc0b
	jmp	@@tc1
	
@@tc0b:	;mov	dx,3ceh
	;mov	ax,0001h
	;out	dx,ax

	;mov	dx,3c4h
	;mov	ax,0f02h
	;out	dx,ax
	mov	eax,0
	%assign zzz 0
	%rep	40/4
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	add	edi,80

	dec	edi
	mov	[_nostar2],di
@@tc0:	ret
@@tc0c:	;mov	dx,3c4h
	;mov	ax,0f02h
	;out	dx,ax
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
@@sw0:	;out	dx,ax
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
	call	_shim_outp_naked
	;out	dx,al
	inc	dx
	
	mov	al,0
	call	_shim_outp_naked
	;out	dx,al
	mov	al,0
	call	_shim_outp_naked
	;out	dx,al
	mov	al,0
	call	_shim_outp_naked
	;out	dx,al
	
	mov	al,25*70/100
	mul	bl
	mov	al,ah
	call	_shim_outp_naked
	;out	dx,al
	mov	al,31*70/100
	mul	bl
	mov	al,ah
	call	_shim_outp_naked
	;out	dx,al
	mov	al,38*70/100
	mul	bl
	mov	al,ah
	call	_shim_outp_naked
	;out	dx,al
	
	mov	al,45*56/100
	mul	bl
	mov	al,ah
	call	_shim_outp_naked
	;out	dx,al
	mov	al,58*56/100
	mul	bl
	mov	al,ah
	call	_shim_outp_naked
	;out	dx,al
	mov	al,69*56/100
	mul	bl
	mov	al,ah
	call	_shim_outp_naked
	;out	dx,al

	mov	al,67*64/100
	mul	bl
	mov	al,ah
	call	_shim_outp_naked
	;out	dx,al
	mov	al,84*64/100
	mul	bl
	mov	al,ah
	call	_shim_outp_naked
	;out	dx,al
	mov	al,99*64/100
	mul	bl
	mov	al,ah
	call	_shim_outp_naked
	;out	dx,al

	;-----

	mov	al,0
	call	_shim_outp_naked
	;out	dx,al
	mov	al,0
	call	_shim_outp_naked
	;out	dx,al
	mov	al,0
	call	_shim_outp_naked
	;out	dx,al

	mov	al,10
	call	_shim_outp_naked
	;out	dx,al
	mov	al,20
	call	_shim_outp_naked
	;out	dx,al
	mov	al,35
	call	_shim_outp_naked
	;out	dx,al

	mov	al,20
	call	_shim_outp_naked
	;out	dx,al
	mov	al,30
	call	_shim_outp_naked
	;out	dx,al
	mov	al,45
	call	_shim_outp_naked
	;out	dx,al

	mov	al,30
	call	_shim_outp_naked
	;out	dx,al
	mov	al,40
	call	_shim_outp_naked
	;out	dx,al
	mov	al,60
	call	_shim_outp_naked
	;out	dx,al
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
	;mov	ax,es
	;mov	ds,ax
	
	;mov	ax,[starvram]
	;mov	es,ax
	mov	esi, [curemmptr0]
	mov	edi, _ddstars_planar + PLANE_SIZE * 0
	;xor	di,di
	;mov	dx,3c4h
	;mov	ax,0102h
	;out	dx,ax
	;mov	si,0
	mov	ecx,100
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
@@3s:	add	esi,40
	add	edi,80
	loop	@@3

	mov	edi, _ddstars_planar + PLANE_SIZE * 1
	;mov	si,4096
	mov	esi, [curemmptr0]
	add	esi, 4096
	;mov	dx,3c4h
	;mov	ax,0202h
	;out	dx,ax
	mov	ecx,100
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
@@7s:	add	esi,40
	add	edi,80
	loop	@@7

	movzx	eax,word [emmpage4]
	add	eax,32
	and	eax,63
	call	fetch4ax
	;mov	ds,ax
	mov	esi, eax
	push esi
	mov	edi, _ddstars_planar + PLANE_SIZE * 0
	add	edi,200*40
	add	esi,99*40
	;mov	dx,3c4h
	;mov	ax,0102h
	;out	dx,ax
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
@@5s:	sub	esi,40
	add	edi,80
	loop	@@5
	mov	edi, _ddstars_planar + PLANE_SIZE * 1
	add	edi,200*40
	pop	esi
	add	esi,99*40+4096
	;mov	dx,3c4h
	;mov	ax,0202h
	;out	dx,ax
	mov	ecx,100
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
@@8s:	sub	esi,40
	add	edi,80
	loop	@@8

	call	_resolve_planar
	call	_demo_blit

	;mov	bx,2
	;int	0fch
	call	_dis_exit
	or	ax,ax
	jz	@@aga
	ret
	
;	mov	ax,0a000h
;	mov	ds,ax
;	xor	si,si
;	mov	cx,40*400
;	mov	dx,0
;@@1:	lodsb
;	shl	al,1
;	adc	dx,0
;	shl	al,1
;	adc	dx,0
;	shl	al,1
;	adc	dx,0
;	shl	al,1
;	adc	dx,0
;	shl	al,1
;	adc	dx,0
;	shl	al,1
;	adc	dx,0
;	shl	al,1
;	adc	dx,0
;	shl	al,1
;	adc	dx,0
;	loop	@@1
;	int	3
;	ret
