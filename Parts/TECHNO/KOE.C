#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <conio.h>
#include <memory.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <fcntl.h>
#include <io.h>
#include <malloc.h>
//#include <graph.h>
#include "..\dis\dis.h"
#include "..\..\shims.h"
#include "..\COMMON.H"

//#include "readp.c"

//extern char pic[];
extern short koe_sin1024[];

char circlemem[ 16384*16 ];

void initinterference(char * memory);
void dointerference();
void dointerference2();
void asminit( char * vbuf );
void asmbox( int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4 );
void asmdoit( char * vbuf, char * vram );
void asmdoit2( char * vbuf, char * vram );
void koe_lineblit( char * vram, char * rowbuf );

int	doit1(int count);
int	doit2(int count);
int	doit3(int count);

char	*pic;

char	palette[768];
char	*palfade;
char	rowbuf[320];

int	pl=1,plv=0;

extern char vbuf[];

char	pal[16*16*3];

//char *vram=(char *)0xa0000000L;
#define vram shim_vram

int	koe_curpal=0;

extern char power0[];
extern char power1[];

unsigned char koe_tempbuf[ 80 * 400 ] = { 0 };
unsigned char koe_planar[ 80 * 400 * 4 ] = { 0 };

int 	waitborder(void)
{	
	static int lasta=0;
	int	a,r;
	char	*p;
	a=dis_musrow(0);
	if(a!=lasta)
	{
		lasta=a;
		if((a&7)==7) koe_curpal=15;
	}
	r=dis_waitb();
	if(r>10) r=10;
	if(r<0) r=1;
	p=pal+16*3*koe_curpal;
	shim_outp(0x3c8,0);
	for(a=0;a<16*3;a++) shim_outp(0x3c9,*p++);
	if(koe_curpal) 
	{
		koe_curpal--;
	}
	return(r);
}

/*
void	border(int r,int g,int b)
{
	dis_waitb();
	shim_outp(0x3c8,0);
	shim_outp(0x3c9,r);
	shim_outp(0x3c9,g);
	shim_outp(0x3c9,b);
	dis_waitb();
}

void	setborder(int c)
{
	return;
	_asm
	{
		mov	dx,3dah
		in	al,dx
		mov	dx,3c0h
		mov	al,11h+20h
		out	dx,al
		mov	al,byte ptr c
		out	dx,al
	}
}
*/

int *	flash(int i)
{
	static int pal1[16*3];
	int	pal2[16*3];
	int	a,j,k;
	if(i==-2) ;
	else if(i==-1)
	{
		shim_outp(0x3c7,0);
		for(a=0;a<16*3;a++) pal1[a]=shim_inp(0x3c9);
	}
	else
	{
		j=256-i;
		for(a=0;a<16*3;a++) pal2[a]=(pal1[a]*j+63*i)>>8;
		dis_waitb();
		shim_outp(0x3c8,0);
		for(a=0;a<16*3;a++) shim_outp(0x3c9,pal2[a]);
		demo_blit();
	}
	return(pal1);
}

