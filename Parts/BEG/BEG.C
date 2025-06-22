#include <stdio.h>
#include <memory.h>
#include "..\common.h"
#include "..\dis\dis.h"
#include "..\..\shims.h"

extern char beg_pic[];

//char *vram=(char *)0xa0000000L;
#define vram shim_vram

char	pal2[768];
char	palette[768];
char	rowbuf[640];

void beg_main()
{
	int	a,b,c,y;
	dis_partstart();
// 	outp(0x3c4,2);
// 	outp(0x3c5,15);
	//memset(vram,15,32768);
	//memset(vram+32768,15,32768);
	//_asm mov ax,80h+13h
	//_asm int 10h
	for(a=0;a<32;a++) dis_waitb();
	shim_outp(0x3c8,0);
	for(a=0;a<255;a++)
	{
		shim_outp(0x3c9,63);
		shim_outp(0x3c9,63);
		shim_outp(0x3c9,63);
	}
	shim_outp(0x3c9,0);
	shim_outp(0x3c9,0);
	shim_outp(0x3c9,0);
//	shim_inp(0x3da);
//	shim_outp(0x3c0,0x11);
//	shim_outp(0x3c0,255);
//	shim_outp(0x3c0,0x20);
	//inittwk();
  /*
	_asm
	{
		mov	dx,3d4h
		mov	ax,000ch
		out	dx,ax
		mov	ax,000dh
		out	dx,ax
		mov	al,9
		out	dx,al
		inc	dx
		in	al,dx
		and	al,not 80h
		and	al,not 31
		out	dx,al
		mov	dx,3c0h
		mov	al,11h
		out	dx,al
		mov	al,0
		out	dx,al
		mov	al,32
		out	dx,al
	}
	_asm
	{
		mov	dx,3c0h
		mov	al,11h
		out	dx,al
		mov	al,255
		out	dx,al
		mov	al,20h
		out	dx,al
	}
  */

	readp(palette,-1,beg_pic);
	for(y=0;y<400;y++)
	{
		readp(vram+(unsigned)y*320U,y,beg_pic);
		//lineblit(vram+(unsigned)y*320U,rowbuf);
	}

  //shim_vram[ 66 * 320 ] = 31;
  for ( c = 0; c <= 128; c++ )
	{
		for(a=0;a<768-3;a++) pal2[a]=((128-c)*63+palette[a]*c)/128;
		dis_waitb();
		setpalarea(pal2,0,254);
    demo_blit();
	}
  //for(int i=0; i<5000; i++)dis_waitb();
	setpalarea(palette,0,254);
}
