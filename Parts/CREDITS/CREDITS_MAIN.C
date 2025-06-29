#include <conio.h>
#include <memory.h>
#include "..\dis\dis.h"
#include "..\common.h"
#include "..\..\shims.h"

char *credits_prtc(int x,int y,char *txt);

extern char credits_pic1[];
extern char credits_pic2[];
extern char credits_pic3[];
extern char credits_pic4[];
extern char credits_pic5[];
extern char credits_pic5b[];
extern char credits_pic6[];
extern char credits_pic7[];
extern char credits_pic8[];
extern char credits_pic9[];
extern char credits_pic10[];
extern char credits_pic10b[];
extern char credits_pic11[];
extern char credits_pic12[];
extern char credits_pic13[];
extern char credits_pic14[];
extern char credits_pic14b[];
extern char credits_pic15[];
extern char credits_pic16[];
extern char credits_pic17[];
extern char credits_pic18[];

#define FONAY 32

extern char credits_font[FONAY][1500];
char	*credits_fonaorder="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/?!:,.\"()+-";
int	credits_fonap[256];
int	credits_fonaw[256];

void credits_init();
void credits_prt( int x, int y, char * txt );
void screenin(char * pic, char *text);

void credits_main()
{
	dis_partstart();
	credits_init();
	//tw_opengraph();
	//tw_setstart(160*200);
	if(!dis_exit()) screenin(credits_pic1,
		"GRAPHICS - MARVEL\0"
		"MUSIC - SKAVEN\0"
		"CODE - WILDFIRE\0"
		);

	if(!dis_exit()) screenin(credits_pic2,
		"GRAPHICS - MARVEL\0"
		"MUSIC - SKAVEN\0"
		"CODE - PSI\0"
		);

	if(!dis_exit()) screenin(credits_pic3,
		"GRAPHICS - MARVEL\0"
		"MUSIC - SKAVEN\0"
		"CODE - WILDFIRE\0"
		"ANIMATION - TRUG\0"
		);

	if(!dis_exit()) screenin(credits_pic4,
		"\0GRAPHICS - PIXEL\0"
		);

	if(!dis_exit()) screenin(credits_pic5,
		"GRAPHICS - PIXEL\0"
		"MUSIC - PURPLE MOTION\0"
		"CODE - PSI\0"
		);

	if(!dis_exit()) screenin(credits_pic5b,
		"\0MUSIC - PURPLE MOTION\0"
		"CODE - TRUG\0"
		);

	if(!dis_exit()) screenin(credits_pic6,
		"\0MUSIC - PURPLE MOTION\0"
		"CODE - PSI\0"
		);

	if(!dis_exit()) screenin(credits_pic7,
		"\0MUSIC - PURPLE MOTION\0"
		"CODE - PSI\0"
		);

	if(!dis_exit()) screenin(credits_pic8,
		"\0GRAPHICS - PIXEL\0"
		"MUSIC - PURPLE MOTION\0"
		);

	if(!dis_exit()) screenin(credits_pic9,
		"GRAPHICS - PIXEL\0"
		"MUSIC - PURPLE MOTION\0"
		"CODE - TRUG\0"
		"RENDERING - TRUG\0"
		);

	if(!dis_exit()) screenin(credits_pic10,
		"GRAPHICS - PIXEL, SKAVEN\0"
		"MUSIC - PURPLE MOTION\0"
		"CODE - PSI\0"
		);

	if(!dis_exit()) screenin(credits_pic10b,
		"GRAPHICS - PIXEL, SKAVEN\0"
		"MUSIC - PURPLE MOTION\0"
		"CODE - PSI\0"
		);

	if(!dis_exit()) screenin(credits_pic11,
		"\0MUSIC - PURPLE MOTION\0"
		"CODE - WILDFIRE\0"
		);

	if(!dis_exit()) screenin(credits_pic12,
		"\0MUSIC - PURPLE MOTION\0"
		"CODE - WILDFIRE\0"
		);

	if(!dis_exit()) screenin(credits_pic13,
		"\0MUSIC - PURPLE MOTION\0"
		"CODE - PSI\0"
		);

	if(!dis_exit()) screenin(credits_pic14,
		"GRAPHICS - PIXEL\0"
		"MUSIC - PURPLE MOTION\0"
		"CODE - TRUG\0"
		"RENDERING - TRUG\0"
		);

	if(!dis_exit()) screenin(credits_pic14b,
		"\0MUSIC - PURPLE MOTION\0"
		"CODE - PSI\0"
		);

	if(!dis_exit()) screenin(credits_pic15,
		"GRAPHICS - MARVEL\0"
		"MUSIC - PURPLE MOTION\0"
		"CODE - PSI\0"
		);

	if(!dis_exit()) screenin(credits_pic16,
		"\0MUSIC - SKAVEN\0"
		"CODE - PSI\0"
		);

	if(!dis_exit()) screenin(credits_pic17,
		"\0GRAPHICS - PIXEL\0"
		"MUSIC - PURPLE MOTION\0"
		);

	if(!dis_exit()) screenin(credits_pic18,
		"GRAPHICS - PIXEL\0"
		"MUSIC - PURPLE MOTION\0"
		"CODE - WILDFIRE\0"
		);

	//tw_closegraph();
	}