void koe_main()
{
	FILE	*f1;
	int	rot=45;
	int	x,y,b,c,x1,y1,x2,y2,x3,y3,x4,y4,a,hx,hy,vx,vy,cx,cy,pl=1,plv=0;
	int	vma,vm;
	char	ch;
	int	*ip;
	char	*v,*p;
	
	dis_partstart();
	
  // vbuf = halloc( 8192, 1 );
	
	for(c=0;c<16;c++)
	{
		p=pal+3*16*c;
		for(a=0;a<16;a++)
		{
			x=0;
			if(a&1) x++;
			if(a&2) x++;
			if(a&4) x++;
			if(a&8) x++;
			switch(x)
			{
			case 0 :
				*(p++)=0;
				*(p++)=0;
				*(p++)=0;
				break;
			case 1 :
				*(p++)=38*64/111;
				*(p++)=33*64/111;
				*(p++)=44*64/111;
				break;
			case 2 :
				*(p++)=52*64/111;
				*(p++)=45*64/111;
				*(p++)=58*64/111;
				break;
			case 3 :
				*(p++)=67*64/111;
				*(p++)=61*64/111;
				*(p++)=73*64/111;
				break;
			case 4 :
				*(p++)=83*64/111;
				*(p++)=77*64/111;
				*(p++)=89*64/111;
				break;
			}
			p-=3;
			*p=*p*(10+c*9/9)/10;
			if(*p>63) *p=63;
			p++;
			*p=*p*(10+c*7/9)/10;
			if(*p>63) *p=63;
			p++;
			*p=*p*(10+c*5/9)/10;
			if(*p>63) *p=63;
			p++;
		}
	}
			
	asminit(vbuf);
	x1=y1=100;

	p=power0;
	for(b=0;b<16;b++)
	{
		for(c=0;c<256;c++)
		{
			if(b==15)
			{
				ch=(char)c;
				*(p++)=ch;
			}
			else
			{
				if(c>127) a=c-256;
				else a=c;
				ch=(char)(a*b/15);
				*(p++)=ch;
			}
		}
	}
	
	p=power1;
	for(b=0;b<16;b++)
	{
		for(c=0;c<256;c++)
		{
			if(b==15)
			{
				ch=(char)c;
				*(p++)=ch;
			}
			else
			{
				if(c>127) a=c-256;
				else a=c;
				ch=(char)(a*b/15);
				*(p++)=ch;
			}
		}
	}

	if ( !demo_isfirstpart() )
	{
		while(!dis_exit() && dis_musplus()<-4) ;
	}
	dis_setmframe(0);

	dointerference2();
	
	initinterference(circlemem);

    if(!dis_exit())
    {
	dointerference();

	flash(-1);
	flash(32);
	flash(64);
	flash(192);
	flash(256);

  /*
	_asm
	{
	;	mov	dx,3c8h
	;	xor	al,al
	;	out	dx,al
	;	inc	dx
	;	mov	cx,16*3
	;l1:	out	dx,al
	;	loop	l1
		mov	dx,3d4h
		mov	ax,0013h+256*20
		out	dx,ax
		mov	ax,000dh
		out	dx,ax
		mov	ax,000ch
		out	dx,ax
		mov	dx,3dah
		in	al,dx
		mov	dx,3c0h
		mov	al,13h
		out	dx,al
		xor	al,al
		out	dx,al
		mov	al,20h
		out	dx,al
		mov	dx,3c4h
		mov	ax,0f02h
		out	dx,ax
	}
  */
	memset(vram,0,64000);
  /*
	_asm
	{
		mov	dx,3c4h
		mov	ax,0f02h
		out	dx,ax
	}
  */
	memset(vram,15,8000*8);
	ip=flash(-2);
	for(a=0;a<16;a++)
	{
		ip[a*3+0]=a*6/2;
		ip[a*3+1]=a*7/2;
		ip[a*3+2]=a*8/2;
	}

	while(!dis_exit() && dis_musplus()<-3) ;

	while(!dis_exit())
	{
		a=dis_musrow(0)&7;
		if(a==7) break;
	}

	for(b=0;b<4 && !dis_exit();b++)
	{	
		char *v;		
		int	zly,zy,zya;
		zy=0; zya=0; zly=0;
		for(a=256;a>-400;a-=32)
		{
			zly=zy;
			zya++;
			zy+=zya;
			v=vram+zly*320;
			for(y=zly;y<zy;y++)
			{
				memset(v+b*80,0,80);
				v+=320;
			}
			if(a>=0) flash(a);
			else flash(0);
		}

		while(!dis_exit())
		{
			a=dis_musrow(0)&7;
			if(a==7) break;
		}
		{
			flash(-1);
			flash(32);
			flash(64);
			flash(192);
			flash(256);
		}
	}
    }

	pic=halloc(20000,4);
	if(!pic) 
	{
		//_asm mov	ax,0
		//_asm int	10h
		printf("GENERAL WINDOWS VIOLATION - REMOVE WINDOWS.");
		//getch();
    return;
	}

	palfade=halloc(13000,1);
	dis_partstart();
	doit1(70*6);
	doit2(70*12);
	doit3(70*14);
	hfree(palfade);
	hfree(pic);

	if(!dis_indemo())
	{	
		_asm mov ax,3
		_asm int 10h
	}
	//return(0);
}

