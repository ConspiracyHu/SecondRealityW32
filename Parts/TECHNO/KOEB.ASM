extern _circle;
extern _circle2;

section .data

%include "sin1024.inc"

;################################################################

sizefade dw	0
rotspeed dw	0
palfader dw	0
palfader2 db	255
zumplane db	11h

;ALIGN 16
	
flip8:
db 0,128,64,192,32,160,96,224,16,144,80,208,48,176,112,240,8,136,72,200
db 40,168,104,232,24,152,88,216,56,184,120,248,4,132,68,196,36,164,100
db 228,20,148,84,212,52,180,116,244,12,140,76,204,44,172,108,236,28,156
db 92,220,60,188,124,252,2,130,66,194,34,162,98,226,18,146,82,210,50,178
db 114,242,10,138,74,202,42,170,106,234,26,154,90,218,58,186,122,250,6
db 134,70,198,38,166,102,230,22,150,86,214,54,182,118,246,14,142,78,206
db 46,174,110,238,30,158,94,222,62,190,126,254,1,129,65,193,33,161,97,225
db 17,145,81,209,49,177,113,241,9,137,73,201,41,169,105,233,25,153,89,217
db 57,185,121,249,5,133,69,197,37,165,101,229,21,149,85,213,53,181,117,245
db 13,141,77,205,45,173,109,237,29,157,93,221,61,189,125,253,3,131,67,195
db 35,163,99,227,19,147,83,211,51,179,115,243,11,139,75,203,43,171,107,235
db 27,155,91,219,59,187,123,251,7,135,71,199,39,167,103,231,23,151,87,215
db 55,183,119,247,15,143,79,207,47,175,111,239,31,159,95,223,63,191,127,255

;circlesB times 8 dd	0

pal	times 32*3 db	0

pal0:
	db	0,30,40
	db	0,0 ,0 
	db	0,0 ,0 
	db	0,0 ,0 
	db	0,0 ,0 
	db	0,0 ,0 
	db	0,0 ,0 
	db	0,0 ,0 
	db	0,30,40
	db	0,0 ,0 
	db	0,0 ,0 
	db	0,0 ,0 
	db	0,0 ,0 
	db	0,0 ,0 
	db	0,0 ,0 
	db	0,0 ,0 

pal1:
	db	 0, 0*7/9, 0
	db	10,10*7/9,10
	db	20,20*7/9,20
	db	30,30*7/9,30
	db	40,40*7/9,40
	db	50,50*7/9,50
	db	60,60*7/9,60
	db	30,30*7/9,30
	db	 0, 0*7/9, 0
	db	10,10*7/9,10
	db	20,20*7/9,20
	db	30,30*7/9,30
	db	40,40*7/9,40
	db	50,50*7/9,50
	db	60,60*7/9,60
	db	30,30*7/9,30

pal2:	
	db	50,50*6/9,50
	db	60,60*6/9,60
	db	30,30*6/9,30
	db	 0, 0*6/9, 0
	db	10,10*6/9,10
	db	20,20*6/9,20
	db	30,30*6/9,30
	db	40,40*6/9,40
	db	50,50*6/9,50
	db	60,60*6/9,60
	db	30,30*6/9,30
	db	 0, 0*6/9, 0
	db	10,10*6/9,10
	db	20,20*6/9,20
	db	30,30*6/9,30
	db	40,40*6/9,40
	
sinuspower db	0
powercnt db	0

global _power1
_power1:
power0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0
	times	256 db 0

section .code

%macro PLANE	1 ; pl
	mov	dx,3c4h
	mov	ax,0002h+%1*100h
	out	dx,ax
%endmacro

; ch = mask
; cl = plane count
bltline:
	push	esi
	push	edi
	mov	dx,3c4h
	mov	al,2
	;out	dx,al
	inc	dx
@@1:	mov	al,ch
	;out	dx,al
	%assign zzz 0
	%rep	10
	mov	eax,[esi+zzz]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
  %endrep
	add	esi,40
  add edi,80 * 400
	shl	ch,1
	dec	cl
	jnz	@@1
	pop	edi
	pop	esi
	ret


bltlinerev:
	push	esi
	push	edi
	mov	dx,3c4h
	mov	al,2
	;out	dx,al
	inc	dx
	xor	ebx,ebx
