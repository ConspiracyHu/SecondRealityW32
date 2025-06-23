#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <conio.h>
#include <string.h>
#include <malloc.h>
#include "..\cd.h"
#include "..\c.h"
#include "..\..\dis\dis.h"
#include "u2common.h"

int	indemo=0;

char	tmpname[64];

char *scene0;
char *scenem;

int	city=0;
int	xit=0;

s_scl scenelist[64];
int scl=0,sclp=0;

char	fpal[768];

s_co co[MAXOBJ];
int conum;

FILE	*fr;

object camobject;
rmatrix cam;

int	order[MAXOBJ],ordernum;
unsigned char *sp;

s_cl cl[4];
int	clr=0,clw=0;
int	firstframe=1;
int	deadlock=0;
int	coppercnt=0;
int	syncframe=0;
int	currframe=0;
int	copperdelay=16;
int	repeat,avgrepeat;

long lsget(unsigned char f)
{
	long	l;
	switch(f&3)
	{
	case 0 : l=0; 
		 break; 
	case 1 : l=(long)(char)(*sp++); 
		 break;
	case 2 : l=*sp++; 
		 l|=(long)(char)(*sp++)<<8; 
		 break;
	case 3 : l=*sp++;
		 l|=(long)(*sp++)<<8; 
		 l|=(long)(*sp++)<<16; 
		 l|=(long)(char)(*sp++)<<24; 
		 break;
	}
	return(l);
}		

void	resetscene(void)
{
	int	a;
	sp=(unsigned char *)(scenelist[sclp].data);
	for(a=0;a<conum;a++)
	{
		memset(co[a].o->r,0,sizeof(rmatrix));
		memset(co[a].o->r0,0,sizeof(rmatrix));
	}
	sclp++;
	if(sclp>=scl)
	{
		sclp=0;
	}
}

//////////////////////////////////////////////////////////////////////////////

void	*getmem(long size)
{
	void	*p;
  /*
	if(size>160000L)
	{
		printf("GETMEM: attempting to reserved >160K (%li byte block)\n",size);
		exit(3);
	}
  */
	p=halloc(size/16L+1,16);
	if(!p)
	{
		printf("GETMEM: out of memory (%li byte block)\n",size);
		exit(3);
	}
	return(p);
}

void	freemem(void *p)
{
	hfree(p);
}

char	*readfile(char *name)
{
	FILE	*f1;
	long	size;
	char *p,*p0;
  f1=fopen(name,"rb");
	if(!f1)
	{
		printf("File '%s' not found.",name);
		exit(3);
	}
	fseek(f1,0L,SEEK_END);
	p0=p=getmem(size=ftell(f1));
	fseek(f1,0L,SEEK_SET);
  /*
	if(size>128000)
	{
		fread(p,64000,1,f1);
		size-=64000; 
		_asm add word ptr p[2],4000
		fread(p,64000,1,f1);
		size-=64000; 
		_asm add word ptr p[2],4000
		fread(p,(size_t)size,1,f1);
	}
	else if(size>64000)
	{
		fread(p,64000,1,f1);
		size-=64000; 
		_asm
		{
			add word ptr p[2],4000
		}
		fread(p,(size_t)size,1,f1);
	}
	else
  */
  fread(p,(size_t)size,1,f1);
	fclose(f1);
	return(p0);
}
