#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <conio.h>
#include <fcntl.h>
#include <dos.h>
#include <math.h>
#include "..\dis\dis.h"
#include "..\..\shims.h"
#include "..\COMMON.H"

/*
extern void tw_opengraph();
extern void tw_closegraph();
extern void tw_putpixel(int x, int y, int color);
extern int  tw_getpixel(int x, int y);
extern void tw_setpalette(void far *pal);
extern void tw_setpalarea(void far *pal,int start,int cnt);
extern void tw_setrgbpalette(int pal, int r, int g, int b);
extern void tw_setstart(int start);
extern void tw_pictovmem(void far *pic, int to, int len);
extern void tw_crlscr();
*/

#define	_LOADER_

void copyline(char *from, char *to, int count);
void shutdown();

#ifndef _LOADER_CALLS
char	kuva[65000];
#endif
char	kuvapal[768];
char	pal[768];
char	fadepals[64][768];

#define tw_getpixel(x,y) shim_vram[(x)+(y)*320]
#define tw_putpixel(x,y,c) shim_vram[(x)+(y)*320]=(c)
#define tw_setpalette(p) setpal(p)
#define tw_setrgbpalette(p,r,g,b) shim_setpal(p,r,g,b)
#define tw_setstart(p)

void shutdown_main()  {
	int	x,y;
  FILE * fff;

	//dis_partstart();

#ifndef _LOADER_
	//tw_opengraph();
	//tw_setstart(80);
	fff=fopen("monster.u","rb");
	fread(kuva,1,64000,fff);
	fclose(fff);
	fff=fopen("monster.pal","rb");
	fread(kuvapal,1,768,fff);
	fclose(fff);

	for(y=0;y<200;y++) for(x=0;x<320;x++)
		{
		tw_putpixel(x+320,y*2,255-kuva[y*320+x]);
		tw_putpixel(x+320,y*2+1,255-kuva[y*320+x]);
		}
	tw_setpalette(kuvapal);
#else
  if ( demo_isfirstpart() )
  {
    char pic[ 80000 ];
    FILE * h = fopen( "Data\\troll.up", "rb" );
    fread( pic, 80000, 1, h );
    fclose( h );
    readp( kuvapal, -1, pic );
    setpal( kuvapal );
    for ( int y = 0; y < 400; y++ )
    {
      readp( shim_vram + y * 320, y, pic );
    }
  }
  getpal(kuvapal);
#endif

	shutdown();
	}

void shutdown()
	{
	int	x,y,a,b;

	for(a=0;a<320;a++) tw_putpixel(a,0,0);
	for(a=0;a<64;a++) for(b=3;b<768;b++) fadepals[a][b]=(a*63+kuvapal[b]*(64-a))/64;
	for(y=0;y<100;y++) for(x=0;x<320;x++)
		tw_putpixel(x,y+50,tw_getpixel(x+320,y*4));
  memset(shim_vram,0,320*50);
  memset(shim_vram+320*150,0,320*50);
	//tw_setstart(100*160);
  /*
	dis_waitb();
	asm {
		mov	dx, 3d4h
		mov	ax, 4109h
		out	dx, ax      // max scanline

		mov	dx, 03ceh
		mov	ax, 4105h
		out	dx, ax			// latch transfer mode

		mov	dx, 03c4h
		mov	ax, 0f02h		// map mask 1111
		out	dx, ax
		}
    */
	tw_setpalette(fadepals[3]);
	tw_setrgbpalette(0,63,63,63);
	tw_setstart(0);
	dis_waitb();
  demo_blit();
	//dis_waitb();
	tw_setpalette(fadepals[20]);
  /*
	asm {
		mov	dx, 3d4h
		mov	ax, 0a013h
		out	dx, ax      // offset register
		}
    */
	for(a=32;a>2;a=a*5/6)
		{
		dis_waitb();
		tw_setpalette(fadepals[63-a]);
    for(b=a/2;b<=a;b++)
			{
			copyline(shim_vram,shim_vram+100*320-(b*320),80);
			copyline(shim_vram,shim_vram+100*320+(b*320),80);
			}
		for(b=0;b<a;b++)
			copyline( shim_vram+320+(400*b/a)*320, shim_vram+100*320+(b-a/2)*320,80);
    demo_blit();
		}

	copyline(shim_vram,shim_vram+101*320,80);
	copyline(shim_vram,shim_vram+ 99*320,80);
  /*
	asm {
		mov	dx, 03ceh
		mov	ax, 4005h
		out	dx, ax			// latch transfer mode

		mov	dx, 03c4h
		mov	ax, 0f02h		// map mask 1111
		out	dx, ax
		}
    */

	for(x=20;x<=160;x+=3)
		{
		dis_waitb();
		tw_putpixel(x,100,0);
		tw_putpixel(320-x,100,0);
		tw_putpixel(x+1,100,0);
		tw_putpixel(319-x,100,0);
		tw_putpixel(x+2,100,0);
		tw_putpixel(318-x,100,0);
		tw_putpixel(x+3,100,0);
		tw_putpixel(317-x,100,0);
    demo_blit();
		}

	tw_putpixel(160,100,1);
	for(a=0;a<60;a++)
		{
		dis_waitb();
		b=cos(a/120.0*3*2*3.1415926535)*31.0+32;
		tw_setrgbpalette(1,b,b,b);
    demo_blit();
		}
	//sleep(1);
	}
/*
getpal(char far *pal)
	{
	asm {
		push	di
		push	es

		les	di, pal
		mov	cx, 768d
		mov	dx, 3c7h
		mov	al, 0d
		out	dx, al
		inc	dx
		inc	dx
		rep	insb

		pop	es
		pop	di
		}
	}
*/