unsigned char planar_vram[ 4 ][ 8 ][ 40 * 200 ] = { 0 };

void resolve_16color( int page, int x_shift )
{
  // resolve 16 color planar mode (EGA) to chunky
  int idx = 0;
  char * dst = vram;
  int dst_stride = 320 - x_shift;
  int src_stride = ( x_shift + 7 ) >> 3;
  for ( int y = 0; y < 200; y++ )
  {
    memset( dst, 0, x_shift );
    dst += x_shift;
    for ( int x = 0; x < dst_stride; x++ )
    {
      char bit = ( x & 0x7 );
      unsigned char color = 0;
      color |= ( ( planar_vram[ 0 ][ page ][ idx ] ) & ( 1 << ( 7 - bit ) ) ) ? 1 : 0;
      color |= ( ( planar_vram[ 1 ][ page ][ idx ] ) & ( 1 << ( 7 - bit ) ) ) ? 2 : 0;
      color |= ( ( planar_vram[ 2 ][ page ][ idx ] ) & ( 1 << ( 7 - bit ) ) ) ? 4 : 0;
      color |= ( ( planar_vram[ 3 ][ page ][ idx ] ) & ( 1 << ( 7 - bit ) ) ) ? 8 : 0;
      *(dst++) = color;
      if ( bit == 7 ) idx++;
    }
    idx += src_stride;
  }
}

void sidescroll_256color( char * src, int x_shift )
{
  int idx = 0;
  char * dst = vram;
  if ( x_shift >= 0 )
  {
    int dst_stride = 320 - x_shift;
    for ( int y = 0; y < 400; y++ )
    {
      memset( dst, 0, x_shift );
      dst += x_shift;
      memcpy( dst, src, dst_stride );
      dst += dst_stride;
      src += 320;
    }
  }
  else
  {
    x_shift = -x_shift;
    int stride = 320 - x_shift;
    for ( int y = 0; y < 400; y++ )
    {
      src += x_shift;
      memcpy( dst, src, stride );
      src += stride;
      memset( dst, 0, x_shift );
      dst += 320;
    }
  }
}

int	doit1( int count )
{
	int	rot=45;
	int	x,y,c,x1,y1,x2,y2,x3,y3,x4,y4,a,hx,hy,vx,vy,cx,cy;
	int	vma,vm;
	vm=50; vma=0;
	waitborder();
	plv=0; pl=1;
  while ( !dis_exit() && count > 0 )
	{
		count-=waitborder();
		//setborder(1);
		memset(vbuf,0,8000);
		{
			hx=koe_sin1024[(rot+0)&1023]*16*6/5;
			hy=koe_sin1024[(rot+256)&1023]*16;
			vx=koe_sin1024[(rot+256)&1023]*6/5;
			vy=koe_sin1024[(rot+512)&1023];
			vx=vx*vm/100;
			vy=vy*vm/100;
			for(c=-10;c<11;c+=2)
			{
				cx=vx*c*2; cy=vy*c*2;
				x1=(-hx-vx+cx)/16+160; y1=(-hy-vy+cy)/16+100;
				x2=(-hx+vx+cx)/16+160; y2=(-hy+vy+cy)/16+100;
				x3=(+hx+vx+cx)/16+160; y3=(+hy+vy+cy)/16+100;
				x4=(+hx-vx+cx)/16+160; y4=(+hy-vy+cy)/16+100;
				asmbox(x1,y1,x2,y2,x3,y3,x4,y4);
			}
			rot+=2;
			vm+=vma;
			if(vm<25) 
			{
				vm-=vma;
				vma=-vma;
			}
			vma--;
		}
		//_asm mov dx,3c4h
		//_asm mov ah,pl
		//_asm mov al,2
		//_asm out dx,ax
    //asmdoit(vbuf,vram);
    asmdoit( vbuf, planar_vram[ pl ][ plv ] );
    resolve_16color( plv, 0 );

		a=plv*0x20;
		//_asm mov dx,3d4h
		//_asm mov al,0ch
		//_asm mov ah,byte ptr a
		//_asm out dx,ax
		plv++; plv&=7;
		//vram=(char *)(0xa0000000L+0x2000000L*(long)plv);
		if(!plv)
		{
      pl = ( pl + 1 ) & 3;
			//pl<<=1;
			//if(pl>15) pl=1;
		}
    demo_blit();
		//setborder(0);
	}
  return 0;
}

