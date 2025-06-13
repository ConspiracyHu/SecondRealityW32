section .data

global _lensexb
_lensexb:
incbin "lens.exb"

; according to LENS\MAKEFILE:
; "after lensexb, there must be 4K of data (filler) for 64K overflow"

times 4096 db 0

global _lensex1
_lensex1:
incbin "lens.ex1"

global _lensex0
_lensex0:
incbin "lens.ex0"

global _lensex2
_lensex2:
incbin "lens.ex2"

global _lensex3
_lensex3:
incbin "lens.ex3"

global _lensex4
_lensex4:
incbin "lens.ex4"

global _lensexp
_lensexp:
incbin "lens.exp"