@@1:	mov	al,ch
	;out	dx,al
	%assign zzz 0
	%rep	10
	mov	bl,[esi+36-zzz]
	mov	al,[flip8+ebx]
	rol	eax,8
	mov	bl,[esi+37-zzz]
	mov	al,[flip8+ebx]
	rol	eax,8
	mov	bl,[esi+38-zzz]
	mov	al,[flip8+ebx]
	rol	eax,8
	mov	bl,[esi+39-zzz]
	mov	al,[flip8+ebx]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
  %endrep
	add	esi,40
  add edi,80 * 400
	shl	ch,1
	dec	cl
	jnz	@@1
	pop	edi
	pop	esi
	ret


resetmode13:
	mov	bx,1
	int	0fch
	mov	dx,3c8h
	mov	al,0
	out	dx,al
	inc	dx
	mov	cx,768
@@ccc:	out	dx,al
	loop	@@ccc
	mov	bx,1
	int	0fch
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
	mov	al,11h
	out	dx,al
	mov	al,255
	out	dx,al
	mov	al,32
	out	dx,al
	;clear pal
	mov	dx,3c8h
	xor	al,al
	out	dx,al
	inc	dx
	mov	cx,768
@@clp:	out	dx,al
	loop	@@clp
	ret


mixpal:
	;cs:si=>cs:di, for cx
	push	edx
	cmp	edx,256
	jg	@@2
	mov	ebx,edx
@@1:	mov	al,[esi]
	xor	ah,ah
	inc	esi
	mul	bx
	shr	ax,8
	mov	[edi],al
	inc	edi
	loop	@@1
	pop	edx
	ret

@@2:	mov	ebx,edx
	sub	ebx,256	
@@4:	mov	al,[esi]
	xor	ah,ah
	inc	esi
	add	ax,bx
	cmp	ax,64
	jb	@@3
	mov	al,63
@@3:	mov	[edi],al
	inc	edi
	loop	@@4
	pop	edx
	ret

extern _setpalarea

outpal:
	;mov	dx,3c8h
	;out	dx,al
	;mov	ax,cs
	;mov	ds,ax
	;inc	dx
	;rep	outsb
  movzx ecx, cl
  push ecx
  movzx eax, al
  push eax
  push esi
  call _setpalarea
  add esp, 12
	ret


waitb:
	;mov	bx,1
	;int	0fch
	ret


;rotate1:
;	;xor	esi,esi
;	mov	ecx,32000/32-2
;	cld
;	jmp	@@2
;	;edx.eax
;@@1:	popf
;	%assign zzz 0
;	%rep 16
;	mov	ax,[esi+zzz]
;	rcr	al,1
;	rcr	ah,1
;	mov	[edi+zzz],ax ; es
;	%assign zzz zzz+2
;  %endrep
;@@2:	pushf
;	add	esi,zzz
;	add	edi,zzz
;	dec	ecx
;	jz	@@0
;	jmp	@@1
;@@0:	popf
;	ret

section .data

;ALIGN 2
framecountB dw	0
palanimcB dd	0
palanimc2B dd	0
scrnpos dw	0
scrnposl dw	0
scrnx	dw	0
scrny	dw	0
scrnrot dw	0
sinurot dw	0
overrot dw	0
overx	dw	0
overya	dw	0
patdir	dd	-3

memseg	dd	0

section .code

extern _shim_vram
extern _koeb_planar1
extern _koeb_planar2

init_interference:
	;mov	dx,3d4h
	;mov	ax,2813h
;	out	dx,ax
	
	;mov	bx,20+100*80
	
	;get mem for circles
	;mov	ah,48h
	;mov	bx,16384
;	int	21h
	;mov	[memseg],eax
	;%assign zzz 0
	;%rep 8
	;mov	[circlesB+zzz],eax
	;add	eax,2048
	;%assign zzz zzz+4
  ;%endrep
	
	;mov	ax,SEG _circle2
	;mov	ds,ax
	;xor	si,si
	;mov	ax,0a000h
	;mov	es,ax
  mov esi, _circle2
  mov edi, _koeb_planar1

	mov	ecx,200
	;xor	edi,edi
	mov	ebp,_koeb_planar1+80*399