int	doit2(int count)
{
	int	rot=50,rota=10;
	int	x,y,c,x1,y1,x2,y2,x3,y3,x4,y4,a,hx,hy,vx,vy,cx,cy;
	int	vma,vm;
	vm=100*64; vma=0;
	waitborder();
	plv=0; pl=1;
  while ( !dis_exit() && count > 0 )
	{
		count-=waitborder();
		//setborder(1);
		memset(vbuf,0,8000);		
		{
			hx=koe_sin1024[(rot+0)&1023]*16*6/5;
			hy=koe_sin1024[(rot+256)&1023]*16;
			vx=koe_sin1024[(rot+256)&1023]*6/5;
			vy=koe_sin1024[(rot+512)&1023];
			vx=vx*(vm/64)/100;
			vy=vy*(vm/64)/100;
			for(c=-10;c<11;c+=2)
			{
				cx=vx*c*2; cy=vy*c*2;
				x1=(-hx-vx+cx)/16+160; y1=(-hy-vy+cy)/16+100;
				x2=(-hx+vx+cx)/16+160; y2=(-hy+vy+cy)/16+100;
				x3=(+hx+vx+cx)/16+160; y3=(+hy+vy+cy)/16+100;
				x4=(+hx-vx+cx)/16+160; y4=(+hy-vy+cy)/16+100;
				asmbox(x1,y1,x2,y2,x3,y3,x4,y4);
			}
			rot+=rota/10;
			vm+=vma;
			if(vm<0) 
			{
				vm-=vma;
				vma=-vma;
			}
			vma--;
			rota++;
		}
		//_asm mov dx,3c4h
		//_asm mov ah,pl
		//_asm mov al,2
		//_asm out dx,ax
    asmdoit( vbuf, planar_vram[ pl ][ plv ] );
    resolve_16color( plv, 0 );

    a = plv * 0x20;
		//_asm mov dx,3d4h
		//_asm mov al,0ch
		//_asm mov ah,byte ptr a
		//_asm out dx,ax
		plv++; plv&=7;
		//vram=(char *)(0xa0000000L+0x2000000L*(long)plv);
		if(!plv)
		{
      pl = ( pl + 1 ) & 3;
      //pl<<=1;
      //if(pl>15) pl=1;
    }
    demo_blit();
		//setborder(0);
	}
  return 0;
}

