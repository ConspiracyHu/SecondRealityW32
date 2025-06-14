section .data

global _pam_memblock
_pam_memblock:
%include 'out.in0'
%include 'out.in1'
%include 'out.in2'
%include 'out.in3'
%include 'out.in4'

global _pam_pal
_pam_pal:
%include 'pal.inc'
