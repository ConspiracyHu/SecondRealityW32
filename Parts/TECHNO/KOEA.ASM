extern _circle
extern _circle2

section .data

;ALIGN 16

global _vbuf
_vbuf times 8192 db 0

_rows	times 200 dw	0
_blit16t times 256 dw	0
clipleft dw	0


global polyisides
polyisides dw	0
global polyixy
polyixy	times 16 dw	0,0
global polysides
polysides dw	0
global polyxy
polyxy	times 16 dw	0,0
;%include "polyclip.asm"

;ALIGN 2
global _koe_sin1024
%include "sin1024.inc"

section .code

extern clipanypoly

%macro JCXZ_LARGE 1
  cmp ecx, 0
  jz %1
%endmacro

%macro REPOUTSB 0
	;local l1
%%l1:	mov	al,[esi]
	inc	si
	out	dx,al
	dec	cx
	jnz	%%l1
%endmacro

global _asminit	
_asminit:
	push 	ebp
	mov	eax,[esp+8]
	;mov	[_vbuf],eax
	call	blitinit
	pop	ebp
	ret

global _asmdoit	
_asmdoit:
	push 	ebp
	mov	ebp,esp
	push	esi
	push	edi
	push	ebx
	;push	ds
	mov esi,[ebp+8]
	mov edi,[ebp+12]
	call	blit16
	;pop	ds
	pop	ebx
	pop	edi
	pop	esi
	pop	ebp
	ret


global _asmdoit2
_asmdoit2:
	push 	ebp
	mov	ebp,esp
	push	esi
	push	edi
	push	ebx
	;push	ds
	mov esi,[ebp+8]
	mov edi,[ebp+12]
	call	blit16b
	;pop	ds
	pop	ebx
	pop	edi
	pop	esi
	pop	ebp
	ret


blitinit:
	mov	ebx,_rows
	mov	ecx,200
	mov	edx,40
	xor	eax,eax
blit_l1:
  mov	[ebx],ax
	add	ax,dx
	add	ebx,2
	loop	blit_l1
	xor	al,al
	mov	ebx,_blit16t
	mov	ecx,256
blit_1:	mov	dh,255
	mov	dl,al
	xor	ah,ah
  %assign lbln 1
	%rep	8
  %define LBL(x) lbln_ %+ lbln
;	local	l2
	rcl	dl,1
	jnc	LBL(x)
	xor	ah,dh
LBL(x):	shr	dh,1
  %assign lbln lbln+1
	%endrep
	mov	[ebx],ah
	ror	ah,1
	and	ah,80h
	mov	[ebx+1],ah
	add	ebx,2
	inc	al
	loop	blit_1
	ret


blit16:
	xor	ebx,ebx
	mov	ecx,200	
	jmp	@@1
	;ALIGN	16
@@1:
  %assign zzz 0
	xor	dh,dh ;line starts black
	%rep	40/2
	mov	bl,[esi+zzz]
	xor	bl,dh
	mov	ax,[_blit16t+ebx*2]

	mov	bl,[esi+1+zzz]
	xor	bl,ah
	mov	dx,[_blit16t+ebx*2]

	mov	ah,dl
	mov	[edi+zzz],ax
	%assign zzz zzz+2
	%endrep
	add	esi,40
	add	edi,40
	dec	ecx
	jz	@@2
	jmp	@@1
@@2:
	ret


blit16b:
	xor	ebx,ebx
	mov	ecx,200	
	jmp	@@1
	;ALIGN	16
@@1:
  %assign zzz 0
	xor	dh,dh ;line starts black
	%rep	40/2
	mov	bl,[esi+zzz]
	xor	bl,dh
	mov	ax,[_blit16t+ebx*2]
	mov	bl,[esi+1+zzz]
	xor	bl,ah
	mov	dx,[_blit16t+ebx*2]
	mov	ah,dl
	mov	[edi+zzz],ax
	%assign zzz zzz+2
	%endrep
	add	esi,40
	add	edi,80
	dec	ecx
	jz	@@2
	jmp	@@1
