section .code
          ; dx = Bground seg
          ;  ax = pos seg
          ;  si = pos ofs
          ;  cx = font seg
          ;  bx = font ofs

extern _shim_vram
extern _forest_hback

global Putrouts
Putrouts:

          ;push   ds
          ;mov    ds,ax
          ;mov    ax,0a000h
          ;mov    es,ax
          ;mov    fs,cx
          ;mov    gs,dx

          mov    edx,237*31
@a:       lodsw                        ; get byte count
          or     ax,ax                 ; if 0 then hidden pixel
          je     @ei                   ; next pixel
          movzx  ecx,ax                 ; set loop value
@c:       lodsw                        ; get destination address
          movzx  edi,ax
          mov    al,[_forest_hback+edi]   ; get bground pixel
          add    al,[ebx]   ; add font value to pixel
          mov    [_shim_vram+edi],al   ; store pixel to screen
          loop   @c
@ei:
          inc    ebx
          dec    edx
          jnz    @a
          ;pop    ds

          ret
