{$asmMode intel}

unit demo;

interface

procedure water_main; cdecl;

implementation

uses crt;

{$I ..\DIS\DISPAS.INC}

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

var  frames : word;
      wat1: array[0..23096] of byte; external name '_water_wat1';
      wat2: array[0..23034] of byte; external name '_water_wat2';
      wat3: array[0..27818] of byte; external name '_water_wat3';
      tausta: array[0..64778] of byte; external name '_water_tausta';
      miekka: array[0..14778] of byte; external name '_water_miekka';
      shim_vram: array[0..64000] of byte; external name '_shim_vram';

procedure waitr;
begin
{
        asm
	mov	bx,1
	int	0fch
        mov     frames,ax
        end;
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

var   f : file;
      inx : word;
      y,x,t   : word;
      tmppal,pal    : array[0..768] of byte;
      font   : array[0..400*35] of byte;
      fbuf   : array[0..158*34] of byte;
      scp,sss:word;

{$L routines.obj}
          { dx = Bground seg,
            ax = pos seg,
            si = pos ofs,
            cx = font seg,
            bx = font ofs }

procedure putrouts1;external name 'Putrouts1';

procedure move(src:pointer; dst:pointer; count:sizeint);
begin
  memcpy(dst, src, count);
end;

procedure fillchar(dst:pointer; count:sizeint; val:char);
begin
  memset(dst, byte(val), count);
end;

procedure scr(pos:byte);
begin
  case pos of

   0:asm
      mov   esi,offset wat1
      mov   ebx,offset fbuf
      call  putrouts1
     end ['esi','ebx'];
   1:asm
      mov   esi,offset wat2
      mov   ebx,offset fbuf
      call  putrouts1
     end ['esi','ebx'];
   2:asm
      mov   esi,offset wat3
      mov   ebx,offset fbuf
      call  putrouts1
     end ['esi','ebx'];
  end;
end;

procedure water_main; cdecl; [Alias:'_water_main'];

var   frame   : word;
      co      : word;
      fadeout : boolean;
      quit    : word;
      fp      : word;
      pf      : word;
begin
{
     asm
     mov   ax,$13
     int   $10

     xor   bx,bx
     int   0fch


@a:  mov   ax,0
     mov   bx,6
     int   0fch
     cmp   dx,0
     jl    @a
     mov   co,cx

     end;
     }
     co := dis_musorder(0);

     fillchar(@fbuf[0],sizeof(fbuf),#0);
     move(@miekka[10],@pal[0],768);
     move(@miekka[778],@font[0],400*34);

     for x := 0 to 255 do setrgb(x,0,0,0);
     move(@tausta[778],@tausta[0],64000);
     move(@tausta[0],@shim_vram[0],64000);

     move(@pal[0],@tmppal[0],768);
     fillchar(@pal[0],768,#0);
     for y := 0 to 63*2 do
      begin
        waitr;
        if y and 1 = 1 then
        begin
        for x := 0 to 255 do
         begin
          setrgb(x,pal[x*3+0],pal[x*3+1],pal[x*3+2]);
          for pf := 0 to 3 do if pal[x*3+pf] < tmppal[x*3+pf] then inc(pal[x*3+pf]);
         end;
        end;

        scr(sss);
        if sss = 2 then sss := 0 else inc(sss);
        demo_blit;
      end;

      {
     asm
@a:  mov   ax,0
     mov   bx,6
     int   0fch
     cmp   cx,CO
     je    @a
     cmp   bx,16
     jl    @a
     end;
     }
     repeat
       demo_blit;
     until not ((dis_musorder(0) = co) or (dis_musrow(0) < 16));


    {######################################################################}

    sss := 0;
    scp  := 0;
    frame := 0;
    quit  := 0;
    fp := 0;
    fadeout := false;
    fillchar(@tmppal[0],768,#0);
    repeat
      waitr;
      {
     asm
     mov   ax,0
     mov   bx,6
     int   0fch
     cmp   dx,-11
     jnz   @a
     mov   fadeout,1
@a:  end;
}
      if dis_musplus(0)=-11 then fadeout:=true;

      if fadeout then
        begin
        if fp = 64 then quit := 1 else inc(fp);
        for x := 0 to 255 do
         begin
          setrgb(x,pal[x*3+0],pal[x*3+1],pal[x*3+2]);
          for pf := 0 to 3 do if pal[x*3+pf] > tmppal[x*3+pf] then dec(pal[x*3+pf]);
         end;
        end;


      scr(sss);
      if sss = 2 then
       begin
        sss := 0;
        move(@fbuf[1],@fbuf[0],sizeof(fbuf));
        for x := 0 to 33 do fbuf[158+x*158] := font[x*400+scp];
        if scp < 390 then inc(scp);
       end else inc(sss);

       demo_blit;
     until dis_exit or (quit = 1);
end;

exports water_main;

end.