@@2:
	ret


drawline:
	push	esi
	push	edi
	push	ebp
@@vis:	movzx	ebx,bx
	cmp	bx,cx
	je	drawline_0
	jle	drawline_1
	xchg	bx,cx
	xchg	ax,dx
drawline_1:	sub	cx,bx
	mov	di,cx
	movzx	esi, word [_rows+ebx*2]
	movzx	ebp, word [clipleft]
	or	bp,bp
	jz	@@nl
	push	esi
	;left overflow fill
	jge	@@ndn
@@nup:
  add	esi,40
	xor	byte [_vbuf+esi],080h ;ds:
	inc	bp
	jnz	@@nup
	jmp	@@nl2
@@ndn:
  sub	esi,40
	xor	byte [_vbuf+esi],080h ;ds:
	dec	bp
	jnz	@@ndn
@@nl2:
  pop	esi
@@nl:	;
	JCXZ_LARGE	drawline_0
	movzx	ebp,ax
	shr	bp,3
	add	si,bp
	mov	bp,ax
	and	bp,7
	;go on
	cmp	ax,dx
	jl	ll_r
@@l:	;=============== left
	neg	dx
	add	dx,ax
	mov	bx,di
	shr	bx,1
	neg	bx
	jmp	[_loffs+ebp*4]
ALIGN 16

_loffs:
	dd	ll_l7
	dd	ll_l6
	dd	ll_l5
	dd	ll_l4
	dd	ll_l3
	dd	ll_l2
	dd	ll_l1
	dd	ll_l0

%macro llinemacro 9 ; mask,lbl1,lbl2,lbl3,lbl4,lbl5,lbl6,lbl7,lbl0
	;local	l1,l2
	;[si]=startpoint
	;di=ycnt
	;dx=xcnt
	;bx=counter
%%l1:	xor	byte [_vbuf+esi],%1 ;ds:
	add	esi,40
	dec	cx
	jz	drawline_0
	add	bx,dx
	jl	%%l1
%%l2:
%ifidni %2, ll_l0
	dec	si
	%endif
	sub	bx,di
	jl	%2
%ifidni %3, ll_l0
	dec	si
	%endif
	sub	bx,di
	jl	%3
%ifidni %4, ll_l0
	dec	si
	%endif
	sub	bx,di
	jl	%4
%ifidni %5, ll_l0
	dec	si
	%endif
	sub	bx,di
	jl	%5
%ifidni %6, ll_l0
	dec	si
	%endif
	sub	bx,di
	jl	%6
%ifidni %7, ll_l0
	dec	si
	%endif
	sub	bx,di
	jl	%7
%ifidni %8, ll_l0
	dec	si
	%endif
	sub	bx,di
	jl	%8
%ifidni %9, ll_l0
	dec	si
	%endif
	sub	bx,di
	jl	%%l1
	jmp	%%l2
%endmacro

ll_l7:	llinemacro 10000000b,ll_l0,ll_l1,ll_l2,ll_l3,ll_l4,ll_l5,ll_l6,ll_l7
ll_l6:	llinemacro 01000000b,ll_l7,ll_l0,ll_l1,ll_l2,ll_l3,ll_l4,ll_l5,ll_l6
ll_l5:	llinemacro 00100000b,ll_l6,ll_l7,ll_l0,ll_l1,ll_l2,ll_l3,ll_l4,ll_l5
ll_l4:	llinemacro 00010000b,ll_l5,ll_l6,ll_l7,ll_l0,ll_l1,ll_l2,ll_l3,ll_l4
ll_l3:	llinemacro 00001000b,ll_l4,ll_l5,ll_l6,ll_l7,ll_l0,ll_l1,ll_l2,ll_l3
ll_l2:	llinemacro 00000100b,ll_l3,ll_l4,ll_l5,ll_l6,ll_l7,ll_l0,ll_l1,ll_l2
ll_l1:	llinemacro 00000010b,ll_l2,ll_l3,ll_l4,ll_l5,ll_l6,ll_l7,ll_l0,ll_l1
ll_l0:	llinemacro 00000001b,ll_l1,ll_l2,ll_l3,ll_l4,ll_l5,ll_l6,ll_l7,ll_l0
ll_r:	;=============== right
	sub	dx,ax
	mov	bx,di
	shr	bx,1
	neg	bx
	jmp	[_roffs+ebp*4]