char vram_split_top[320*100]={0};
char vram_split_bottom[320*200]={0};
char * split_vram = shim_vram;
#define tw_getpixel(b,x,y) b[(x)+(y)*320]
#define tw_putpixel(b,x,y,c) b[(x)+(y)*320]=(c)

void reconstitute_split(int vertical, int horizontal)
{
  memset( shim_vram, 0, 320 * 400 );
  //memcpy( shim_vram, vram_split_top, 320 * 200 );

  for ( int i = 0; i < 200; i++ )
  {
    if ( horizontal < 0 )
    {
      memcpy( shim_vram + 320 * i, vram_split_top + 320 * ( i / 2 ) - horizontal, 320 + horizontal );
    }
    else
    {
      memcpy( shim_vram + 320 * i + horizontal, vram_split_top + 320 * (i / 2), 320 - horizontal );
    }

    if ( i + 200 + vertical < 400 )
    {
      memcpy( shim_vram + 320 * ( i + 200 + vertical ), vram_split_bottom + 320 * i, 320 );
    }
  }
}

void screenin(char * pic, char *text)
	{
	int	a,x,y,yy,v;

	//tw_setsplit(400);
	//tw_clrscr();
  memset(shim_vram,0,320*400);
  memset(vram_split_bottom,0,320*200);
  memset(vram_split_top,0,320*100);
	//tw_setstart(160*200);
	dis_waitb();
	//tw_setpalette(&pic[0][16]);
  setpalarea(&pic[16],0,256);
	pic=&pic[784];

  split_vram = shim_vram + 320 * 200;
	y=16;while(*(text=credits_prtc(160,y,text))) y+=FONAY+10;

  split_vram = shim_vram;
	//for(x=0;x<160;x++) for(y=0;y<100;y++) tw_putpixel(400+x,400+y*2,pic[y*160+x]+16);
	for(x=0;x<160;x++) for(y=0;y<100;y++) tw_putpixel( vram_split_top, 80+x,0+y,pic[y*160+x]+16);

	for(y=200*128;y>0 && !dis_exit();y=y*12L/13)
		{
		dis_waitb();
		//tw_setsplit(y/128+200);
		yy=320-y/80;
		for(a=0;a<10000;a++);
		//tw_setstart(160*200+(yy/4));
    /*
		asm	{
			mov	dx, 0x3c0
			mov	al, 0x33
			out	dx, al
			mov	ax, yy
			and	ax, 3
			shl	ax, 1
			out	dx, al
			}
      */
    reconstitute_split(y / 128, 320 - yy );
    demo_blit();
		}

	for(a=0;a<200 && !dis_exit();a++)
  {
    dis_waitb();
    demo_blit();
  }

	for(y=0,v=0;y<128*200 && !dis_exit();y=y+v,v+=15)
		{
		dis_waitb();
		//tw_setsplit(y/128+200);
		yy=320+y/80;
		for(a=0;a<10000;a++);
		//tw_setstart(160*200+(yy/4));
    /*
		asm	{
			mov	dx, 0x3c0
			mov	al, 0x33
			out	dx, al
			mov	ax, yy
			and	ax, 3
			shl	ax, 1
			out	dx, al
			}
    */
    reconstitute_split(y / 128, 320 - yy);
    demo_blit();
		}
	}

void credits_prt(int x,int y,char *txt)
{
	int	x2w,x2,y2,y2w=y+FONAY,sx,d;
	while(*txt)
	{
		x2w=credits_fonaw[*txt]+x;
		sx=credits_fonap[*txt];
		for(x2=x;x2<x2w;x2++)
		{
			for(y2=y;y2<y2w;y2++)
			{
				d=credits_font[y2-y][sx];
				tw_putpixel( vram_split_bottom,x2,y2,d);
			}
			sx++;
		}
		x=x2+2;
		txt++;
	}
}

char *credits_prtc(int x,int y,char *txt)
{
	int	w=0;
	char	*t=txt;
	while(*t) w+=credits_fonaw[*t++]+2;
	credits_prt(x-w/2,y,txt);
	return(t+1);
}


