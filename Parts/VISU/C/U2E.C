#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <conio.h>
#include <string.h>
#include <malloc.h>
#include "..\..\dis\dis.h"
#include "..\..\..\shims.h"
#include "..\..\common.h"
#include "..\cd.h"
#include "..\c.h"
#include "u2common.h"

#define	noDEBUG

char	u2e_scene[64]={"U2E"};

void border(int r,int g,int b)
{
	shim_outp(0x3c8,255);
	shim_outp(0x3c9,r);
	shim_outp(0x3c9,g);
	shim_outp(0x3c9,b);
}

#pragma check_stack(off)

void u2e_copper2(void)
{
	int	a,c1,c2,c3,c4;
	
	syncframe++;

	if(cl[0].ready==2) cl[0].ready=0;
	if(cl[1].ready==2) cl[1].ready=0;
	if(cl[2].ready==2) cl[2].ready=0;
	if(cl[3].ready==2) cl[3].ready=0;

	deadlock++;
	coppercnt++;

	if(copperdelay>0)
	{
		copperdelay--;
	}
	if(copperdelay>0) return;
	copperdelay=0;
	if(cl[clr].ready)
	{
		cl[(clr-1)&3].ready=2;
		//vid_setswitch(-1,clr);
		copperdelay=cl[clr].frames;
		clr++; clr&=3;
	}
	else avgrepeat++;
}

void	fadeset(char *vram)
{
	int	y;
	shim_outp(0x3c4,2);
	shim_outp(0x3c5,15);
	for(y=0;y<25;y++)
	{
		memset(vram+(y*2+0)*320+0,0,17*4);
		memset(vram+(y*2+1)*320+0,0,17*4);
		memset(vram+(y*2+0)*320+17*4,252,47*4);
		memset(vram+(y*2+1)*320+17*4,252,47*4);
		shim_outp(0x3c4,2);
		shim_outp(0x3c5,2+4+8);
		*(vram+(y*2+0)*320+63*4+1)=0;
		*(vram+(y*2+0)*320+63*4+2)=0;
		*(vram+(y*2+0)*320+63*4+3)=0;
		*(vram+(y*2+1)*320+63*4+1)=0;
		*(vram+(y*2+1)*320+63*4+2)=0;
		*(vram+(y*2+1)*320+63*4+3)=0;
		shim_outp(0x3c4,2);
		shim_outp(0x3c5,15);
		memset(vram+(y*2+0)*320+252*4,0,16*4);
		memset(vram+(y*2+1)*320+252*4,0,16*4);
	}
	for(y=25;y<175;y++)
	{
		memset(vram+(y*2+0)*320+0,254,17*4);
		memset(vram+(y*2+1)*320+0,254,17*4);
		memset(vram+(y*2+0)*320+17*4,253,47*4);
		memset(vram+(y*2+1)*320+17*4,253,47*4);
		shim_outp(0x3c4,2);
		shim_outp(0x3c5,2+4+8);
		*(vram+(y*2+0)*320+63*4+1)=254;
		*(vram+(y*2+0)*320+63*4+2)=254;
		*(vram+(y*2+0)*320+63*4+3)=254;
		*(vram+(y*2+1)*320+63*4+1)=254;
		*(vram+(y*2+1)*320+63*4+2)=254;
		*(vram+(y*2+1)*320+63*4+3)=254;
		shim_outp(0x3c4,2);
    shim_outp(0x3c5,15);
		memset(vram+(y*2+0)*320+64*4,254,16*4);
		memset(vram+(y*2+1)*320+64*4,254,16*4);
	}
	for(y=175;y<200;y++)
	{
		memset(vram+(y*2+0)*320+0,0,17*4);
		memset(vram+(y*2+1)*320+0,0,17*4);
		memset(vram+(y*2+0)*320+17*4,252,47*4);
		memset(vram+(y*2+1)*320+17*4,252,47*4);
		shim_outp(0x3c4,2);
		shim_outp(0x3c5,2+4+8);
		*(vram+(y*2+0)*320+63*4+1)=0;
		*(vram+(y*2+0)*320+63*4+2)=0;
		*(vram+(y*2+0)*320+63*4+3)=0;
		*(vram+(y*2+1)*320+63*4+1)=0;
		*(vram+(y*2+1)*320+63*4+2)=0;
		*(vram+(y*2+1)*320+63*4+3)=0;
		shim_outp(0x3c4,2);
		shim_outp(0x3c5,15);
		memset(vram+(y*2+0)*320+64*4,0,16*4);
		memset(vram+(y*2+1)*320+64*4,0,16*4);
	}
}