;ALIGN 16
_roffs:
	dd	rl_r7
	dd	rl_r6
	dd	rl_r5
	dd	rl_r4
	dd	rl_r3
	dd	rl_r2
	dd	rl_r1
	dd	rl_r0

%macro rlinemacro 9 ; mask,lbl1,lbl2,lbl3,lbl4,lbl5,lbl6,lbl7,lbl0
	;local	l1,l2
	;[si]=startpoint
	;di=ycnt
	;dx=xcnt
	;bx=counter
%%l1:
  xor	byte [_vbuf+esi],%1 ;ds:
	add	esi,40
	dec	cx
	jz	drawline_0
	add	bx,dx
	jl	%%l1
%%l2:
%ifidni %2, rl_r7
	inc	si
	%endif
	sub	bx,di
	jl	%2
%ifidni %3, rl_r7
	inc	si
	%endif
	sub	bx,di
	jl	%3
%ifidni %4, rl_r7
	inc	si
	%endif
	sub	bx,di
	jl	%4
%ifidni %5, rl_r7
	inc	si
	%endif
	sub	bx,di
	jl	%5
%ifidni %6, rl_r7
	inc	si
	%endif
	sub	bx,di
	jl	%6
%ifidni %7, rl_r7
	inc	si
	%endif
	sub	bx,di
	jl	%7
%ifidni %8, rl_r7
	inc	si
	%endif
	sub	bx,di
	jl	%8
%ifidni %9, rl_r7
	inc	si
	%endif
	sub	bx,di
	jl	%%l1
	jmp	%%l2
%endmacro

rl_r7:	rlinemacro 10000000b,rl_r6,rl_r5,rl_r4,rl_r3,rl_r2,rl_r1,rl_r0,rl_r7
rl_r6:	rlinemacro 01000000b,rl_r5,rl_r4,rl_r3,rl_r2,rl_r1,rl_r0,rl_r7,rl_r6
rl_r5:	rlinemacro 00100000b,rl_r4,rl_r3,rl_r2,rl_r1,rl_r0,rl_r7,rl_r6,rl_r5
rl_r4:	rlinemacro 00010000b,rl_r3,rl_r2,rl_r1,rl_r0,rl_r7,rl_r6,rl_r5,rl_r4
rl_r3:	rlinemacro 00001000b,rl_r2,rl_r1,rl_r0,rl_r7,rl_r6,rl_r5,rl_r4,rl_r3
rl_r2:	rlinemacro 00000100b,rl_r1,rl_r0,rl_r7,rl_r6,rl_r5,rl_r4,rl_r3,rl_r2
rl_r1:	rlinemacro 00000010b,rl_r0,rl_r7,rl_r6,rl_r5,rl_r4,rl_r3,rl_r2,rl_r1
rl_r0:	rlinemacro 00000001b,rl_r7,rl_r6,rl_r5,rl_r4,rl_r3,rl_r2,rl_r1,rl_r0
drawline_0:
	pop	ebp
	pop	edi
	pop	esi
	ret


global _asmbox	
_asmbox:
	push 	ebp
	mov	ebp,esp
	push	esi
	push	edi
	push	ebx
	;push	ds

  %assign P 0
  %rep 8	
	mov	eax,[ebp+8+P*4]
	mov	word [polyixy+P*2],ax
  %assign P P+1
  %endrep

	mov	word [polyisides],4
	call	clipanypoly

	;mov	ds,[_vbuf]
	mov	esi,polyxy
	movzx	edi,word [polysides]
	or	edi,edi
	jz	@@0
	dec	edi
	jz	@@2

