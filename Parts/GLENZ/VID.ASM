%include "asm.inc"

;publics:
;setvmode()

extern _bgpic

section .data
	

modes:
  dd	v320x200x256
	dd	v320x350x256
	dd	v320x350x256
	dd	v320x240x256
	dd	vtseng640x400x256

v320x200x256:
	dd	init320x200	;init routine
	dd	switch320x200	;page switcher
	dd	clear64k		;clear all screens
	dd	twpset
	dd	twlineto
	dd	twhline
	dd	twhlinegroup
	dd	twthlinegroup
	dd	polygroup
	dd	clearpage
	dd	fwaitborder
v320x350x256:
	dd	init320x350	;init routine
	dd	switch320x350	;page switcher
	dd	clear64k		;clear all screens
	dd	twpset
	dd	twlineto
	dd	twhline
	dd	twhlinegroup
	dd	twthlinegroup
	dd	polygroup
	dd	clearpage
	dd	fwaitborder
v320x350x256unr:
	dd	init320x350unr   ;init routine
	dd	switch320x350	;page switcher
	dd	clear64k		;clear all screens
	dd	twpset
	dd	twlineto
	dd	twhline
	dd	twhlinegroup
	dd	twthlinegroup
	dd	polygroup
	dd	clearpage
	dd	fwaitborder
v320x240x256:
	dd	init320x240	;init routine
	dd	switch320x240	;page switcher
	dd	clear64k		;clear all screens
	dd	twpset
	dd	twlineto
	dd	twhline
	dd	twhlinegroup
	dd	twthlinegroup
	dd	polygroup
	dd	clearpage
	dd	fwaitborder
vtseng640x400x256:
	dd	init640x400	;init routine
	dd	switch640x400	;page switcher
	dd	clear640x400	;clear all screens
	dd	twpset
	dd	twlineto
	dd	twhline
	dd	twhlinegroup
	dd	twthlinegroup
	dd	polygroup
	dd	clearpage
	dd	fwaitborder

pagep	dw	0
wpage	dw	0,1,2
wpage2	dw	0,4,8
spage	dw	2,0,1

t324v	dw	0a5f0h
t324v1	dw	0aaa0h
t324v2	dw	0a140h
t324vout dw	01400h
t324vout1 dw	05f00h
t324vout2 dw	0aa00h

t365v	dw	0a000h
t365v1	dw	0a800h
t365vo	dw	08000h
t365vo1 dw	00000h

section .code

global setvmode
setvmode:
	;ax=mode => ds:si
	movzx	ebx,ax
	shl	bx,1
	mov	bx,[modes+ebx]
	mov	cx,16
.@@1:	mov	ax,[bx]
	mov	[esi],ax
	mov	word [esi+2],cs
	add	si,4
	add	bx,2
	loop	.@@1
	ret

;video mode structure

%include "vidmisc.asm"
%include "vidinit.asm"
%include "vidtwe.asm"
%include "vidnrm.asm"
%include "vidpoly.asm"

;****************************************************************

section .code

setrows:
	mov	[rowsadd],dx
	mov	[truerowsadd],dx
	xor	ax,ax
	mov	ebx,rows
ain1:	mov	[ebx],ax
	add	ax,dx
	add	bx,2
	loop	ain1
	ret

init640x400:
	LOADDS
	mov	dword [projxmul],256*2
	mov	dword [projymul],213*2
	mov	word [projxadd],320
	mov	word [projyadd],200
	mov	dword [projminz],128
	mov	word [projminzshr],7
	mov	word [wminx],0
	mov	word [wminy],0
	mov	word [wmaxx],639
	mov	word [wmaxy],399
	mov	word [framerate10],700 ;70 frames/sec
	;
	mov	ax,11h ;640x480/mono
	int	10h
	call	tweak640x400
	mov	cx,400
	mov	dx,160
	call	setrows
	ret

switch640x400:
swipa2:	mov	ax,0a000h
	mov	[vram],ax
	mov	[truevram],ax
	mov	bx,[pagep]
	inc	bx
	cmp	bx,3
	jb	sws1
	xor	ebx,ebx
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

clear640x400:
	call	switch640x400
	call	clear64k
	call	switch640x400
	call	clear64k
	call	switch640x400
	call	clear64k
	call	switch640x400
	call	clear64k
	ret

;****************************************************************

global _init320x200
_init320x200:
init320x200:
	LOADDS
	mov	dword [projxmul],256
	mov	dword [projymul],213
	mov	word [projxadd],160
	mov	word [projyadd],130
	mov	dword [projminz],128
	mov	word [projminzshr],7
	mov	word [wminx],0
	mov	word [wminy],0
	mov	word [wmaxx],319
	mov	word [wmaxy],199
	mov	word [framerate10],700
	;
