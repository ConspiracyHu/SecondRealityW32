#include <stdio.h>
#include <conio.h>
#include <dos.h>
#include <math.h>
#include "tweak.h"
#include "..\..\shims.h"

#define M_PI 3.141592f

extern do_line(char *to, int dx, int dy, int cnt, char *from, long txx1, long txy1, long txx2, long txy2, int dseg);
extern do_block(int ycnt);
extern do_clear(char *vmem, int *otau, int *ntau);

extern int acstau[256];
int	sini[2000];
char vram_half[ 160 * 400 ] = { 0 };
char	(* vmem)[160]= vram_half;
//#define vmem shim_vram

extern char kuva1[64][256];
extern char kuva2[64][256];
extern char kuva3[64][256];
extern char dist1[128][256];
char	buu[1000];
char	sinx[128], siny[128];
char	plz_pal[768];

short	clrtau[8][256][2];
int	clrptr=0;

initvect() {
	int	a,b,x,y,s,d=0,p=0,ch;

	for(a=0;a<1524;a++)
		{
		sini[a]=s=sin(a/1024.0*M_PI*4)*127;
		s-=sini[a];
		}

/*	for(a=0;a<65;a++) for(b=0;b<256;b++) // chessboard
		{ x=1; if((a>>4)&1) x^=3; if((b>>5)&1) x^=3; kuva[a][b]=x; }

	pal[0*192+3*1]=pal[0*192+3*1+1]=pal[0*192+3*1+2]=40;
	pal[0*192+3*2]=pal[0*192+3*2+1]=pal[0*192+3*2+2]=60;
*/
	for(a=1;a<32;a++)		// must-sini-valk
		{ plz_pal[0*192+a*3]=0; plz_pal[0*192+a*3+1]=0; plz_pal[0*192+a*3+2]=a*2; }
	for(a=0;a<32;a++)
		{ plz_pal[0*192+a*3+32*3]=a*2; plz_pal[0*192+a*3+1+32*3]=a*2; plz_pal[0*192+a*3+2+32*3]=63; }

	for(a=0;a<32;a++)		// must-pun-kelt
		{ plz_pal[1*192+a*3]=a*2; plz_pal[1*192+a*3+1]=0; plz_pal[1*192+a*3+2]=0; }
	for(a=0;a<32;a++)
		{ plz_pal[1*192+a*3+32*3]=63; plz_pal[1*192+a*3+1+32*3]=a*2; plz_pal[1*192+a*3+2+32*3]=0; }


	for(a=0;a<32;a++)		// must-orans-viol
		{ plz_pal[2*192+a*3]=a; plz_pal[2*192+a*3+1]=0; plz_pal[2*192+a*3+2]=a*2/3; }
	for(a=0;a<32;a++)
		{ plz_pal[2*192+a*3+32*3]=31-a; plz_pal[2*192+a*3+1+32*3]=a*2; plz_pal[2*192+a*3+2+32*3]=21; }


	for(y=0;y<64;y++) for(x=0;x<256;x++)
		{
		kuva1[y][x]=sini[(y*4+sini[x*2])&511]/4+32;
		kuva2[y][x]=sini[(y*4+sini[x*2])&511]/4+32+64;
		kuva3[y][x]=sini[(y*4+sini[x*2])&511]/4+32+128;
		}

	for(y=0;y<128;y++) for(x=0;x<256;x++)
		dist1[y][x]=sini[y*8]/3;

	for(a=0;a<8*256;a++) { clrtau[0][a][0]=320; clrtau[0][a][1]=0; }
	}

extern char * to;
extern char * from;
extern short * ctau;
extern int dseg;
extern short	xx, yy;
extern long	ay1,ay2,ax1,ax2,xx1,yy1,xx2,yy2;
extern long	txx1,txy1,tay1,tax1;
extern long	txx2,txy2,tay2,tax2;

char *	kuvataus[]={kuva1,kuva2,kuva3,kuva1};
char *	disttaus[]={dist1,dist1,dist1,dist1};