@@1:
  movzx	eax,word [esi+0]
	movzx	ebx,word [esi+2]
	movzx	edx,word [esi+4]
	movzx	ecx,word [esi+6]
	call	drawline
	add	esi,4
	dec	edi
	jnz	@@1

@@2:
  movzx eax,word [esi+0]
	movzx ebx,word [esi+2]
	movzx edx,word [polyxy+0]
	movzx ecx,word [polyxy+2]
	call	drawline

@@0:	;pop	ds
	pop	ebx
	pop	edi
	pop	esi
	pop	ebp
	ret


;################################################################
section .data

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

circles times 8 dd	0

pal2:
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

pal1:
	db	30,30*8/9,30
	db	60,60*8/9,60
	db	50,50*8/9,50
	db	40,40*8/9,40
	db	30,30*8/9,30
	db	20,20*8/9,20
	db	10,10*8/9,10
	db	 0, 0*8/9, 0
	db	30,30*8/9,30
	db	60,60*8/9,60
	db	50,50*8/9,50
	db	40,40*8/9,40
	db	30,30*8/9,30
	db	20,20*8/9,20
	db	10,10*8/9,10
	db	 0, 0*8/9, 0
	
sinuspower db	0
powercnt db	0

global _power0
_power0:
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

%macro PLANE 1 ; pl
	mov	dx,3c4h
	mov	ax,0002h+%1*100h
	;out	dx,ax
%endmacro

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
	mov	bx,1
	int	0fch
	ret


rotate1:
	;xor	esi,esi
	mov	ecx,32000/32-2
	cld
	jmp	@@2
	;edx.eax
@@1:	popf
	%assign zzz 0
	%rep 16
	mov	ax,[esi+zzz]
	rcr	al,1
	rcr	ah,1
	mov	[edi+zzz],ax ;es
	%assign zzz zzz+2
	%endrep
@@2:	pushf
	add	esi,zzz
	add	edi,zzz
	dec	ecx
	jz	@@0
	jmp	@@1
@@0:	popf
	ret

section .data

ALIGN 2
framecount dw	0
palanimc dw	0
palanimc2 dw	0
scrnpos dw	0
scrnposl dw	0
scrnx	dw	0
scrny	dw	0
scrnrot dw	0
sinurot dw	0
overrot dw	211
overx	dw	0
overya	dw	0
patdir	dw	0

memseg	dd	0

section .code

extern _shim_vram
extern _koe_tempbuf
extern _koe_planar

init_interference:
	;mov	dx,3d4h
	;mov	ax,2813h
	;out	dx,ax
	
	;mov	bx,20+100*80
	
	;get mem for circles
	;mov	ah,48h
	;mov	bx,16384
	;int	21h
	mov	[memseg],eax
	%assign zzz 0
	%rep 8
	mov	[circles+zzz],eax
	add	eax,2048*16
	%assign zzz zzz+4
	%endrep
	
	mov	esi,_circle2
	;mov	ds,eax
	;xor	esi,esi
	;mov	ax,0a000h
	;mov	es,ax
	mov	ecx,200
	;xor	edi,edi
  mov edi, _koe_tempbuf
	mov	ebp,_koe_tempbuf+80*399
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
	;mov	ecx,400
	;mov	es,[circles+0]
	;mov	ax,0a000h
	;mov	ds,ax
	mov	ecx,32000/4
  mov esi,_koe_tempbuf
  mov edi,[circles+0]
	;xor	esi,esi
	;xor	edi,edi
	rep	movsd
	%assign zzz 0
	%rep	7	
	mov	esi,[circles+zzz]
	mov	edi,[circles+zzz+4]
	call	rotate1
	%assign zzz zzz+4
	%endrep

	;mov	ax,SEG _circle
	;mov	ds,ax
	;xor	si,si
  mov esi, _circle
	;mov	ax,0a000h
	;mov	es,ax
	mov	cx,200
	;xor	di,di
  mov edi, _koe_planar
	mov	ebp,_koe_planar+80*399
