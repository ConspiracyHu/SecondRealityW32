{$asmMode intel}

unit tun10;

interface

procedure tun_main; cdecl;

implementation

uses crt;

const veke = 1060;    { frame count to exit }

type
      bc     = record
                 x : integer;
                 y : integer;
               end;
      ptr_bc = ^bc;

      rengas = record
                 x,y   : integer;
                 c     : byte;
               end;

var
      putki  : array[0..102] of rengas;
      pcalc  : array[0..137,0..63] of bc;

      aa1    : array[0..100] of word;
      rows   : array[0..200] of word;
      aa2    : array[0..200] of word;

      sinit  : array[0..4096] of word;
      cosit  : array[0..2048] of word;
      sade   : array[0..102] of word;
      shim_vram: array[0..64000] of byte; external name '_shim_vram';
      tun: array[0..17664] of word; external name '_tunnel_tun';
      sini: array[0..6146] of word; external name '_tunnel_sini';
      cosptr: ^word;
      frame  : word;
      bor    : byte;
      frames : word;
      oldpos : array[0..7500] of word;
      _bx,by : word;
      bbc   : byte;
      ry     : word;

      {
procedure tun;external;
procedure sini;external;
}

{$I ..\DIS\DISPAS.INC}

procedure move(src:pointer; dst:pointer; count:sizeint);
begin
  memcpy(dst, src, count);
end;

procedure setrgb(c,r,g,b:byte);
begin
    shim_setpal(c,r,g,b);
{
     port[$3c8] := c;
     port[$3c9] := r;
     port[$3c9] := g;
     port[$3c9] := b;
     }
end;

procedure waitr;
begin
{
        setrgb(0,0,0,0);
        
        asm
	mov	bx,1
	int	0fch
        mov     frames,ax
        end;
        if mem[$40:$17] and 16 = 16 then setrgb(0,0,0,15);
        }
        frames := dis_waitb;
end;

{
function dis_exit:boolean;
var   a : byte;
begin
        asm
	mov	bx,2
	int	0fch
        mov     a,al
        end;
        if a = 0 then dis_exit := false else dis_exit := true;
end;
}

procedure tun_main; cdecl; [Alias:'_tun_main'];

var  op     : word;

var  x,y,z : integer;
     x1,y1 : word;
     a   : word;
     f   : file;

     sx,sy : word;
     br    : byte;
     pcp   : ptr_bc;
     pc    : byte;
     mx,my : integer;
     addi,yvalue : word;
     ch          : char;
     oo          : word;
     flip        : byte;
     quit        : boolean;
     sync        : word;

label poies;
begin

    x := 0;y := 0;z := 0;x1 := 0;y1 := 0;a := 0;sx := 0;sy := 0;

    quit := false;

{    fillchar(oldpos,sizeof(oldpos),#0);}

    for x := 0 to 100 do aa1[x] := 64000;
    move(@aa1[0],@aa2[0],sizeof(aa1));
    for x := 0 to 200 do rows[x] := x*320;
    move(@sini[0],@sinit[0],4097*2);
    cosptr := @sini[4097];
    move(@cosptr[0],@cosit[0],2048*2);
    move(@tun[0],@pcalc[0],sizeof(pcalc));

{
    for x := 0 to 4096 do Sinit[x] := round(sin((x)/128*pi)*((x*3) div 16));
    for x := 0 to 2048 do Cosit[x] := round(cos((x)/256*pi)*((x*4) div 32));
}
{
    asm
        mov  ax,$13
        int  $10

	xor	bx,bx
	int	0fch
    end;
    }
{
    for x := 0 to 64 do setrgb(64+x,(64-x) *4 div 7,(64-x) * 2 div 3,64-x);
    for x := 0 to 64 do setrgb(128+x,(64-x) div 3,(64-x) div 2,(64-x) * 2 div 3);
}
    for x := 0 to 64 do setrgb(64+x ,(64-x),(64-x),(64-x));
    for x := 0 to 64 do setrgb(128+x,(64-x) *3 div 4,(64-x) *3 div 4,(64-x) *3 div 4);

    setrgb(68,0,0,0);
    setrgb(132,0,0,0);


    setrgb(255,0,63,0);

    for x := 0 to 100 do
     begin
      putki[x].x := 0;
      putki[x].y := 0;
      putki[x].c := 0;
     end;

  sx := 0;
  sy := 0;

  pc := 60;
  addi := 40;
  flip := 0;
  bor := 0;
  frame := 0;
  quit := false;

  waitr;
  for Z := 0 to 100 do sade[z] := round(16384 div ((Z*7)+95));

  repeat
    waitr;
    ry := 0;
    for x := 80 downto 4 do
     begin
     _bx := putki[x].x-putki[5].x;
      by := putki[x].y-putki[5].y;
      br := sade[x];
      bbc := putki[x].c+round(x / 1.3);
      pcp := @pcalc[br][0];

      if bbc >= 64 then
       asm
       {
        mov    ax,$a000
        mov    es,ax
        }
        mov      esi,pcp
        movzx    edx,word [_bx]
        movzx    eax,byte [bbc]
        mov    byte [@c+6],al

        mov    ecx,64
        movzx  eax, word [RY]

        push   ebp
        movzx  ebp, word [BY]
@a:     mov    ebx,eax
        movzx  edi,word [oldpos+ebx]
        mov    byte ptr [shim_vram+edi],0

        movzx  edi,word ptr [esi]
        add    edi,edx
        cmp    edi,319
        ja     @yli
        mov    ebx,ebp
        add    bx,word ptr [esi+2]
        add    ebx,ebx
        add    di,word ptr [rows+ebx]
@c:     mov    byte ptr [shim_vram+edi],15
@yli:
        mov    ebx,eax
        mov    word ptr [oldpos+ebx],di
        add    esi,4
        add    eax,2
        dec    ecx
        jnz    @a
        pop    ebp
        mov    [RY],ax
       end['esi','eax','ebx','ecx'];
     end;

     for sync := 1 to frames do
     begin
     putki[100].x := cosit[sy and 2047]-sinit[sy*3 and 4095]-cosit[sx and 2047];
     putki[100].y := sinit[sx*2 and 4095]-cosit[sx and 2047]+sinit[y and 4095];
     memcpy(@putki[0],@putki[1],ofs(putki[100])-ofs(putki[0]));
     inc(sy);
     inc(sx);

{
     asm
     mov   ax,0
     mov   bx,6
     int   0fch
     cmp   ax,-4
     jnz   @a
     mov   quit,1
@a:
     end;
}
     if dis_muscode(0)=-4 then quit:=true;

     if (sy and 15) > 7 then putki[99].c := 128 else putki[99].c := 64;
     if frame >= veke-102 then putki[99].c := 0;
     if frame = veke then quit := true else inc(frame);
{     inc(frame);}
     if dis_exit then quit := true;
     if quit then goto poies;
     end;
     demo_blit;
poies:
  until quit;
end;

exports tun_main;

end.