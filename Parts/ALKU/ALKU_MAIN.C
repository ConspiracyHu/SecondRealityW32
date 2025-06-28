#include <dos.h>
#include <stdio.h>
#include <conio.h>
#include <memory.h>
//#include "tweak.h"
#include "../dis/dis.h"
#include "../common.h"
#include "../../shims.h"

#define SCRLF 9

extern char hzpic[];
extern void outline(char *f, char *t);
extern void ascrolltext(int scrl, int *dtau);

#define vmem shim_vram
unsigned char planar_vram[ 352 * 200 ];

void alku_simulate_scroll()
{
  for ( int y = 0; y < 320; y++ )
  {
    memcpy( shim_vram + y * 320, planar_vram + cop_start + cop_scrl + y * 352, 320 );
  }
}

int	mmask[4]={0x0102,0x0202,0x0402,0x0802};

char (* vvmem)[176];
extern char font[31][1500];
char rowbuf[1024];

char	palette[768];		// pic
char	palette2[768];		// pic & text

char	fade1[768];			// black
char	fade2[768];			// text

short	picin[768];
short	textin[768];
short	textout[768];

char	*alku_fonaorder="ABCDEFGHIJKLMNOPQRSTUVWXabcdefghijklmnopqrstuvwxyz0123456789!?,.:\x8f\x8f()+-*='\x8f\x99";
int	fonap[256];
int	fonaw[256];

int	dtau[30000];
char	tbuf[186][352];

int	a=0,p=0,alku_tptr=0;

void alku_init();
void prtc( int x, int y, char * txt );
void dofade( char * pal1, char * pal2 );
int fdofade( char * pal1, char * pal2, int a );
void addtext( int tx, int ty, char * txt );
void maketext( int scrl );
void scrolltext( int scrl );
int alku_do_scroll( int mode );
void wait( int t );
void fonapois();
void ffonapois();
void prt( int x, int y, char * txt );
void fffade( char * pal1, char * pal2, int frames );
void faddtext( int tx, int ty, char * txt );
void fmaketext( int scrl );

void alku_main()
	{
	int	aa,b,c,x,y,f;

	//asm	mov	ax, 3
	//asm	int	10h

	alku_init();

  /*
	while(dis_sync()<1 && !dis_exit()) demo_blit();

	prtc(160,120,"A");
	prtc(160,160,"Future Crew");
	prtc(160,200,"Production");
	dofade(fade1,fade2); wait(300); dofade(fade2,fade1); fonapois();

	while(dis_sync()<2 && !dis_exit()) demo_blit();

	prtc(160,160,"First Presented");
	prtc(160,200,"at Assembly 93");
	dofade(fade1,fade2); wait(300); dofade(fade2,fade1); fonapois();

	while(dis_sync()<3 && !dis_exit()) demo_blit();

	prtc(160,120,"in");
	prtc(160,160,"\x8f");
	prtc(160,179,"\x99");
	dofade(fade1,fade2); wait(300); dofade(fade2,fade1); fonapois();

	while(dis_sync()<4 && !dis_exit()) demo_blit();
  */

	memcpy(fadepal,fade1,768);
	cop_fadepal=(char*)picin;
	cop_dofade=128;
	for(a=1,p=1,f=0,frame_count=0;cop_dofade!=0 && !dis_exit();)
  {
    copper2();
    copper3();
		alku_do_scroll(2);
    dis_waitb();
    demo_blit();
  }

	for(f=60;a<320 && !dis_exit();)
		{
		if(f==0) {
			cop_fadepal=(char*)textin;
			cop_dofade=64;
			f+=20;
			}
		else if(f==50) {
			cop_fadepal= (char *)textout;
			cop_dofade=64;
			f++;
			}
		else if(f>50 && cop_dofade==0) {
			cop_pal=palette; do_pal=1; f++;
			memset(tbuf,0,186*320);
			switch(alku_tptr++) {
			case 0:
				addtext(160,50,"Graphics");
				addtext(160,90,"Marvel");
				addtext(160,130,"Pixel");	// sucks
				ffonapois();
				break;
			case 1:
				faddtext(160,50,"Music");
				faddtext(160,90,  "Purple Motion");
				faddtext(160,130, "Skaven");
				ffonapois();
				break;
			case 2:
				faddtext(160,30,"Code");
				faddtext(160,70,  "Psi");
				faddtext(160,110, "Trug");
				faddtext(160,148, "Wildfire");
				ffonapois();
				break;
			case 3:
				faddtext(160,50,"Additional Design");
				faddtext(160,90, "Abyss");
//				faddtext(160,110,"Useless Design");
				faddtext(160,130, "Gore");
				ffonapois();
				break;
			case 4:
				ffonapois();
				break;
			default:
				faddtext(160,80, "BUG BUG BUG");
				faddtext(160,130, "Timing error");
				ffonapois();
				break;
				}
			while(((a&1) || dis_sync()<4+alku_tptr) && !dis_exit() && a<319)
				alku_do_scroll(0);
			aa=a;
			if(aa<320-12) fmaketext(aa+16);
			f=0;
			}
		else	f++;

		alku_do_scroll(1);
    dis_waitb();
    demo_blit();
    cop_dofade--;
  }
	if(f>63/SCRLF){
		dofade(palette2,palette);
		}
	fonapois();
	//close_copper();
	}