@@10:	push	ecx
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
	mov	word [framecount],0
	ret

extern _dis_waitb
extern _dis_musrow
extern _dis_exit
extern _dis_getmframe
extern _demo_blit

_resolve_planar:
  movzx esi, word [scrnpos]
  mov edi, _shim_vram
  movzx ecx, word [scrnposl]
  mov edx, 320
  mov bl, 0x80
  shr bl, cl
  mov ecx, 320*200
  resolve_byte:
    xor al, al
    test [_koe_planar+esi+80*400*0], bl
    jz nah1
      or al, 1
    nah1:
    test [_koe_planar+esi+80*400*1], bl
    jz nah2
      or al, 2
    nah2:
    test [_koe_planar+esi+80*400*2], bl
    jz nah3
      or al, 4
    nah3:
    test [_koe_planar+esi+80*400*3], bl
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
	
	mov	si,[palanimc]
	add	si,[patdir]
	cmp	si,0
	jge	@@a11
	mov	si,8*3-3
@@a11:	cmp	si,8*3
	jb	@@a1
	xor	si,si
@@a1:	mov	[palanimc],si
	mov	[palanimc2],si

	movzx	esi,word [palanimc]
	add	esi,pal1
	xor	al,al
	mov	ecx,8*3
	call	outpal
	movzx	esi,word [palanimc]
	add	esi,pal2
	mov	al,8
	mov	ecx,8*3
	call	outpal

	PLANE 8
	;mov	ax,0a000h
	;mov	es,ax
	xor	esi,esi
	movzx edi, word [scrnpos]
  add edi, _koe_planar+80 * 400 * 3
  movzx ebp, word [sinurot]
	add	ebp,7*2
	and	ebp,2047
	mov	[sinurot],bp
	mov	ecx,200
@@cp1:
  %assign zzz 0
	push	esi
	add	ebp,9*2
	and	ebp,2047
	movsx	ebx,word [_koe_sin1024+ebp]
	sar	ebx,3
	mov	bh,[sinuspower]
  and ebx, 0xFFFF
	movsx	eax,byte [power0+ebx]
  movzx ebx, word [overx]
  add	eax, ebx
  movzx ebx, word [scrnposl]
  sub	eax, ebx
	mov	ebx, eax
	and	ebx,7
  shl ebx,2
  neg ebx
  add esi,[circles+ebx+7*4]
	sar	eax,3
	add	esi,eax
  movzx eax,word [overya]
	add	esi,eax
	%rep	40/4+1
	mov	eax,[esi+zzz]
	mov	[edi+zzz],eax
	%assign zzz zzz+4
	%endrep
	pop	esi
	add	edi,80
	add	esi,80
	dec	ecx
	jz	@@cp0
	jmp	@@cp1
@@cp0:
	;MOVE

	mov	bx,6
	;int	0fch
  call _dis_musrow
  mov bx,ax
	;bx=row
	and	bx,7
	cmp	bx,0
	jne	@@m1
	mov	word [patdir],-3
@@m1:	cmp	bx,4
	jne	@@m2
	mov	word [patdir],-3 ;-3
@@m2:
	movzx	ebx, word [scrnrot]
	add	bx,5
	and	bx,1023
	mov	[scrnrot],bx

	shl	bx,1
	mov	ax,[_koe_sin1024+ebx]
	sar	ax,2
	add	ax,160
	mov	[scrnx],ax
	add	bx,256*2
	and	bx,1024*2-1
	mov	ax,[_koe_sin1024+ebx]
	sar	ax,2
	add	ax,100
	mov	[scrny],ax

	movzx	ebx,word [overrot]
	add	bx,7
	and	bx,1023
	mov	[overrot],bx

	shl	bx,1
	mov	ax,[_koe_sin1024+ebx]
	sar	ax,2
	add	ax,160
	mov	[overx],ax
	add	bx,256*2
	and	bx,1024*2-1
	mov	ax,[_koe_sin1024+ebx]
	sar	ax,2
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

	cmp	word [framecount],70*5
	jb	@@p1	
	inc	byte [powercnt]
	cmp	byte [powercnt],16
	jb	@@p1
	mov	byte [powercnt],0
	cmp	word [sinuspower],15
	jae	@@p1
	inc	word [sinuspower]
