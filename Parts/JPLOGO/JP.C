#include <stdio.h>
#include <string.h>
#include "..\dis\dis.h"
#include "..\common.h"
#include "..\..\shims.h"

FILE	*f1;

//#include "readp.c"

extern char jl_pic[];

extern void jl_setborder(int);
extern void inittwk();
extern void linezoom(char * dst, char * src, int);

#define vram shim_paged_vram_scratch

char	rowdata1[200][186];
char	rowdata2[200][186];
char	*row[400];

char	pal2[768];
char	palette[768];
char	rowbuf[640];

extern short jl_sin1024[];

int	framey1[200];
int	framey2[200];
int	framey1t[800];
int	framey2t[800];
int	lasty[400];
int	lasts[400];

void	scrolly(int y)
{
	int	a;
	a=y*80;
  shim_setstartpixel( a * 4 );
//	_asm
//	{
//		mov	dx,3d4h
//		mov	al,0dh
//		mov	ah,byte ptr a[0]
//		out	dx,ax
//		mov	dx,3d4h
//		mov	al,0ch
//		mov	ah,byte ptr a[1]
//		out	dx,ax
//	}
}

char	*shiftstatus=(char *)0x0417;
inline int	waitb()
{
	return(dis_waitb());
}

int	calc(int y,int c)
{
	_asm
	{
		mov	eax,[y]
		sub	ax,400
		add	eax,[c]
		mov	dx,400
		imul	dx
		mov	ecx,[c]
		idiv	cx
	} 
}

unsigned int lens_current_plane_mask = 0;
unsigned char * lens_scanline_chunky = 0;
unsigned char lens_scanline_plane_buffer[ 80 ];
unsigned char * lens_scanline_plane_bufferptr = lens_scanline_plane_buffer;
void __declspec( naked ) lens_demux_scanline()
{
  __asm
  {
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad

    mov ebx, [lens_current_plane_mask]
    test ebx, 1
    jz _not1
      mov esi, lens_scanline_plane_bufferptr
      mov edi, lens_scanline_chunky
      mov ecx, 80

      da_loop_1:
        movsb
        add edi, 3
      loop da_loop_1
    _not1:

    test ebx, 2
    jz _not2
      mov esi, lens_scanline_plane_bufferptr
      mov edi, lens_scanline_chunky
      inc edi
      mov ecx, 80

      da_loop_2:
        movsb
        add edi, 3
      loop da_loop_2
    _not2:

    test ebx, 4
    jz _not3
      mov esi, lens_scanline_plane_bufferptr
      mov edi, lens_scanline_chunky
      add edi, 2
      mov ecx, 80

      da_loop_3:
        movsb
        add edi, 3
      loop da_loop_3
    _not3:

    test ebx, 8
    jz _not4
      mov esi, lens_scanline_plane_bufferptr
      mov edi, lens_scanline_chunky
      add edi, 3
      mov ecx, 80

      da_loop_4:
        movsb
        add edi, 3
      loop da_loop_4
    _not4:

    movzx eax, al
    mov [lens_current_plane_mask], eax

    popad
    mov esp, ebp
    pop ebp
    retn
  }
}

void	doit(void)
{
	int	frame=0,halt=0,storea=0,ysb=0;
	int	a,b,c,y,ysz,ysza,xsc,spd=10,la,y1,y2;
 	if (!demo_isfirstpart())
 	{
 		while(!dis_exit() && dis_musplus()<4);
 	}
 	while(!dis_exit() && frame<700)
	{
		//if(*shiftstatus&16) jl_setborder(0);
		c=waitb();
		//if(*shiftstatus&16) jl_setborder(127);
		frame+=c;
		if(frame>511) c=400;
		else 
		{
			y1=framey1t[frame]/16;
			y2=framey2t[frame]/16;
		}
		xsc=(400-(y2-y1))/8;
		for(y=0;y<400;y++)
		{
			if(y<y1 || y>=y2)
			{
        lens_scanline_chunky = shim_vram + y * 320;
        linezoom(lens_scanline_plane_buffer,NULL,0);
        __asm
        {
          xor al, al
          call lens_demux_scanline
        }
      }
			else 
			{
				b=(long)(y-y1)*400L/(long)(y2-y1);
				a=184+(jl_sin1024[b*32/25]*xsc+32)/64;
				a&=~1;
				if(lasty[y]!=b || lasts[y]!=a)
				{
          lens_scanline_chunky = shim_vram + y * 320;
					linezoom(lens_scanline_plane_buffer,row[b],a);
          __asm
          {
            xor al, al
            call lens_demux_scanline
          }
          lasty[ y ] = b;
					lasts[y]=a;
				}
			}
		}
    demo_blit();
	}
}