do_poly(x1,y1,x2,y2,x3,y3,x4,y4,color, dd)
int	x1,y1,x2,y2,x3,y3,x4,y4,color, dd;
	{
	int    	a,b,c,d,n=0,m,s1,s2,d1,d2,dx1,dy1,dx2,dy2;

	struct  points {
		int	x,y; } pnts[4],txt[4]={{64,4},{190,4},{190,60},{64,60}};
//		int	x,y; } pnts[4],txt[4]={{1,1},{63,1},{63,63},{1,63}};

	dd=(dd+1)&63;

	pnts[0].x=x1; pnts[0].y=y1;
	pnts[1].x=x2; pnts[1].y=y2;
	pnts[2].x=x3; pnts[2].y=y3;
	pnts[3].x=x4; pnts[3].y=y4;

	for(n=0,a=1;a<4;a++) if(pnts[a].y<pnts[n].y) n=a;

	s1=n; s2=n; d1=(s1+1)&3; d2=(s2-1)&3;
	dx1=pnts[d1].x-pnts[s1].x;
	dy1=pnts[d1].y-pnts[s1].y; if(dy1==0) dy1++;
	ax1=65536L*dx1/dy1;
	xx1=((long)pnts[s1].x<<16)+0x8000L;
	txx1=((long)txt[s1].x<<16)+0x8000L;
	txy1=((long)txt[s1].y<<16)+0x8000L;
	tax1=65536L*(txt[d1].x-txt[s1].x)/dy1;
	tay1=65536L*(txt[d1].y-txt[s1].y)/dy1;

	dx2=pnts[d2].x-pnts[s2].x;
	dy2=pnts[d2].y-pnts[s2].y; if(dy2==0) dy2++;
	ax2=65536L*dx2/dy2;
	xx2=((long)pnts[s2].x<<16)+0x8000L;
	txx2=((long)txt[s2].x<<16)+0x8000L;
	txy2=((long)txt[s2].y<<16)+0x8000L;
	tax2=65536L*(txt[d2].x-txt[s2].x)/dy2;
	tay2=65536L*(txt[d2].y-txt[s2].y)/dy2;

	yy=(long)pnts[s1].y;
	from=kuvataus[color];
	to=vmem[yy];		// initialize gfx pointers
	dseg=disttaus[color]+dd*16;
	ctau=&clrtau[clrptr][yy];
	for(n=0;n<4;)
		{
		if(pnts[d1].y<pnts[d2].y) m=pnts[d1].y; else m=pnts[d2].y;
		do_block(m-yy); yy=m;

		if(pnts[d1].y==pnts[d2].y)
			{
			s1=d1; d1=(s1+1)&3;
			s2=d2; d2=(s2-1)&3; n+=2;

			dx1=pnts[d1].x-pnts[s1].x;
			dy1=pnts[d1].y-pnts[s1].y; if(dy1==0) dy1++;
			ax1=65536L*dx1/dy1;
			xx1=((long)pnts[s1].x<<16)+0x8000L;
			txx1=((long)txt[s1].x<<16)+0x8000L;
			txy1=((long)txt[s1].y<<16)+0x8000L;
			tax1=65536L*(txt[d1].x-txt[s1].x)/dy1;
			tay1=65536L*(txt[d1].y-txt[s1].y)/dy1;

			dx2=pnts[d2].x-pnts[s2].x;
			dy2=pnts[d2].y-pnts[s2].y; if(dy2==0) dy2++;
			ax2=65536L*dx2/dy2;
			xx2=((long)pnts[s2].x<<16)+0x8000L;
			txx2=((long)txt[s2].x<<16)+0x8000L;
			txy2=((long)txt[s2].y<<16)+0x8000L;
			tax2=65536L*(txt[d2].x-txt[s2].x)/dy2;
			tay2=65536L*(txt[d2].y-txt[s2].y)/dy2;
			}
		else if(pnts[d1].y<pnts[d2].y)
			{
			s1=d1; d1=(s1+1)&3; n++;
			dx1=pnts[d1].x-pnts[s1].x;
			dy1=pnts[d1].y-pnts[s1].y; if(dy1==0) dy1++;
			ax1=65536L*dx1/dy1;
			xx1=((long)pnts[s1].x<<16)+0x8000L;
			txx1=((long)txt[s1].x<<16)+0x8000L;
			txy1=((long)txt[s1].y<<16)+0x8000L;
			tax1=65536L*(txt[d1].x-txt[s1].x)/dy1;
			tay1=65536L*(txt[d1].y-txt[s1].y)/dy1;
			}
		else 	{
			s2=d2; d2=(s2-1)&3; n++;
			dx2=pnts[d2].x-pnts[s2].x;
			dy2=pnts[d2].y-pnts[s2].y; if(dy2==0) dy2++;
			ax2=65536L*dx2/dy2;
			xx2=((long)pnts[s2].x<<16)+0x8000L;
			txx2=((long)txt[s2].x<<16)+0x8000L;
			txy2=((long)txt[s2].y<<16)+0x8000L;
			tax2=65536L*(txt[d2].x-txt[s2].x)/dy2;
			tay2=65536L*(txt[d2].y-txt[s2].y)/dy2;
			}
		}
	}

clear()
	{
  short *otau=clrtau[(clrptr-3)&7], *ntau=clrtau[clrptr];

	clrptr=(clrptr+1)&7;

	do_clear(vmem[0],otau,ntau);
	}

