#include <memory.h>
#include "../../shims.h"

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
		add	cx,si
		mov edi,dest
	l1:	mov	al,[esi]
		inc	si
		or	al,al
		jns	l2
		mov	ah,al
		and	ah,7fh	
		mov	al,[esi]
		inc	si
	l4:	mov	[edi],al
		inc	di
		dec	ah
		jnz	l4
		cmp	si,cx
		jb	l1
		jmp	l3
	l2:	mov	[edi],al
		inc	di
		cmp	si,cx
		jb	l1
	l3:
		pop	edi
		pop	esi
	}
}
