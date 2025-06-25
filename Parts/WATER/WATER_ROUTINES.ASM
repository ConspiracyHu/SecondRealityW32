section .code

          ;  dx = Bground seg
          ;  ax = pos seg
          ;  si = pos ofs
          ;  cx = font seg
          ;  bx = font ofs
          ;  Front scroll

extern _shim_vram
extern _water_tausta
extern _water_miekka

global Putrouts1
Putrouts1:
          ;push  ds
          ;mov   ds,ax
          ;mov   ax,0a000h
          ;mov   es,ax
          ;mov   fs,cx
          ;mov   gs,dx

          mov   edx,158*34
@a1:      lodsw
          or    ax,ax
          je    @no1
          movzx ecx,ax
@b1:      lodsw
          movzx edi,ax
          mov   al,byte [ebx]
          or    al,al
          jne   @y
          mov   al,byte [_water_tausta+edi]
@y:       mov   byte [_shim_vram+edi],al
          loop  @b1
@no1:     inc   ebx
          dec   edx
          jnz   @a1

          ;pop   ds
          ret
