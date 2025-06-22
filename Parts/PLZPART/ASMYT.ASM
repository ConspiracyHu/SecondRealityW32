;EXTRN C l1:word, C l2:word, C l3:word, C l4:word, C k1:word, C k2:word, C k3:word, C k4:word
;EXTRN C m1:word, C m2:word, C m3:word, C m4:word, C n1:word, C n2:word, C n3:word, C n4:word

segment .code

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

global _plzline
_plzline:
        push ebp
        ;ARG     y1:word, vseg:word

        ;push    ds es si di
        push    esi
        push    edi

        ;push    [esp+12]
        ;pop     es
        ;push    cs
        ;pop     ds
        mov     si, [esp+8]
;       and     si, 0fffeh
        shl     si, 1
	mov     di, si

  %define LC_LABEL(x) x %+ _ %+ ccc %+ :

        ;IRP ccc, <3,2,1,0,7,6,5,4,11,10,9,8,15,14,13,12,19,18,17,16,23,22,21,20,27,26,25,24,31,30,29,28,35,34,33,32,39,38,37,36,43,42,41,40,47,46,45,44,51,50,49,48,55,54,53,52,59,58,57,56,63,62,61,60,67,66,65,64,71,70,69,68,75,74,73,72,79,78,77,76,83,82,81,80>
        %assign ccc_inc 0
        %rep 84
        %assign ccc (ccc_inc&(~3)) + 3-(ccc_inc&3)

%if (ccc & 1) == 1
LC_LABEL(lc2)
        mov     bx, [esi+0c200h]
LC_LABEL(lc1)
        mov     ah, [ccc*32 + ebx + 0c100h]
LC_LABEL(lc4)
        mov     bx, [ccc*64 + edi + 0c400h]
LC_LABEL(lc3)
        add     ah, [ebx + edi + 0c300h]
%else
LC_LABEL(lc2)
        mov     bx, [esi+0c200h]
LC_LABEL(lc1)
        mov     al, [ccc*32 + ebx + 0c100h]
LC_LABEL(lc4)
        mov     bx, [ccc*64 + edi + 0c400h]
LC_LABEL(lc3)
        add     al, [ebx + edi + 0c300h]
%endif
%if (ccc & 3) == 2
        shl     eax, 16
%endif
%if (ccc & 3) == 0
        mov     [edi + ccc], eax
%endif
        %assign ccc_inc ccc_inc+1
        %endrep
        pop    edi
        pop    esi
        pop ebp
        ret
ENDP

global _setplzparas
_setplzparas:
        ;ARG     c1:word, c2:word, c3:word, c4:word
  push ebp

%define LC_OFS(x) x %+ _ %+ ccc

  %assign ccc 0
  %rep 84
        ;IRP ccc, <0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83>
        mov     ax, [esp+8]
	add     ax, psini+ccc*8
        mov     [LC_OFS(lc1)], ax
        mov     ax, [esp+12]
	shl     ax, 1
	add     ax, lsini16-ccc*8+80*8
	mov     [LC_OFS(lc2)], ax
	mov     ax, [esp+16]
	add     ax, psini-ccc*4+80*4
	mov     [LC_OFS(lc3)], ax
	mov     ax, [esp+20]
	shl     ax, 1
	add     ax, lsini4+ccc*32
	mov     [LC_OFS(lc4)], ax

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