int jplogo_main()
{
	int	frame,halt=0,storea=0;
	int	a,b,c,d,y,ya,ysz,ysza,xsc,spd=10,la;
	int	y1,y2,y1a,y2a,ly1a,mika;
	dis_partstart();

	for(a=0;a<200;a++) row[a]=rowdata1[a];
	for(a=0;a<200;a++) row[a+200]=rowdata2[a];

	frame=0;
	ysz=400*16; ysza=-460/6;
	y=0;
	y1=0; y1a=500;
	y2=399*16; y2a=500;
	mika=1;
	for(frame=0;frame<200;frame++)
	{	
		if(!halt)
		{
			y1+=y1a;
			y2+=y2a;
	
			y2a+=16;
			if(y2>400*16)
			{
				y2-=y2a;
				y2a=-y2a*mika/8;
				if(mika<4) mika+=3;
			}
	
			y1a+=16;
			
			la=a;
			a=(y2-y1)-400*16;
			if((a&0x8000)^(la&0x8000))
			{
				y1a=y1a*7/8;
			}
			y1a+=a/8;
			y2a-=a/8;
		}
		
		if(frame>90) 
		{
			if(y2>=399*16) 
			{
				y2=400*16;
				halt=1;
			}
			else y2a=8;
			y1=y2-400*16;
		}

		framey1[frame]=y1;
		framey2[frame]=y2;
	}
	for(a=0;a<800;a++)
	{
		b=a/4;
		c=a&3;
		d=3-c;
		framey1t[a]=(framey1[b]*d+framey1[b+1]*c)/3;
		framey2t[a]=(framey2[b]*d+framey2[b+1]*c)/3;
	}

	//_asm mov ax,13h
	//_asm int 10h	
	//inittwk();
	//_asm
	//{
	//	mov	dx,3c0h
	//	mov	al,11h
	//	out	dx,al
	//	mov	al,255
	//	out	dx,al
	//	mov	al,20h
	//	out	dx,al
	//}

	readp(palette,-1,jl_pic);
	palette[64*3+0]=0;
	palette[64*3+1]=0;
	palette[64*3+2]=0;
	for(y=0;y<400;y++)
	{
		readp(rowbuf,y,jl_pic);
		memcpy(row[y],rowbuf+70,184);
		row[y][184]=65;
	}
	setpalarea(palette,0,256);
	for(a=0;a<400;a++)
	{
		for(b=0;b<184;b++) if(row[a][b]==0) row[a][b]=64;
	}
	
	for(y=0;y<400;y++) lasty[y]=lasts[y]=-1;
	dis_waitb();
	scrolly(400);
	dis_waitb();
  for ( y = 0; y < 400; y++ )
	{
    lens_scanline_chunky = shim_vram + y * 320;
		linezoom(lens_scanline_plane_buffer,row[y],184);
    __asm
    {
      xor al, al
      call lens_demux_scanline
    }
	}
	a=64; y=400*64;
	while(y>0)
	{
		y-=a;
		a+=6;
		if(y<0) y=0;
    scrolly(y/64);
		dis_waitb();
    demo_blit();
	}
	storea=a;
	dis_waitb();
	doit();
  scrolly(0);
	//_asm mov ax,3
	//_asm int 10h
	//printf("%i\n",storea);
	return(0);
}