@@1:	push	ecx
	push	edi
	mov	ecx,0401h
	call	bltline
	add	edi,40
	mov	ecx,0401h
	call	bltlinerev
	add	edi,40
	mov	edi,ebp
	mov	ecx,0401h
	call	bltline
	add	edi,40
	mov	ecx,0401h
	call	bltlinerev
	add	edi,40
	pop	edi
	add	edi,80
	sub	ebp,80
	add	esi,40
	pop	ecx
	loop	@@1
	
	;mov	dx,3ceh
	;mov	ax,0204h
	;out	dx,ax
	;mov	cx,400
	;mov	es,[circlesB+0]
	;mov	ax,0a000h
	;mov	ds,ax
  ;mov esi, _koeb_planar1
  ;mov edi, [circlesB]

	;mov	ecx,32000/4
	;xor	esi,esi
	;xor	edi,edi
	;rep	movsd
	;%assign zzz 0
	;%rep	7	
	;mov	esi,[circlesB+zzz]
	;mov	edi,[circlesB+zzz+4]
	;call	rotate1
	;%assign zzz zzz+4
  ;%endrep

	;mov	ax,SEG _circle
	;mov	ds,ax
	;xor	si,si
	;mov	ax,0a000h
	;mov	es,ax
  mov esi, _circle
  mov edi, _koeb_planar2
	mov	ecx,200
	;xor	di,di
	mov	ebp,_koeb_planar2+80*399
@@10:
	push	ecx
	push	edi
	mov	ecx,0103h ;start at plane 1, copy 3 planes
	call	bltline
	add	edi,40
	mov	ecx,0103h ;start at plane 1, copy 3 planes
	call	bltlinerev
	add	edi,40
	mov	edi,ebp
	mov	ecx,0103h ;start at plane 1, copy 3 planes
	call	bltline
	add	edi,40
	mov	ecx,0103h ;start at plane 1, copy 3 planes
	call	bltlinerev
	add	edi,40
	pop	edi
	add	edi,80
	sub	ebp,80
	add	esi,40*3
	pop	ecx
	loop	@@10
	mov	word [framecountB],0
	ret

extern _dis_waitb
extern _dis_musrow
extern _dis_exit
extern _demo_blit

extern _shim_vram
extern _koeb_planar1
extern _koeb_planar2

_resolve_planar:
  ;movzx esi, word [scrnposl]
  ;shl esi, 3
  ;add esi, 0x2000 >> 3
  mov esi, 80 * 100 + 20
  mov edi, _shim_vram
  mov ecx, 320*400
  mov edx, 320
  mov bl, 0x80
  resolve_byte:
    xor al, al
    test [_koeb_planar1+esi], bl
    jz nah1
      or al, 1
    nah1:
    test [_koeb_planar2+esi], bl
    jz nah2
      or al, 2
    nah2:
    test [_koeb_planar2+esi+80*400], bl
    jz nah3
      or al, 4
    nah3:
    test [_koeb_planar2+esi+80*400+2], bl
    jz nah4
      or al, 8
    nah4:
    stosb
    ror bl,1
    test bl,0x80
    jz nextbyte
      inc esi
    nextbyte:
    dec edx
    cmp edx, 0
    jne nextrow
      add esi, 40
      mov edx, 320
    nextrow:
  loop resolve_byte
  ret

do_interference:
@@aga:	call	_dis_waitb
	;mov	dx,3c0h
	;mov	al,13h
	;out	dx,al
	;mov	al,byte [scrnposl]
	;out	dx,al
	;mov	al,32
	;out	dx,al
	
	xor	al,al
	mov	esi,pal
	mov	ecx,16*3
	call	outpal

	mov	esi, [palanimcB]
	add	esi, [patdir]
	cmp	esi,0
	jge	@@a11
	mov	esi,8*3-3
@@a11:	cmp	esi,8*3
	jb	@@a1
	xor	esi,esi
@@a1:	mov	[palanimcB],esi
	mov	[palanimc2B],esi

	mov	dx,[palfader]
	add	dx,2
	cmp	dx,512
	jb	@@pf1
	mov	dx,512
@@pf1:	mov	[palfader],dx
;
	mov	esi,[palanimcB]
	add	esi,pal0
	mov	edi,pal
	mov	ecx,8*3
	call	mixpal
	mov	esi,[palanimcB]
	add	esi,pal0
	mov	edi,pal+8*3
	mov	ecx,8*3
	call	mixpal

	mov	esi,pal
	mov	al,0
	mov	ecx,16*3
	call	outpal

	jmp	@@OVER3