void credits_init()
	{
	int	x,y,a,b;

	for(x=0;x<1500 && *credits_fonaorder;)
	{
		while(x<1500)
		{
			for(y=0;y<FONAY;y++) if(credits_font[y][x]) break;
			if(y!=FONAY) break;
			x++;
		}
		b=x;
		while(x<1500)
		{
			for(y=0;y<FONAY;y++) if(credits_font[y][x]) break;
			if(y==FONAY) break;
			x++;
		}
		//printf("%c: %i %i\n",*fonaorder,b,x-b);
		credits_fonap[*credits_fonaorder]=b;
		credits_fonaw[*credits_fonaorder]=x-b;
		credits_fonaorder++;
	}
	credits_fonap[32]=1500-32;
	credits_fonaw[32]=8;

	memmove(&credits_pic1[16*3+16],&credits_pic1[16],768-16*3);
	memmove(&credits_pic2[16*3+16],&credits_pic2[16],768-16*3);
	memmove(&credits_pic3[16*3+16],&credits_pic3[16],768-16*3);
	memmove(&credits_pic4[16*3+16],&credits_pic4[16],768-16*3);
	memmove(&credits_pic5[16*3+16],&credits_pic5[16],768-16*3);
	memmove(&credits_pic5b[16*3+16],&credits_pic5b[16],768-16*3);
	memmove(&credits_pic6[16*3+16],&credits_pic6[16],768-16*3);
	memmove(&credits_pic7[16*3+16],&credits_pic7[16],768-16*3);
	memmove(&credits_pic8[16*3+16],&credits_pic8[16],768-16*3);
	memmove(&credits_pic9[16*3+16],&credits_pic9[16],768-16*3);
	memmove(&credits_pic10[16*3+16],&credits_pic10[16],768-16*3);
	memmove(&credits_pic10b[16*3+16],&credits_pic10b[16],768-16*3);
	memmove(&credits_pic11[16*3+16],&credits_pic11[16],768-16*3);
	memmove(&credits_pic12[16*3+16],&credits_pic12[16],768-16*3);
	memmove(&credits_pic13[16*3+16],&credits_pic13[16],768-16*3);
	memmove(&credits_pic14[16*3+16],&credits_pic14[16],768-16*3);
	memmove(&credits_pic14b[16*3+16],&credits_pic14b[16],768-16*3);
	memmove(&credits_pic15[16*3+16],&credits_pic15[16],768-16*3);
	memmove(&credits_pic16[16*3+16],&credits_pic16[16],768-16*3);
	memmove(&credits_pic17[16*3+16],&credits_pic17[16],768-16*3);
	memmove(&credits_pic18[16*3+16],&credits_pic18[16],768-16*3);
	for(a=0;a<10;a++)
		{
		credits_pic1[a*3+0+16]=credits_pic1[a*3+1+16]=credits_pic1[a*3+2+16]=7*a;
		credits_pic2[a*3+0+16]=credits_pic2[a*3+1+16]=credits_pic2[a*3+2+16]=7*a;
		credits_pic3[a*3+0+16]=credits_pic3[a*3+1+16]=credits_pic3[a*3+2+16]=7*a;
		credits_pic4[a*3+0+16]=credits_pic4[a*3+1+16]=credits_pic4[a*3+2+16]=7*a;
		credits_pic5[a*3+0+16]=credits_pic5[a*3+1+16]=credits_pic5[a*3+2+16]=7*a;
		credits_pic5b[a*3+0+16]=credits_pic5b[a*3+1+16]=credits_pic5b[a*3+2+16]=7*a;
		credits_pic6[a*3+0+16]=credits_pic6[a*3+1+16]=credits_pic6[a*3+2+16]=7*a;
		credits_pic7[a*3+0+16]=credits_pic7[a*3+1+16]=credits_pic7[a*3+2+16]=7*a;
		credits_pic8[a*3+0+16]=credits_pic8[a*3+1+16]=credits_pic8[a*3+2+16]=7*a;
		credits_pic9[a*3+0+16]=credits_pic9[a*3+1+16]=credits_pic9[a*3+2+16]=7*a;
		credits_pic10[a*3+0+16]=credits_pic10[a*3+1+16]=credits_pic10[a*3+2+16]=7*a;
		credits_pic10b[a*3+0+16]=credits_pic10b[a*3+1+16]=credits_pic10b[a*3+2+16]=7*a;
		credits_pic11[a*3+0+16]=credits_pic11[a*3+1+16]=credits_pic11[a*3+2+16]=7*a;
		credits_pic12[a*3+0+16]=credits_pic12[a*3+1+16]=credits_pic12[a*3+2+16]=7*a;
		credits_pic13[a*3+0+16]=credits_pic13[a*3+1+16]=credits_pic13[a*3+2+16]=7*a;
		credits_pic14[a*3+0+16]=credits_pic14[a*3+1+16]=credits_pic14[a*3+2+16]=7*a;
		credits_pic14b[a*3+0+16]=credits_pic14b[a*3+1+16]=credits_pic14b[a*3+2+16]=7*a;
		credits_pic15[a*3+0+16]=credits_pic15[a*3+1+16]=credits_pic15[a*3+2+16]=7*a;
		credits_pic16[a*3+0+16]=credits_pic16[a*3+1+16]=credits_pic16[a*3+2+16]=7*a;
		credits_pic17[a*3+0+16]=credits_pic17[a*3+1+16]=credits_pic17[a*3+2+16]=7*a;
		credits_pic18[a*3+0+16]=credits_pic18[a*3+1+16]=credits_pic18[a*3+2+16]=7*a;
		}
	}