void alku_init()	{
	int	a,b,c,x,y,p=0,f;

	dis_partstart();
	//tw_opengraph();
	//init_copper();
	setpalarea(fade1,0,256);
	memcpy(palette,hzpic+16,768);

	for(a=0;a<88;a++)
		{
		outline(hzpic+a*4+784, planar_vram+a+176*50);
		outline(hzpic+a*4+784, planar_vram+a+176*50+88);
		}
  alku_simulate_scroll();

	for(y=0;y<32;y++)
	{
		for(a=0;a<1500;a++)
		{
			switch(font[y][a]&3)
			{
			case 0x1 : b=0x40; break;
			case 0x2 : b=0x80; break;
			case 0x3 : b=0xc0; break;
			default : b=0;
			}
			font[y][a]=b;
		}
	}

	for(y=0;y<768;y+=3)
	{
		if(y<64*3)
		{
		palette2[y+0]=palette[y+0];
		palette2[y+1]=palette[y+1];
		palette2[y+2]=palette[y+2];
		}
		else if(y<128*3)
		{
			palette2[y+0]=(fade2[y+0]=palette[0x1*3+0])*63+((palette[y%(64*3)+0]*(63-palette[0x1*3+0]))>>6);
			palette2[y+1]=(fade2[y+1]=palette[0x1*3+1])*63+((palette[y%(64*3)+1]*(63-palette[0x1*3+1]))>>6);
			palette2[y+2]=(fade2[y+2]=palette[0x1*3+2])*63+((palette[y%(64*3)+2]*(63-palette[0x1*3+2]))>>6);
		}
		else if(y<192*3)
		{
			palette2[y+0]=(fade2[y+0]=palette[0x2*3+0])*63+((palette[y%(64*3)+0]*(63-palette[0x2*3+0]))>>6);
			palette2[y+1]=(fade2[y+1]=palette[0x2*3+1])*63+((palette[y%(64*3)+1]*(63-palette[0x2*3+1]))>>6);
			palette2[y+2]=(fade2[y+2]=palette[0x2*3+2])*63+((palette[y%(64*3)+2]*(63-palette[0x2*3+2]))>>6);
		}
		else
		{
			palette2[y+0]=(fade2[y+0]=palette[0x3*3+0])*63+((palette[y%(64*3)+0]*(63-palette[0x3*3+0]))>>6);
			palette2[y+1]=(fade2[y+1]=palette[0x3*3+1])*63+((palette[y%(64*3)+1]*(63-palette[0x3*3+1]))>>6);
			palette2[y+2]=(fade2[y+2]=palette[0x3*3+2])*63+((palette[y%(64*3)+2]*(63-palette[0x3*3+2]))>>6);
		}
	}

	for(a=192;a<768;a++) palette[a]=palette[a-192];

	for(x=0;x<1500 && *alku_fonaorder;)
	{
		while(x<1500)
		{
			for(y=0;y<32;y++) if(font[y][x]) break;
			if(y!=32) break;
			x++;
		}
		b=x;
		while(x<1500)
		{
			for(y=0;y<32;y++) if(font[y][x]) break;
			if(y==32) break;
			x++;
		}
		//printf("%c: %i %i\n",*alku_fonaorder,b,x-b);
		fonap[*alku_fonaorder]=b;
		fonaw[*alku_fonaorder]=x-b;
		alku_fonaorder++;
	}
	fonap[32]=1500-20;
	fonaw[32]=16;

	for(a=0;a<768;a++)
		{
		textin[a]=(palette2[a]-palette[a])*256/64;
		textout[a]=(palette[a]-palette2[a])*256/64;
		picin[a]=(palette[a]-fade1[a])*256/128;
		}
	}

void wait(int t)
	{
  for ( int i = 0; i < t; i++ )
  {
    if ( dis_exit() ) break;
    dis_waitb();
    demo_blit();
  }
	//while(frame_count<t && !dis_exit()); frame_count=0;
	}

