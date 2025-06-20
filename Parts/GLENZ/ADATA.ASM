section .data

global newdata1
newdata1 times 0fff0h db 0

global background,_background
_background:
background times 0fff0h db 0

global rows
rows	times 512 dw	0

global wminx,wminy,wmaxx,wmaxy
wminx	dw	0
wminy	dw	0
wmaxx	dw	100
wmaxy	dw	100

global video,vram,rowsadd,framerate10,truevram,truerowsadd
video	times	16 dd 0 ;far offsets to vid routines
vram	dw	0
rowsadd	dw	0
framerate10 dw	0
truevram dw	0
truerowsadd dw	0

;ALIGN 4
global projxmul,projymul,projxadd,projyadd,projminz,projminzshr
projxmul dd	0
projymul dd	0
projxadd dw	0
projyadd dw	0
projminz dd	0
projminzshr dw	0

global color,color1,color2
color:
color1	db	0
color2	db	0

;ALIGN 4
global _xadd,_yadd,_zadd
_xadd	dd	0
_yadd	dd	0
_zadd	dd	0

;ALIGN 16 ;TEMPORARY WORK AREA FOR:
global borders
borders: ;polygon drawing
	times 8192  db	0
workoverflow dw 00fch