@@p1:
	inc	word [framecount]
	;cmp	[framecount],70*13
	;je	@@xx
  call _resolve_planar
  call _demo_blit
 	mov	ax,0
	mov	bx,9
	;int	0fch
  call _dis_getmframe
	cmp	eax,925
	jae	@@xx
	mov	bx,2
	;int	0fch
  call _dis_exit
	or	ax,ax
	jz	@@aga
@@xx:	ret


global _initinterference
_initinterference:
	push	ebp
	;mov	bp,sp
	;push	si
	;push	di
	;push	ds
	
;	call	resetmode13

;@@wm1:	mov	bx,2
;	int	0fch
;	or	ax,ax
;	jnz	@@xit
;	mov	bx,6
;	mov	ax,0f1h
;	int	0fch
;	cmp	ax,0f1h
;	jne	@@wm1
	mov eax, [esp+8]
	call	init_interference
	
	;pop	ds
	;pop	di
	;pop	si
	pop	ebp
	ret


global _dointerference
_dointerference:
	push	ebp
	;mov	bp,sp
	;push	si
	;push	di
	;push	ds
	
	call	do_interference	
	
	;mov	es,[memseg]
	;mov	ah,49h
	;int	21h

	;pop	ds
	;pop	di
	;pop	si
	pop	ebp
	ret

	
;global _inittwk
;_inittwk:
;	push	bp
;	mov	bp,sp
;	push	si
;	push	di
;	push	ds
;	;clear palette
;	mov	dx,3c8h
;	xor	al,al
;	out	dx,al
;	inc	dx
;	mov	cx,768
;@@1:	out	dx,al
;	loop	@@1
;	;400 rows
;	mov	dx,3d4h
;	mov	ax,00009h
;	out	dx,ax
;	;tweak
;	mov	dx,3d4h
;	mov	ax,00014h
;	out	dx,ax
;	mov	ax,0e317h
;	out	dx,ax
;	mov	dx,3c4h
;	mov	ax,0604h
;	out	dx,ax
;	;
;	mov	dx,3c4h
;	mov	ax,0f02h
;	out	dx,ax
;	mov	ax,0a000h
;	mov	es,ax
;	xor	di,di
;	mov	cx,32768
;	xor	ax,ax
;	rep	stosw
;	;
;	pop	ds
;	pop	di
;	pop	si
;	pop	bp
;	ret


global _koe_lineblit
_koe_lineblit:
	push	bp
	mov	bp,sp
	push	si
	push	di
	push	ds
	mov	di,[bp+6]
	mov	es,[bp+8]
	mov	si,[bp+10]
	mov	ds,[bp+12]
	%assign zpl 0
	%rep	4
	mov	dx,3c4h
	mov	ax,02h+(100h << zpl)
	out	dx,ax
	%assign zzz 0
	%rep 80/2
	mov	al,[esi+(zzz+0)*4+zpl]
	mov	ah,[esi+(zzz+1)*4+zpl]
	mov	[edi+zzz],ax
	%assign zzz zzz+2
	%endrep
	%assign zpl zpl+1
	%endrep
	pop	ds
	pop	di
	pop	si
	pop	bp
	ret


;global _setpalarea
;_setpalarea:
;	push	bp
;	mov	bp,sp
;	push	si
;	push	di
;	push	ds
;	mov	si,[bp+6]
;	mov	ds,[bp+8]
;	mov	ax,[bp+10]
;	mov	dx,3c8h
;	out	dx,al
;	inc	dx
;	mov	cx,[bp+12]
;	shl	cx,1
;	add	cx,ax
;	REPOUTSB
;	pop	ds
;	pop	di
;	pop	si
;	pop	bp
;	ret
