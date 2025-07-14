;EXTRN C l1:word, C l2:word, C l3:word, C l4:word, C k1:word, C k2:word, C k3:word, C k4:word
;EXTRN C m1:word, C m2:word, C m3:word, C m4:word, C n1:word, C n2:word, C n3:word, C n4:word

segment .data
global psini
psini:
%include 'psini.inc'
;       db      16384 dup(?)

global lsini4
lsini4:
%include 'lsini4.inc'
;       db      16384 dup(?)

global lsini16
lsini16:
%include 'lsini16.inc'
;       db      16384 dup(?)

segment .code

%define LC_OFS(x) x %+ _ %+ ccc

global _plzline
_plzline:
        push ebp
        mov ebp, esp
        push esi
        push edi
        push ebx

        ;ARG     y1:word, vseg:word
        %define y1 ebp+8
        %define vseg ebp+12
        ;push    ds es si di

        mov ecx, [vseg]
        ;push    [esp+12]
        ;pop     es
        ;push    cs
        ;pop     ds
        ;mov     si, [esp+8]
        mov esi, [y1]
;       and     si, 0fffeh
        shl esi, 1
        mov edi, esi
        xor eax, eax
        xor ebx, ebx

        ;IRP ccc, <3,2,1,0,7,6,5,4,11,10,9,8,15,14,13,12,19,18,17,16,23,22,21,20,27,26,25,24,31,30,29,28,35,34,33,32,39,38,37,36,43,42,41,40,47,46,45,44,51,50,49,48,55,54,53,52,59,58,57,56,63,62,61,60,67,66,65,64,71,70,69,68,75,74,73,72,79,78,77,76,83,82,81,80>
        %assign ccc_inc 0
        %rep 84
        %assign ccc (ccc_inc&(~3)) + 3-(ccc_inc&3)

%if (ccc & 1) == 1
LC_OFS(lc2) equ $+3
        mov     bx, [esi+1234h]
LC_OFS(lc1) equ $+2
        mov     ah, [ccc*32 + ebx + 1234h]
LC_OFS(lc4) equ $+3
        mov     bx, [ccc*64 + edi + 1234h]
LC_OFS(lc3) equ $+3
        add     ah, [ebx + edi + 1234h]
%else
LC_OFS(lc2) equ $+3
        mov     bx, [esi+1234h]
LC_OFS(lc1) equ $+2
        mov     al, [ccc*32 + ebx + 1234h]
LC_OFS(lc4) equ $+3
        mov     bx, [ccc*64 + edi + 1234h]
LC_OFS(lc3) equ $+3
        add     al, [ebx + edi + 1234h]
%endif
%if (ccc & 3) == 2
        shl     eax, 16
%endif
%if (ccc & 3) == 0
        mov     [ecx + ccc], eax
%endif
        %assign ccc_inc ccc_inc+1
        %endrep
        pop ebx
        pop edi
        pop esi
        pop ebp
        ret
ENDP

global _setplzparas
_setplzparas:
        ;ARG     c1:word, c2:word, c3:word, c4:word
  %define c1 esp+8
  %define c2 esp+12
  %define c3 esp+16
  %define c4 esp+20

  push ebp

  %assign ccc 0
  %rep 84

  movzx   eax, word [c1]
  add     eax, psini+ccc*8
  mov     [LC_OFS(lc1)], eax
  movzx   eax, word [c2]
  shl     eax, 1
  add     eax, lsini16-ccc*8+80*8
  mov     [LC_OFS(lc2)], eax

  movzx   eax, word [c3]
  add     eax, psini-ccc*4+80*4
  mov     [LC_OFS(lc3)], eax
  movzx   eax, word [c4]
  shl     eax, 1
  add     eax, lsini4+ccc*32
  mov     [LC_OFS(lc4)], eax

  %assign ccc ccc+1
	%endrep

  pop ebp

	ret

global _set_plzstart
_set_plzstart:

	;ARG	start:word
  push ebp
	mov	dx, 3d4h
	mov	al, 18h		; linecompare
	mov	ah, [esp+8]
	;out	dx, ax
	mov	al, 07h
	mov	ah, [esp+9]
	shl	ah, 4
	and	ah, 10h
	or	ah, 0fh
	;out	dx, ax			; 8th bit

  pop ebp
	ret
