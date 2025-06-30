section .bss

global _kuva1
_kuva1:
	resb	16384

global _dist1
_dist1:
	resw	16384 

global _kuva2
_kuva2:
	resb	16384 

global _kuva3
_kuva3:
	resb	16384 

section .data
%include 'sinit.inc'
