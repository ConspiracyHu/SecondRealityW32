mov ax, 13
int 10h

mov	dx,0x3da
in	al,dx

; palette registers
mov	dx,0x3c0
xor	al,al
%rep 16
out	dx,al ; index
out	dx,al ; data
inc	al
%endrep

; overscan
mov	al,11h
out	dx,al
mov	al,255
out	dx,al

mov	al,32
out	dx,al
  
mov	dx,0x3c8
xor	al,al
out	dx,al
inc	dx

%macro RGB 3
mov	al,%1
out	dx,al
mov	al,%2
out	dx,al
mov	al,%3
out	dx,al
%endmacro

RGB  0, 0, 0
RGB 63, 0, 0
RGB  0,63, 0
RGB  0, 0,63
RGB 63,63, 0
RGB  0,63,63
RGB 63, 0,63
RGB 63,63,63

RGB 16,16,16
RGB 32, 0, 0
RGB  0,32, 0
RGB  0, 0,32
RGB 32,32, 0
RGB  0,32,32
RGB 32, 0,32
RGB 32,32,32

%macro SETPLANE 1
	mov dx,0x3c4
	mov ax,0x0002 | (%1 << 8)
  out dx,ax
%endmacro

%macro SETPAGE 1
	mov dx,0x3d4
	mov ax,0x000C | (%1 << 8)
  out dx,ax
%endmacro

%macro SETVIDMEM 1
  push 0xA000 + (%1 << 8)
  pop es
%endmacro

%macro SETVIDMEMSTART 1 ; in bytes, not pixels!
  mov	dx,0x3d4
  mov	ax,0x000c | (%1 & 0xFF00)
  out	dx,ax
  mov	ax,0x000d | ((%1 & 0xFF) << 8)
  out	dx,ax
%endmacro

%macro SETVIDMEMSTRIDE 1
  mov	dx,0x3d4
  mov	ax,0x0013 | ((%1 & 0xFF) << 8)
  out	dx,ax
%endmacro

ide:

  mov dx,0x3da
@@1:
  in al,dx
  test al,8
  jnz @@1
@@2: 
  in al,dx
  test al,8
  jz @@2

  SETPAGE 0x00
  SETVIDMEM 0x00
  SETPLANE 0x01
  
  SETVIDMEMSTART 0
  ;SETVIDMEMSTRIDE 20 ; 320, 16 col
  SETVIDMEMSTRIDE 0x28 ; 320, 16 col
 
  mov byte [es:di+40], 0x55
 
  xor di, di
  %assign N 0
  %rep 40
  mov byte [es:di+0x00+N], 0x55
  mov byte [es:di+0x01+N], 0xFE
  mov byte [es:di+0x02+N], 0xFE
  mov byte [es:di+0x03+N], 0x3C
  %assign N N+4
  %endrep
  
;  mov cx, 40
;  mov al, 0x55
;  rep stosb
;  
;  mov di, 80
;  mov al, 0xAA
;  stosb
;  
;  mov di, 120
;  mov al, 0xf1
;  stosb
  
;  xor di, di
;  mov al, 1
;  stosb
;  
;  mov di, 40
;  mov al, 2
;  stosb
;
;  mov di, 80
;  mov al, 0xF
;  stosb
;
;  SETPLANE 0x02
;
;  mov di, 20
;  mov al, 0xFF
;  stosb
;    
;  mov di, 80
;  mov al, 0x55
;  stosb
;
;  SETPAGE 0x20
;  SETVIDMEM 0x02
;  SETPLANE 0x01
;
;  mov di, 0
;  mov al, 0x5A
;  stosb
;
;  SETPAGE 0x40
;  SETVIDMEM 0x04
;
;  mov di, 0
;  mov al, 0xC1
;  stosb

  in al,0x60
  cmp al,1
jnz ide

mov ax,3
int 0x10

ret