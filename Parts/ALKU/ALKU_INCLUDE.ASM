section .data

global _hzpic
_hzpic:
%include 'hoi.in0'
%include 'hoi.in1'

global _font
_font:
%include 'fona.inc'

times 1500*5 dw 0