void u2e_main()
{
	char *sptemp;
  short *ip;
	unsigned int u;
	char	*cp;
	int	jellywas=0;
	int	a,b,c,d,e,f,g,x,y,z;
	#ifdef DEBUG
	fr=blob_fopen("tmp","wt");
	#endif
	indemo=1;

  /*
	_asm
	{
		mov	ah,0fh
		int	10h
		xor	ah,ah
		mov	a,ax
	}
  */
	/*if(a>3) */jellywas=1;

	//dis_partstart();
	sprintf(tmpname,"%s.00M",u2e_scene);
	if(!indemo) printf("Loading materials %s...\n",tmpname);
	scene0=scenem=readfile(tmpname);

	if(scene0[15]=='C') city=1;
	if(scene0[15]=='R') city=2;
	ip=(short *)(scene0+LONGAT(scene0+4));
	conum=d=*ip++;
	for(f=-1,c=1;c<d;c++)
	{	
		e=*ip++;
		if(e>f)
		{
			f=e;
			sprintf(tmpname,"%s.%03i",u2e_scene,e);
			if(!indemo) printf("Loading %s... ",tmpname);
			co[c].o=vis_loadobject(tmpname);
			memset(co[c].o->r,0,sizeof(rmatrix));
			memset(co[c].o->r0,0,sizeof(rmatrix));
			co[c].index=e;
			co[c].on=0;
			if(!indemo) printf("(co[%i]:%s)\n",c,co[c].o->name);
		}
		else
		{
			if(!indemo) printf("Copying %s.%03i... ",u2e_scene,e);
			for(g=0;g<c;g++) if(co[g].index==e) break;
			memcpy(co+c,co+g,sizeof(s_co));
			co[c].o=getmem(sizeof(object));
			memcpy(co[c].o,co[g].o,sizeof(object));
			co[c].o->r=getmem(sizeof(rmatrix));
			co[c].o->r0=getmem(sizeof(rmatrix));
			memset(co[c].o->r,0,sizeof(rmatrix));
			memset(co[c].o->r0,0,sizeof(rmatrix));
			co[c].on=0;
			if(!indemo) printf("(co[%i]:%s)\n",c,co[c].o->name);
		}
	}
	co[0].o=&camobject;
	camobject.r=&cam;
	camobject.r0=&cam;

	sprintf(tmpname,"%s.0AA",u2e_scene);
	if(!indemo) printf("Loading animations...\n");
	ip=readfile(tmpname);
  scl=0;
	while(*ip)
	{
		a=*ip;
		if(a==-1) break;
		sprintf(tmpname,"%s.0%c%c",u2e_scene,a/10+'A',a%10+'A');
		if(!indemo) printf("Scene: %s ",tmpname);
		scenelist[scl].data=readfile(tmpname);
		if(!indemo) printf("(%i:@%Fp)\n",scl,scenelist[scl].data);
		scl++;
		ip+=2;
	}

	if(!indemo) 
	{
		printf("Press any key to continue...");
		//getch();
	}	

	resetscene();

    	if(!jellywas) 
	{
		vid_init(1);
		for(a=0;a<768;a++) fpal[a]=0;
		for(a=3;a<64*3;a++) fpal[a]=63;
	}
	else
	{
		shim_outp(0x3c7,0);
		for(a=0;a<768;a++) fpal[a]=shim_inp(0x3c9);
	}
	
	for(b=0;b<33;b++)
	{
		for(a=3;a<768-6;a++) 
		{
			fpal[a]+=2;
			if(fpal[a]>63) fpal[a]=63;
		}
		dis_waitb();
    shim_outp(0x3c8,0);
		for(a=0;a<768;a++) shim_outp(0x3c9,fpal[a]);
    demo_blit();
	}

	for(b=0;b<16;b++)
	{
		dis_waitb();
	}
	
	{
		fadeset((char *)shim_vram);
    /*
		dis_waitb();
    shim_outp(0x3d4,9);
		a= shim_inp(0x3d5);
		a=(a&0xf0)|0x80;
    shim_outp(0x3d5,a);
		dis_waitb();
		fadeset((char *)shim_vram);
		fadeset((char *)shim_vram);
		fadeset((char *)shim_vram);
    */
	}

	for(b=0;b<16;b++)
	{
		dis_waitb();
	}
	
	for(b=0;b<33;b++)
	{
		for(a=3;a<768-9;a++) 
		{
			fpal[a]-=2;
			if(fpal[a]<0) fpal[a]=0;
		}
		for(a=768-9;a<768-3;a++) 
		{
			fpal[a]+=2;
			if(fpal[a]>63) fpal[a]=63;
		}
		dis_waitb();
    shim_outp(0x3c8,0);
		for(a=0;a<768;a++) shim_outp(0x3c9,fpal[a]);
    demo_blit();
	}
	demo_changemode( 320, 200 );
	vid_init(11);
	cp=(char *)(scenem+16);
	cp[255*3+0]=0;
	cp[255*3+1]=0;
	cp[255*3+2]=0;
	cp[252*3+0]=0;
	cp[252*3+1]=0;
	cp[252*3+2]=0;
	cp[253*3+0]=63;
	cp[253*3+1]=63;
	cp[253*3+2]=63;
	cp[254*3+0]=63;
	cp[254*3+1]=63;
	cp[254*3+2]=63;
	vid_setpal(cp);
	vid_window(0L,319L,25L,174L,512L,9999999L);

	dis_setcopper(2,u2e_copper2);
	dis_partstart();
	xit=0;
  currframe=0;

	while(!dis_exit())
	{
		a = dis_musorder(0);
		if(a>18) break;
	}
	
	coppercnt=0;
	syncframe=0;
	avgrepeat=1;
	cl[0].ready=0;
	cl[1].ready=0;
	cl[2].ready=0;
	cl[3].ready=1;
	
	int fov = 0;
	while(!dis_exit() && !xit)
	{
		int onum;
		long pflag;
		long dis;
		long l;
		object *o;
		rmatrix *r;
    memset( shim_vram, 0, 320 * 200 );
	    if(!firstframe)
	    {
 		deadlock=0;
		//while(cl[clw].ready)
		//{
		//	if(deadlock>16) break;
		//}
		// Draw to free frame
		vid_setswitch(clw,-1);
		vid_clear255();
		// Field of vision
		vid_cameraangle(fov);
		// Calc matrices and add to order list (only enabled objects)
		ordernum=0;
		/* start at 1 to skip camera */
		for(a=1;a<conum;a++) if(co[a].on)
		{
			order[ordernum++]=a;
			o=co[a].o;
			memcpy(o->r,o->r0,sizeof(rmatrix));
			calc_applyrmatrix(o->r,&cam);
			b=o->pl[0][1]; // center vertex
			if(co[a].o->name[1]=='_') co[a].dist=1000000000L;
			else co[a].dist=calc_singlez(b,o->v0,o->r);
			if(currframe>900*2 && currframe<1100*2)
			{
				if(co[a].o->name[1]=='s' &&
				   co[a].o->name[2]=='0' &&
				   co[a].o->name[3]=='1')
				   	co[a].dist=1L;
			}
		}
		for(a=0;a<ordernum;a++) 
		{
			dis=co[c=order[a]].dist;
			for(b=a-1;b>=0 && dis>co[order[b]].dist;b--)
				order[b+1]=order[b];
			order[b+1]=c;
		}
		// Draw
		for(a=0;a<ordernum;a++)
		{
			int	x,y;
			o=co[order[a]].o;
			vis_drawobject(o);
		}
		// **** Drawing completed **** //
	    } else { syncframe=0; firstframe=0; coppercnt=1; }
		// calculate how many frames late of schedule
		a=(syncframe-currframe);
		repeat=a+1;
		if(repeat<0) repeat=0;
		if(repeat==0) cl[clw].frames=1;
		else cl[clw].frames=repeat;
		cl[clw].ready=1;
		clw++; clw&=3;
		// advance that many frames
		repeat=(repeat+1)/2;
		currframe+=repeat*2;
	    while(repeat-- && !xit)
	    {
		// parse animation stream for 1 frame
		onum=0;
		while(!xit)
		{
			a=*sp++;
			if(a==0xff)
			{
				a=*sp++;
				if(a<=0x7f)
				{
					fov=a<<8;
					break;
				}
				else if(a==0xff) 
				{
					resetscene();
					xit=1;
					continue;
				}
			}
			if((a&0xc0)==0xc0)
			{
				onum=((a&0x3f)<<4);
				a=*sp++;
			}
			onum=(onum&0xff0)|(a&0xf);
			b=0;
			switch(a&0xc0)
			{
			case 0x80 : b=1; co[onum].on=1; break;
			case 0x40 : b=1; co[onum].on=0; break;
			}
			
			#ifdef DEBUG
			if(b) fprintf(fr,"[%i (%s) ",onum,co[onum].on?"on":"off");
			else fprintf(fr,"[%i (--) ",onum,co[onum].on?"on":"off");
			#endif
			if(onum>=conum)
			{
				return;
			}
			
			r=co[onum].o->r0;
			
			pflag=0;
			switch(a&0x30)
			{
			case 0x00 : break;
			case 0x10 : pflag|=*sp++; break;
			case 0x20 : pflag|=sp[0]; 
				    pflag|=(long)sp[1]<<8; 
				    sp+=2; break;
			case 0x30 : pflag|=sp[0]; 
				    pflag|=(long)sp[1]<<8; 
				    pflag|=(long)sp[2]<<16; 
				    sp+=3; break;
			}
			
			#ifdef DEBUG
			fprintf(fr,"pfl:%06lX",pflag);
			#endif
			
			l=lsget(pflag);
			r->x+=l;
			l=lsget(pflag>>2);
			r->y+=l;
			l=lsget(pflag>>4);
			r->z+=l;
			
			#ifdef DEBUG
			fprintf(fr," XYZ:(%li,%li,%li)",r->x,r->y,r->z);
			#endif

			if(pflag&0x40)
			{ // word matrix
				for(b=0;b<9;b++) if(pflag&(0x80<<b))
				{
					r->m[b]+=lsget(2);
				}
			}
			else
			{ // byte matrix
				for(b=0;b<9;b++) if(pflag&(0x80<<b))
				{
					r->m[b]+=lsget(1);
				}
			}

			#ifdef DEBUG
			fprintf(fr,"]\n");
			#endif
		}
	    }
      demo_blit();
      dis_waitb();
      u2e_copper2();
	}
	dis_setcopper(2,NULL);

  shim_outp(0x3c7,0);
	for(a=0;a<768;a++) fpal[a]= shim_inp(0x3c9);
	for(b=0;b<16;b++)
	{
		for(a=0;a<768;a++) 
		{
			fpal[a]+=4;
			if(fpal[a]>63) fpal[a]=63;
		}
		dis_waitb();
    shim_outp(0x3c8,255);
		for(a=0;a<768;a++) shim_outp(0x3c9,fpal[a]);
		demo_blit();
	}
	if(!dis_indemo())
	{
		vid_deinit();
	}

	#ifdef DEBUG
	blob_fclose(fr);
	#endif
	return;
}