int	doit3(int count)
{
	int	rot=45,rota=10,rot2=0;
	int	x,y,c,x1,y1,x2,y2,x3,y3,x4,y4,a,b,hx,hy,vx,vy,cx,cy,wx,wy;
	int	vma,vm,xpos=320,xposa=0;
	int	ripple,ripplep,repeat=1;
	char	*p;
	vm=100*64; vma=0;
	waitborder();
	shim_outp(0x3c8,0);
	for(a=0;a<16*3;a++) shim_outp(0x3c9,0);
  /*
	_asm
	{
		mov	dx,3c4h
		mov	ax,0f02h
		out	dx,ax
	}
  */
	//vram=(char *)(0xa0000000L);
	memset(vram,0,32768);
	memset(vram+32768,0,32768);
  /*
	_asm 
	{
		mov	dx,3d4h
		mov	ax,0dh+256*40
		out	dx,ax
		mov	ax,0ch+256*0
		out	dx,ax
		mov	ax,13h+256*40
		out	dx,ax
	}
  */
	//vram=(char *)(0xa0000000L+40);
	plv=0; pl=1;
	while(!dis_exit() && count>0)
	{
		a=dis_getmframe();
    /*
		if(a>2520) 
		{
			if(xpos!=0) xpos=0;
			else break;
		}
    */
		if(count<333) 
		{
			while(repeat--)
			{
				xpos-=xposa/4;
				if(xpos<0) xpos=0;
				else xposa++;
			}
			if(xpos==0) break;
		}
		if(rot2<32)
		{
			wx=koe_sin1024[(rot2+0)&1023]*rot2/8+160;
			wy=koe_sin1024[(rot2+256)&1023]*rot2/8+100;
		}
		else
		{
			wx=koe_sin1024[(rot2+0)&1023]/4+160;
			wy=koe_sin1024[(rot2+256)&1023]/4+100;
		}
		rot2+=17;
		a=xpos/8;
		//_asm mov dx,3d4h
		//_asm mov ah,byte ptr a
		//_asm mov al,0dh
		//_asm out dx,ax
		count-=(repeat=waitborder());
		a=xpos&7;
		//_asm mov dx,3dah
		//_asm in al,dx
		//_asm mov dx,3c0h
		//_asm mov al,13h
		//_asm out dx,al
		//_asm mov al,byte ptr a
		//_asm out dx,al
		//_asm mov al,20h
		//_asm out dx,al
		//setborder(1);
		memset(vbuf,0,8000);		
		{
			hx=koe_sin1024[(rot+0)&1023]*16*6/5;
			hy=koe_sin1024[(rot+256)&1023]*16;
			vx=koe_sin1024[(rot+256)&1023]*6/5;
			vy=koe_sin1024[(rot+512)&1023];
			vx=vx*(vm/64)/100;
			vy=vy*(vm/64)/100;
			for(c=-10;c<11;c+=2)
			{
				cx=vx*c*2; cy=vy*c*2;
				x1=(-hx-vx+cx)/16+wx; y1=(-hy-vy+cy)/16+wy;
				x2=(-hx+vx+cx)/16+wx; y2=(-hy+vy+cy)/16+wy;
				x3=(+hx+vx+cx)/16+wx; y3=(+hy+vy+cy)/16+wy;
				x4=(+hx-vx+cx)/16+wx; y4=(+hy-vy+cy)/16+wy;
				asmbox(x1,y1,x2,y2,x3,y3,x4,y4);
			}
			rot+=rota/10;
			{
				vm+=vma;
				if(vm<0)
				{
					vm-=vma;
					vma=-vma;
				}
				vma--;
			}
			rota++;
		}
		//_asm mov dx,3c4h
		//_asm mov ah,pl
		//_asm mov al,2
		//_asm out dx,ax
		//asmdoit2(vbuf,vram);
    asmdoit( vbuf, planar_vram[ pl ][ plv ] );
    resolve_16color( plv, 320 - xpos );
    
		a=plv*0x20;
		//_asm mov dx,3d4h
		//_asm mov al,0ch
		//_asm mov ah,byte ptr a
		//_asm out dx,ax
		plv+=2; plv&=7;
		//vram=(char *)(0xa0000000L+0x2000000L*(long)plv+40);
		if(!plv)
		{
      pl = ( pl + 1 ) & 3;
      //pl<<=1;
      //if(pl>15) pl=1;
    }
    demo_blit();
		//setborder(0);
	}

	//_asm mov ax,13h
	//_asm int 10h
	//inittwk();
  demo_changemode( 320, 400 );
  memset( shim_vram, 0, 320 * 400 );
  demo_blit();
  /*
	_asm 
	{
		mov	dx,3d4h
		mov	ax,13h+256*80
		out	dx,ax
	}
  */
	//vram=(char *)(0xa0000000L);

	if(dis_exit()) return 0;
	
	{
		FILE	*h;
		char	*p=pic;
		h=blob_fopen("troll.up","rb");
		dis_waitb();
		blob_fread(p,40000,1,h);
		dis_waitb();
		//_asm add word ptr p[2],40000/16
    p+=40000;
		blob_fread(p,40000,1,h);
		blob_fclose(h);
	}

	dis_waitb();

  char picdata[ 320 * 400 ];
	readp(palette,-1,pic);
	for(y=0;y<400;y++)
	{
		readp(picdata+y*320,y,pic);
		//koe_lineblit(vram+80U+(unsigned)y*160U,rowbuf);
	}
	
	p=palfade;
	for(y=0;y<16;y++)
	{
		x=(45-y*3);
		for(a=0;a<768;a++)
		{
			c=palette[a]+x;
			if(c>63) c=63;
			*p++=c;
		}
	}

	dis_waitb();
  demo_blit();
	setpalarea(palette,0,256);

  while(!dis_exit())
	{
    /*
		_asm
		{
			mov	bx,6
			int	0fch
			mov	b,bx
			mov	a,cx
		}
    */
    b = dis_musrow(0);
    a = dis_musorder(0);
    demo_blit();
		if(a>35 || (a==35 && b>48)) break;
	}
  
	count=300;
	xposa=0; xpos=0;
	while(!dis_exit() && count>0)
	{
		if(xpos==320) break;
		xpos+=xposa/4;
		if(xpos>320) xpos=320;
		else xposa++;
		a=xpos/4;
		//_asm mov dx,3d4h
		//_asm mov ah,byte ptr a
		//_asm mov al,0dh
		//_asm out dx,ax
		count-=dis_waitb();
		a=(xpos&3)*2;
		//_asm mov dx,3dah
		//_asm in al,dx
		//_asm mov dx,3c0h
		//_asm mov al,13h
		//_asm out dx,al
		//_asm mov al,byte ptr a
		//_asm out dx,al
		//_asm mov al,20h
		//_asm out dx,al
    sidescroll_256color( picdata, 320 - xpos );
    demo_blit();
	}
	count=50; c=0;
	ripple=0; ripplep=8;
	while(!dis_exit() && count>0)
	{
		if(ripplep>1023) ripplep=1024;
		else ripplep=ripplep*5/4;
		xpos=320+koe_sin1024[ripple&1023]/ripplep;
		ripple+=ripplep+100;
		a=xpos/4;
		//_asm mov dx,3d4h
		//_asm mov ah,byte ptr a
		//_asm mov al,0dh
		//_asm out dx,ax
		count-=dis_waitb();
		a=(xpos&3)*2;
		//_asm mov dx,3dah
		//_asm in al,dx
		//_asm mov dx,3c0h
		//_asm mov al,13h
		//_asm out dx,al
		//_asm mov al,byte ptr a
		//_asm out dx,al
		//_asm mov al,20h
		//_asm out dx,al
		if(c<16)
		{
			setpalarea(palfade+c*768,0,256);
			c++;
		}
    sidescroll_256color( picdata, 320 - xpos );
    demo_blit();
	}
	setpalarea(palette,0,256);
	count=420; xpos=320;
	while(!dis_exit() && count>0)
	{
		a=dis_musplus();
		if(a>-6 && a<16) break;
		a=xpos/4;
		//_asm mov dx,3d4h
		//_asm mov ah,byte ptr a
		//_asm mov al,0dh
		//_asm out dx,ax
		count-=dis_waitb();
		a=(xpos&3)*2;
		//_asm mov dx,3dah
		//_asm in al,dx
		//_asm mov dx,3c0h
		//_asm mov al,13h
		//_asm out dx,al
		//_asm mov al,byte ptr a
		//_asm out dx,al
		//_asm mov al,20h
		//_asm out dx,al
    sidescroll_256color( picdata, 320 - xpos );
    demo_blit();
	}
  return 0;
}