void fonapois()
	{
  char * vvmem = shim_vram;// ( 0x0a000, 0 );
	unsigned a;
  //memset( shim_vram, 0, shim_vram_x * shim_vram_y );

  for(a=320*64;a<320U*(64+256);a++) vvmem[a]=vvmem[a]&63;
  /*
	shim_outp(0x3c4,0x0102);
	shim_outp(0x3ce,0x0004);
	for(a=160*64;a<160U*(64+256);a++) vvmem[a]=vvmem[a]&63;

	shim_outp(0x3c4,0x0202);
	shim_outp(0x3ce,0x0104);
	for(a=160*64;a<160U*(64+256);a++) vvmem[a]=vvmem[a]&63;

	shim_outp(0x3c4,0x0402);
	shim_outp(0x3ce,0x0204);
	for(a=160*64;a<160U*(64+256);a++) vvmem[a]=vvmem[a]&63;
	shim_outp(0x3c4,0x0802);
	shim_outp(0x3ce,0x0304);
	for(a=160*64;a<160U*(64+256);a++) vvmem[a]=vvmem[a]&63;
  */

	}

#define tw_getpixel(x,y) shim_vram[(x)+(y)*320]
#define tw_putpixel(x,y,c) shim_vram[(x)+(y)*320]=(c)

void prt(int x,int y,char *txt)
{
	int	x2w,x2,y2,y2w=y+32,sx,d;
	while(*txt)
	{
		x2w=fonaw[*txt]+x;
		sx=fonap[*txt];
		for(x2=x;x2<x2w;x2++)
		{
			for(y2=y;y2<y2w;y2++)
			{
				d=font[y2-y][sx];
				tw_putpixel(x2,y2,tw_getpixel(x2,y2)|d);
			}
			sx++;
		}
		x=x2+2;
		txt++;
	}
}

void prtc(int x,int y,char *txt)
{
	int	w=0;
	char	*t=txt;
	while(*t) w+=fonaw[*t++]+2;
	prt(x-w/2,y,txt);
}

void dofade(char *pal1, char *pal2)
	{
	int	a,b,c;
	char	pal[768];

	for(a=0;a<64 && !dis_exit();a++)
		{
		for(b=0;b<768;b++) pal[b]=(pal1[b]*(64-a)+pal2[b]*a>>6);
    setpalarea( pal, 0, 256 );
		//cop_pal=pal; do_pal=1;
		//while(frame_count<1); frame_count=0;
    dis_waitb();
    demo_blit();
		}
	}
char	fuckpal[768];

int fdofade(char *pal1, char *pal2, int a)
	{
	int	b,c;

	if(a<0 || a>64) return(0);
	for(b=0;b<768;b++) fuckpal[b]=(pal1[b]*(64-a)+pal2[b]*a>>6);
	cop_pal=fuckpal; do_pal=1;
  return 0;
	}

void addtext(int tx,int ty,char *txt)
	{
	int	a,b,c,x,y,w=0;
	char	*t=txt;

	while(*t) w+=fonaw[*t++]+2;

	t=txt; w/=2;
	while(*t)
		{
		for(x=0;x<fonaw[*t];x++)
			for(y=0;y<31;y++)
				tbuf[y+ty][tx+x-w]=font[y][fonap[*t]+x];

		tx+=fonaw[*t++]+2;
		}
	}


void maketext(int scrl)
	{
  char * vvmem = shim_vram;
	int	*p1=dtau;
	int	mtau[]={1*256+2,2*256+2,4*256+2,8*256+2};
	int	a,b,c,x,y,m;

	for(m=0;m<4;m++)
		{
		for(x=m;x<320;x+=4) for(y=1;y<184;y++)
			if(tbuf[y][x]!=tbuf[y][x-2]) {
				*p1++=x/4+y*176+100*176;
				*p1++=tbuf[y][x]^tbuf[y][x-2];
				}
		*p1++=-1;
		*p1++=-1;
		}

	for(x=0;x<320;x++)
		{
		shim_outp(0x3c4,mtau[(x+scrl)&3]);
		shim_outp(0x3ce,((x+scrl)&3)*256+4);
		for(y=1;y<184;y++)
			{
			vvmem[y*176+176*100+(x+scrl)/4]^=tbuf[y][x-1-1];
			vvmem[y*176+176*100+(x+scrl)/4+88]^=tbuf[y][x-1];
			}
		}
	}

void scrolltext(int scrl)
	{
	char 	*vvmem=shim_vram;
	int	mtau[]={1*256+2,2*256+2,4*256+2,8*256+2,1*256+2,2*256+2,4*256+2,8*256+2};
	int	*p1=dtau;
	int	x,y,a,c,m,aa;

	p1=dtau;
	for(m=0;m<4;m++)
		{
		aa=(scrl+m)/4;
		shim_outp(0x3c4,mtau[(scrl+m)&3]);
		shim_outp(0x3ce,((scrl+m)&3)*256+4);
		while(*p1!=-1)
			{
			a=*p1++;
			c=*p1++;
			vvmem[a+aa]^=c;
			}
		p1+=2;
		}
	}


