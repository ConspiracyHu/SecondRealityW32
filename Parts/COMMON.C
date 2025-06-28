#include <memory.h>
#include "../shims.h"

struct st_readp
{
	short	magic;
	short	wid;
	short	hig;
	short	cols;
	short	add;
};

void	readp(char *dest,int row,char *src)
{
	int	bytes,a,b;
	struct st_readp *hdr;
	hdr=(struct st_readp *)src;
	if(row==-1)
	{
		memcpy(dest,src+16,hdr->cols*3);
		return;
	}
	if(row>=hdr->hig) return;
	src+=hdr->add*16;
	while(row)
	{
		src+=*(short *)src;
		src+=2;
		row--;
	}
	bytes=*(short *)src;
	src+=2;
	_asm
	{
		push	esi
		push	edi
		mov	ecx,bytes
		mov esi,src
		add	ecx,esi
		mov edi,dest
	l1:	mov	al,[esi]
		inc	esi
		or	al,al
		jns	l2
		mov	ah,al
		and	ah,7fh	
		mov	al,[esi]
		inc	esi
	l4:	mov	[edi],al
		inc	edi
		dec	ah
		jnz	l4
		cmp	esi,ecx
		jb	l1
		jmp	l3
	l2:	mov	[edi],al
		inc	edi
		cmp	esi,ecx
		jb	l1
	l3:
		pop	edi
		pop	esi
	}
}

void setpalarea( char * p, int offset, int count )
{
  shim_outp( 0x3c8, offset );
  for ( int c = 0; c < count * 3; c++ ) shim_outp( 0x3c9, p[ c ] );
}

void getpalarea( char * p, int offset, int count )
{
  shim_outp( 0x3c8, offset );
  for ( int c = 0; c < count * 3; c++ ) p[ c ] = shim_inp( 0x3c9 );
}

//extern	init_copper();
//extern	close_copper();
int frame_count;
char * cop_pal;
int do_pal;
int cop_start;
int cop_scrl;
int cop_dofade;
short * cop_fadepal;
short fadepal[ 256 * 3 ] = { 0 };
int cop_drop;

void copper2()
{
  if ( do_pal )
  {
    for ( int i = 0; i < 256; i++ )
    {
      //setpalarea( cop_pal, 0, 256 );
      shim_setpal( i, cop_pal[ i * 6 + 1 ], cop_pal[ i * 6 + 3 ], cop_pal[ i * 6 + 5 ] );
    }
    do_pal = 0;
  }
}

void copper3()
{
  if ( cop_dofade )
  {
    do_pal = 1;
  }
  if ( do_pal )
  {
    cop_pal = fadepal;
    for ( int i = 0; i < 768; i++ )
    {
      fadepal[ i ] += cop_fadepal[ i ];
    }
    cop_dofade--;
  }
}