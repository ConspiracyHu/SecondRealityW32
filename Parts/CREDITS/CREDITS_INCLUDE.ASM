section .data

global _credits_pic1
_credits_pic1:
;%incbin "pic01.inc"

global _credits_pic2
_credits_pic2:
;%incbin "pic02.inc"

global _credits_pic3
_credits_pic3:
;%incbin "pic03.inc"

global _credits_pic4
_credits_pic4:
;%incbin "pic04.inc"

global _credits_pic5
_credits_pic5:
;%incbin "pic05.inc"

global _credits_pic5b
_credits_pic5b:
;%incbin "pic05b.inc"

global _credits_pic6
_credits_pic6:
;%incbin "pic06.inc"

global _credits_pic7
_credits_pic7:
;%incbin "pic07.inc"

global _credits_pic8
_credits_pic8:
;%incbin "pic08.inc"

global _credits_pic9
_credits_pic9:
;%incbin "pic09.inc"

global _credits_pic10
_credits_pic10:
;%incbin "pic10.inc"

global _credits_pic10b
_credits_pic10b:
;%incbin "pic10b.inc"

global _credits_pic11
_credits_pic11:
;%incbin "pic11.inc"

global _credits_pic12
_credits_pic12:
;%incbin "pic12.inc"

global _credits_pic13
_credits_pic13:
;%incbin "pic13.inc"

global _credits_pic14
_credits_pic14:
;%incbin "pic14.inc"

global _credits_pic14b
_credits_pic14b:
;%incbin "pic14b.inc"

global _credits_pic15
_credits_pic15:
;%incbin "pic15.inc"

global _credits_pic16
_credits_pic16:
;%incbin "pic16.inc"

global _credits_pic17
_credits_pic17:
;%incbin "pic17.inc"

global _credits_pic18
_credits_pic18:
;%incbin "pic18.inc"

; dummy image
times 16 db 0
%assign gray 0
%rep 256
db gray
db gray
db gray
%assign gray gray+1
%endrep
times 160*100 db 0x88

global _credits_font
_credits_font:
%include "fona.inc"
