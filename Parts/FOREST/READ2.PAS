{$asmMode intel}

unit read2;

interface

procedure forest_main; cdecl;

implementation

uses crt;

const  veke = 2800;

procedure shim_setpal(idx:integer; r:byte; g:byte; b:byte);cdecl;external;
procedure demo_blit;cdecl;external;
function dis_waitb:integer;cdecl;external;
function dis_exit_c:integer;cdecl;external name 'dis_exit';
procedure memcpy(dest:pointer; source:pointer; count: sizeint);cdecl;external;
procedure memset(dest:pointer; val:byte; count: sizeint);cdecl;external;

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
      w     : word;
      posi1: array[0..25088] of byte; external name '_forest_posi1';
      posi2: array[0..25064] of byte; external name '_forest_posi2';
      posi3: array[0..25114] of byte; external name '_forest_posi3';
      hback: array[0..64778] of byte; external name '_forest_hback';
      o2: array[0..21258] of byte; external name '_forest_o2';
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


function dis_exit:boolean;
var   a : byte;
begin
{
        asm
	mov	bx,2
	int	0fch
        mov     a,al
        end;
        if a = 0 then dis_exit := false else dis_exit := true;
        }
        if dis_exit_c = 0 then dis_exit := false else dis_exit := true;
end;

var   f : file;
      inx : word;
      y,x,t   : word;
      pal    : array[0..768] of byte;
      fbuf   : array[0..640*31] of byte;
      font   : array[0..237*31] of byte;
      fpal,tmppal : array[0..768] of byte;
      scp,sss:word;

{L routines.obj}
          { dx = Bground seg,
            ax = pos seg,
            si = pos ofs,
            cx = font seg,
            bx = font ofs }

procedure putrouts;external name 'Putrouts';

procedure move(src:pointer; dst:pointer; count:sizeint);
begin
  memcpy(dst, src, count);
end;

procedure fillchar(dst:pointer; count:sizeint; val:char);
begin
  memset(dst, byte(val), count);
end;

procedure scr(pos:byte);
var ff : word;
begin
  case pos of

   0:asm
      mov   esi,offset posi1
      mov   ebx,offset font
      call  putrouts
     end;
   1:asm
      mov   esi,offset posi2
      mov   ebx,offset font
      call  putrouts
     end;
   2:begin
      asm
       mov   esi,offset posi3
       mov   ebx,offset font
       call  putrouts
      end;
      move(@font[1],@font[0],237*31);
      for ff := 0 to 30 do font[ff*237+236] := fbuf[ff*640+scp];
      if scp < 639 then inc(scp);
     end;
  end;
end;

procedure forest_main; cdecl; [Alias:'_forest_main'];

var   frame : word;
      quit  : word;
      ch    : char;
      perse : boolean;
      fadeout : boolean;
      fp      : byte;
begin
{
     asm
     mov   ax,$13
     int   $10

     xor   bx,bx
     int   0fch

     end;
}
     {
     assign(f,'Data\o2.sci');
     reset(f,1);
     for x := 0 to 30 do
      begin
       seek(f,x*640+778);
       blockread(f,fbuf[x*640],640);
      end;
     close(f);
     }
     for x := 0 to 30 do
      begin
       move(@o2[x*640+778],@fbuf[x*640],640);
      end;

     for x := 0 to sizeof(fbuf) do if fbuf[x] > 0 then inc(fbuf[x],128);
     move(@hback[10],@pal[0],768);
     move(@hback[778],@hback[0], 64000);
     for x := 0 to 255 do setrgb(x,0,0,0);
     move(@hback,@shim_vram[0],64000);

     move(@pal[0],@tmppal[0],768);
     fillchar(@tmppal[0],32*3,#0);
     fillchar(@tmppal[128*3],32*3,#0);
     fillchar(@fpal[0],768,#0);

     w := 1;     { Wait raster routine }

     for y := 0 to 63 do
      begin
        waitr;
        for x := 0 to 255 do setrgb(x,fpal[x*3+0],fpal[x*3+1],fpal[x*3+2]);
        for x := 0 to 255 do
         begin
          if fpal[x*3+0] < tmppal[x*3+0] then inc(fpal[x*3+0]);
          if fpal[x*3+1] < tmppal[x*3+1] then inc(fpal[x*3+1]);
          if fpal[x*3+2] < tmppal[x*3+2] then inc(fpal[x*3+2]);
         end;
         demo_blit;
      end;
      
     move(@pal[0],@tmppal[0],768);
     move(@pal[0],@fpal[0],768);
     fillchar(@fpal[0],32*3,#0);
     fillchar(@fpal[128*3],32*3,#0);
     for x := 0 to 255 do setrgb(x,fpal[x*3+0],fpal[x*3+1],fpal[x*3+2]);

     for x := 0 to 30 do move(@fbuf[x*640],@font[x*237+104],133);
     scp := 133;
     
     {
     asm
@a:  mov   ax,0
     mov   bx,6
     int   0fch
     cmp   dx,0
     jl    @a
     end;
     }
{     for y := 0 to 150 do waitr;}

     sss := 0;

     for y := 0 to 63*2 do
      begin
        waitr;

        if y and 1 = 1 then
        begin
        for x := 0 to 176 do setrgb(x,fpal[x*3+0],fpal[x*3+1],fpal[x*3+2]);
        for x := 0 to 176 do
         begin
          if fpal[x*3+0] < tmppal[x*3+0] then inc(fpal[x*3+0]);
          if fpal[x*3+1] < tmppal[x*3+1] then inc(fpal[x*3+1]);
          if fpal[x*3+2] < tmppal[x*3+2] then inc(fpal[x*3+2]);
         end;
        end;

        scr(sss);
        if sss = 2 then sss := 0 else inc(sss);
        demo_blit;
      end;

    fillchar(@tmppal[0],768,#0);


    { Loppu looppi }

    frame := 0;
    w     := 0;
    ch    := #0;
    quit  := 0;
    fadeout := false;
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

      if fadeout then
        begin
        if fp = 64 then quit := 1 else inc(fp);
        for x := 0 to 255 do
         begin
          setrgb(x,fpal[x*3+0],fpal[x*3+1],fpal[x*3+2]);
          if fpal[x*3+0] > tmppal[x*3+0] then dec(fpal[x*3+0]);
          if fpal[x*3+1] > tmppal[x*3+1] then dec(fpal[x*3+1]);
          if fpal[x*3+2] > tmppal[x*3+2] then dec(fpal[x*3+2]);
         end;
        end;


     scr(sss);
     if sss = 2 then sss := 0 else inc(sss);

{     inc(frame);}
     demo_blit;

     until dis_exit or (frame = veke) or (quit = 1);
end;

exports forest_main;

end.