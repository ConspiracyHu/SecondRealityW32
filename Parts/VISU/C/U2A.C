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

char	u2a_scene[64]={"U2A"};

extern char u2a_bg[];
char * bg2;

#pragma check_stack(off)

void u2a_copper2(void)
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


void u2a_main()
{
	char *sptemp;
	short	*ip;
	unsigned int u;
	char	*cp;
	int	a,b,c,d,e,f,g,x,y,z;
	#ifdef DEBUG
	fr=fopen("tmp","wt");
	#endif
	indemo=1;

	dis_partstart();
	sprintf(tmpname,"Data\\%s.00M",u2a_scene);
	if(!indemo) printf("Loading materials %s...\n",tmpname);
	scene0=scenem=readfile(tmpname);

	memcpy(scene0+16+192*3,u2a_bg+16,64*3);
	bg2=halloc(16384,4);
  u=0;
	for(y=0;y<200;y++)
	{
		for(x=0;x<320;x++)
		{
			a=u2a_bg[16+768+x+y*320];
			bg2[u++]=a;
		}
	}
	memcpy(u2a_bg,bg2,64000);
	hfree(bg2);

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
			sprintf(tmpname,"Data\\%s.%03i",u2a_scene,e);
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
			if(!indemo) printf("Copying %s.%03i... ",u2a_scene,e);
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

	sprintf(tmpname,"Data\\%s.0AA",u2a_scene);
	if(!indemo) printf("Loading animations...\n",tmpname);
	ip=readfile(tmpname);
  scl=0;
	while(*ip)
	{
		a=*ip;
		if(a==-1) break;
		sprintf(tmpname,"Data\\%s.0%c%c",u2a_scene,a/10+'A',a%10+'A');
		if(!indemo) printf("Scene: %s ",tmpname);
		scenelist[scl].data=readfile(tmpname);
		if (!indemo) printf("(%i:@%Fp)\n",scl,scenelist[scl].data);
		scl++;
		ip+=2;
	}

	if(!indemo) 
	{
		printf("Press any key to continue...");
		//getch();
	}	

	resetscene();

  if (!demo_isfirstpart())
  {
		for(;;)
		{
      /*
			_asm
			{
				mov	bx,6
				int	0fch
				mov	a,cx
				mov	b,bx
			}
      */
      a = dis_musorder(0);
      b = dis_musrow(0);
			if(a>10 && b>46) break;
			if(dis_exit()) return;
		}
  }
 	vid_init(3); ////// oversample x 4
	cp=(char *)(scenem+16);
	//vid_setpal(cp);
	shim_outp(0x3c8,0);
	for(a=0;a<768;a++) shim_outp(0x3c9,cp[a]);
	vid_window(0L,319L,25L,174L,512L,9999999L);
	
	dis_setcopper(2,u2a_copper2);
	dis_partstart();
	xit=0;
  currframe=0;
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

    /*
		_asm
		{
			mov	bx,6
			int	0fch
			mov	a,cx
			mov	b,bx
		}
    */
	        //if(a>11 && b>54) break;
		
		deadlock=0;
//		while(cl[clw].ready)
//		{
//			if(deadlock>16) break;
//		}
		// Draw to free frame
		vid_setswitch(clw,-1);
		vid_clearbg(u2a_bg);
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
			co[a].dist=calc_singlez(b,o->v0,o->r);
		}
		// Zsort
		if(city==1)
		{
			co[2].dist=1000000000L; // for CITY scene, test
			co[7].dist=1000000000L; // for CITY scene, test
			co[13].dist=1000000000L; // for CITY scene, test
		}
		if(city==2)
		{
			co[14].dist=1000000000L; // for CITY scene, test
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
		// calculate how many frames late of schedule
		avgrepeat=(avgrepeat+(syncframe-currframe)+1)/2;
		repeat=avgrepeat;
		if(repeat<1) repeat=1;
		cl[clw].frames=repeat;
		cl[clw].ready=1;
		clw++; clw&=3;
		// advance that many frames
		repeat=repeat;
		currframe+=repeat;
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
				return(3);
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
      u2a_copper2();
	}
	dis_setcopper(2,NULL);

	vid_setswitch(0,-1);
	vid_clearbg(u2a_bg);
	vid_setswitch(1,-1);
	vid_clearbg(u2a_bg);
	vid_setswitch(2,-1);
	vid_clearbg(u2a_bg);
	vid_setswitch(3,-1);
	vid_clearbg(u2a_bg);
	
	if(!dis_indemo())
	{
		vid_deinit();
	}

	#ifdef DEBUG
	fclose(fr);
	#endif
	return(0);
}