;	call	tweak320x200
	mov	cx,200
	mov	dx,80
	call	setrows
	ret

init320x240:
	LOADDS
	mov	dword [projxmul],256
	mov	dword [projymul],256
	mov	word [projxadd],160
	mov	word [projyadd],120
	mov	dword [projminz],128
	mov	word [projminzshr],7
	mov	word [wminx],0
	mov	word [wminy],0
	mov	word [wmaxx],319
	mov	word [wmaxy],239
	mov	word [framerate10],610 ;60 frames/sec
	;
	call	tweak320x200
	LOADDS
	mov	esi,hseq1
	call	sethseq ;to 240 mode
	mov	cx,240
	mov	dx,80
	call	setrows
	ret

switch320x240b:
	LOADDS
 	mov	ax,[t324v]
	mov	bx,[t324v1]
	mov	[t324v],bx
	mov	[t324v1],ax
	mov	[vram],bx
	mov	[truevram],bx
	mov	bx,[t324vout1]
	mov	cx,[t324vout2]
	mov	[t324vout1],cx
	mov	[t324vout2],bx
	mov	dx,3d4h
	mov	al,0ch
	mov	ah,bh
	out	dx,ax
	ret

switch320x240:
switch320x200:
	LOADDS
	mov	ax,[t324v]
	mov	bx,[t324v1]
	mov	cx,[t324v2]
	mov	[t324v],bx
	mov	[t324v1],cx
	mov	[t324v2],ax
	mov	[vram],bx
	mov	[truevram],bx
	mov	ax,[t324vout]
	mov	bx,[t324vout1]
	mov	cx,[t324vout2]
	mov	[t324vout],bx
	mov	[t324vout1],cx
	mov	[t324vout2],ax
	mov	dx,3d4h
	mov	al,0ch
	mov	ah,bh
	out	dx,ax
	ret

clear64k:
	cld
	mov	dx,3c4h
	mov	ax,0f02h
	out	dx,ax
	mov	ax,0a000h
	mov	es,ax
	mov	cx,32768
	xor	ax,ax
	xor	di,di
	rep	stosw
	ret

;****************************************************************

init320x350unr:
	LOADDS
	mov	dword [projxmul],256
	mov	dword [projymul],420
	mov	word [projxadd],180
	mov	word [projyadd],175
	mov	dword [projminz],128
	mov	word [projminzshr],7
	mov	word [wminx],0
	mov	word [wminy],32
	mov	word [wmaxx],359
	mov	word [wmaxy],349-32
	mov	word [framerate10],700 ;70 frames/sec
	;
	call	tweak320x350
	mov	cx,350
	mov	dx,92
	call	setrows
	ret

init320x350:
	LOADDS
	mov	dword [projxmul],256
	mov	dword [projymul],420
	mov	word [projxadd],180
	mov	word [projyadd],175
	mov	dword [projminz],128
	mov	word [projminzshr],7
	mov	word [wminx],0
	mov	word [wminy],0
	mov	word [wmaxx],359
	mov	word [wmaxy],349
	mov	word [framerate10],700 ;70 frames/sec
	;
	call	tweak360x350
	mov	cx,350
	mov	dx,92
	call	setrows
	ret

;ALIGN 2

switch320x350:
	LOADDS
	mov	ax,[t365v]
	xchg	ax,[t365v1]
	mov	[t365v],ax
	mov	[vram],ax
	mov	[truevram],ax
	mov	bx,[t365vo]
	xchg	bx,[t365vo1]
	mov	[t365vo],bx
	mov	dx,3d4h
	mov	al,0ch
	mov	ah,bh
	out	dx,ax
	call	waitborder
	ret

justret:
	ret

clearpage:
	push	ax
	mov	dx,3c4h
	mov	ax,0f02h
	out	dx,ax
	mov	es,[vram]
	movzx	edi, word [wminy]
	shl	di,1
	mov	di,[rows+edi]
	mov	ax,[wminx]
	mov	dx,[wmaxx]
	sub	dx,ax
	shr	ax,2
	add	di,ax
	add	dx,7
	shr	dx,4
	mov	cx,[wmaxy]
	sub	cx,[wminy]
	inc	cx
	pop	ax
	push	ax
	shl	eax,16
	pop	ax
.@@1:	push	cx
	push	di
	mov	cx,dx
	rep	stosd
	pop	di
	pop	cx
	add	di,[rowsadd]
	loop	.@@1
	ret