;	mov	dx,3c4h
;	mov	al,2
;	mov	ah,[zumplane]
;	rol	ah,1
;	mov	[zumplane],ah
;	;out	dx,ax
;
;	;mov	ax,0a000h
;	;mov	es,ax
;	;xor	si,si
;	movzx edi, word [scrnpos]
;  add edi, _shim_vram
;  movzx	ebp, word [sinurot]
;	add	bp,7*2
;	and	bp,2047
;	mov	[sinurot],bp
;	mov	ecx,200
;@@cp1:
;  %assign zzz 0
;	push	esi
;	add	bp,9*2
;	and	bp,2047
;	movzx	ebx,word [_koe_sin1024+ebp]
;	sar	bx,3
;	mov	bh,[sinuspower]
;	movsx	ax,byte [power0+ebx]
;	sub	ax,[scrnposl]
;	add	ax,[overx]
;	mov	bx,ax
;	and	bx,7
;  xor bx,7
;  shl	bx,2
;	;neg	bx
;	mov	esi,[circlesB+ebx]
;	sar	ax,3
;	add	si,ax
;	add	si,[overya]
;	%rep	40/4+1
;	mov	eax,[esi+zzz]
;	mov	[edi+zzz],eax
;	%assign zzz zzz+4
;  %endrep
;	pop	esi
;	add	edi,80
;	add	esi,80
;	dec	ecx
;	jz	@@cp0
;	jmp	@@cp1
;@@cp0:
@@OVER3:
	;MOVE
	;mov	bx,6
	;int	0fch
  call _dis_musrow
  mov bx,ax
	;bx=row
	and	bx,7
	cmp	bx,0
	jne	@@m1
	mov	dword [patdir],-3
@@m1:	cmp	bx,4
	jne	@@m2
	mov	dword [patdir],-3 ;-3
@@m2:
	movzx	ebx, word [scrnrot]
	add	bx,5
	and	bx,1023
	mov	[scrnrot],bx

	cmp	word [framecountB],64
	jb	@@szf1
	inc	word [rotspeed]
	mov	ax,[sizefade]
	cmp	ax,16834
	jge	@@1
	;add	ax,256
@@1:	mov	[sizefade],ax
@@szf1:
	shl	bx,1
	mov	ax,[_koe_sin1024+ebx]
	imul	word [sizefade]
	mov	ax,dx
	add	ax,160
	mov	[scrnx],ax
	add	bx,256*2
	and	ebx,1024*2-1
	mov	ax,[_koe_sin1024+ebx]
	imul	word [sizefade]
	mov	ax,dx
	add	ax,100
	mov	[scrny],ax

	movzx	ebx, word [overrot]
	add	bx,[rotspeed]
	and	bx,1023
	mov	[overrot],bx

	shl	bx,1
	mov	ax,[_koe_sin1024+ebx]
	sar	ax,2
	imul	word [sizefade]
	mov	ax,dx
	add	ax,160
	mov	[overx],ax
	add	bx,256*2
	and	ebx,1024*2-1
	mov	ax,[_koe_sin1024+ebx]
	sar	ax,2
	imul	word [sizefade]
	mov	ax,dx
	add	ax,100
	mov	bx,80
	mul	bx
	mov	[overya],ax

	mov	ax,[scrnx]
	mov	bx,ax
	and	ax,7
	mov	[scrnposl],ax
	mov	ax,80
	mul	word [scrny]
	sar	bx,3
	add	ax,bx
	mov	[scrnpos],ax

	mov	bx,[scrnpos]
	mov	dx,3d4h
	mov	al,0ch
	mov	ah,bh
	;out	dx,ax
	inc	al
	mov	ah,bl
	;out	dx,ax

	cmp	word [framecountB],192
	jb	@@asd2
	test	word [framecountB],3
	jnz	@@asd2
@@asd2:	
;	cmp	[framecountB],256
;	jb	@@p1
;	inc	[powercnt]
;	cmp	[powercnt],16
;	jb	@@p1
;	mov	[powercnt],0
;	cmp	[sinuspower],15
;	jae	@@p1
;	inc	[sinuspower]
@@p1:
	inc	word [framecountB]
	cmp	word [framecountB],256
	je	@@xx
  call _resolve_planar
  call _demo_blit
  call _dis_exit
	;mov	bx,2
	;int	0fch
	or	ax,ax
	jz	@@aga
@@xx:	ret


global _dointerference2
_dointerference2:
	push	ebp
	;mov	bp,sp
	;push	si
	;push	di
	;push	ds
	
;	call	resetmode13
  ;mov eax, [esp+8]
	call	init_interference
	call	do_interference	
	;mov	es,[memseg]
	;mov	ah,49h
	;int	21h
	
	;pop	ds
	;pop	di
	;pop	si
	pop	ebp
	ret