int alku_do_scroll(int mode)
	{
	if(mode==0 && frame_count++<SCRLF) return(0);
	while(frame_count<SCRLF){frame_count++;}
	frame_count-=SCRLF;
	if(mode==1) ascrolltext(a+p*352,dtau);
	cop_start=a/4+p*88;
  cop_scrl=(a&3)*2;
  
	if((a&3)==0)
		{
		outline(hzpic+(a/4+86)*4+784, planar_vram + (a/4+86)+176*50);
		outline(hzpic+(a/4+86)*4+784, planar_vram + (a/4+86)+176*50+88);
		}
  alku_simulate_scroll();
	a+=1; p^=1;
	return(1);
	}




void faddtext(int tx,int ty,char *txt)
	{
	int	a,b,c,x,y,w=0;
	char	*t=txt;

	while(*t) w+=fonaw[*t++]+2;

	t=txt; w/=2;
	while(*t)
		{
		for(x=0;x<fonaw[*t];x++)
			for(y=0;y<32;y++)
				tbuf[y+ty][tx+x-w]=font[y][fonap[*t]+x];

		alku_do_scroll(0);
		tx+=fonaw[*t++]+2;
		}
	}

void fmaketext(int scrl)
	{
	char 	*vvmem=shim_vram;
	int	*p1=dtau;
	int	mtau[]={1*256+2,2*256+2,4*256+2,8*256+2};
	int	b,c,x,y,m;

	for(m=0;m<4;m++)
		{
		for(x=m;x<320;x+=4) {
			for(y=1;y<184;y++) if(tbuf[y][x]!=tbuf[y][x-2]) {
				*p1++=x/4+y*176+100*176;
				*p1++=tbuf[y][x]^tbuf[y][x-2];
				}
			alku_do_scroll(0);
			}
		*p1++=-1;
		*p1++=-1;
		}

	for(x=0;x<320;x++)
		{
		shim_outp(0x3c4,mtau[(x+scrl)&3]);
		shim_outp(0x3ce,((x+scrl)&3)*256+4);
		for(y=1;y<184;y++)
			{
			vvmem[y*176+176*100+(x+scrl)/4]^=tbuf[y][x-1-1];
			vvmem[y*176+176*100+(x+scrl)/4+88]^=tbuf[y][x-1];
			}
		alku_do_scroll(0);
		}

	while(a<=scrl) alku_do_scroll(0);
	}

void ffonapois()
	{
  unsigned int * vvmem = ( unsigned int * )shim_vram;// MK_FP( 0x0a000, 0 );
	unsigned a;

  for(a=80*64;a<80U*(64+256+10);a++) vvmem[a]=vvmem[a]&0x3f3f3f3f;
  /*
	shim_outp(0x3c4,0x0102);
	shim_outp(0x3ce,0x0004);
	for(a=40*64;a<40U*(64+256+10);a++) vvmem[a]=vvmem[a]&0x3f3f3f3f;
	alku_do_scroll(0);

	shim_outp(0x3c4,0x0202);
	shim_outp(0x3ce,0x0104);
	for(a=40*64;a<40U*(64+256+10);a++) vvmem[a]=vvmem[a]&0x3f3f3f3f;
	alku_do_scroll(0);

	shim_outp(0x3c4,0x0402);
	shim_outp(0x3ce,0x0204);
	for(a=40*64;a<40U*(64+256+10);a++) vvmem[a]=vvmem[a]&0x3f3f3f3f;
	alku_do_scroll(0);

	shim_outp(0x3c4,0x0802);
	shim_outp(0x3ce,0x0304);
	for(a=40*64;a<40U*(64+256+10);a++) vvmem[a]=vvmem[a]&0x3f3f3f3f;
	alku_do_scroll(0);
  */
	}

char cfpal[768*2];
int cop_fade;

void fffade(char *pal1, char *pal2, int frames)
	{
	int	a,b,c;
	for(a=0;a<768;a++)
		{
		cfpal[a]=pal1[a];
		cfpal[a+768]=(pal2[a]-pal1[a])*256/frames;
		}
	cop_fade=frames;
	}

/*
dis_sync

0	= ...
1	= fc_pres
2	= first
3	= maisema
4	= gfx
5	= music
6	= code
7	= addi
8	= exit

dis_muscode=row/order

2  ekaa = mustaa
2  fc..
3  93..
4  feidaa ineen
5  music
6  gfx
7  code
8  addi

bx=6
ax=?
int fch
cx=ord
bx=row


*/