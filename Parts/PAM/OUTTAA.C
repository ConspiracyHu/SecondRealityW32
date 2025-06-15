#include <stdio.h>
#include <conio.h>
#include <dos.h>
#include "..\dis\dis.h"
#include "..\..\shims.h"
//#pragma	 inline

//extern void tw_opengraph();
//extern void tw_waitvr();
//extern void tw_setpalette(char far *pal);
//extern void tw_setstart(int s);
//
//extern	init_copper();
//extern	close_copper();
extern	int frame_count;
extern  char *cop_pal;
extern  int do_pal;

extern	void init_uframe(char * seg);
extern	void ulosta_frame(char * start);
extern 	char pam_memblock[];
extern 	char pam_pal[];

void setpalarea( char * p, int offset, int count );

int	wfade[100]=    {63,32,16,8,4,2,1,0,0,0,
			0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,
			1,2,4,6,9,14,20,28,37,46,
			56,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63};

void pam_main()
	{
	int	a,f=0,p=0,frames;
	unsigned  m=65535,b,segp;
	long	len;

	dis_partstart();

	for(a=1;a<64;a++) for(b=0;b<768;b++)
		pam_pal[a*768+b]=(63*a+(64-a)* pam_pal[b])/64;

//	while(dis_waitb()<10&&!dis_exit());
//	tw_waitvr();
//	tw_setpalette(&pal[768*63]);
//	tw_opengraph();
  //aseg = pam_memblock;
	init_uframe(pam_memblock);
	//init_copper();
	//frame_count=0;
	while(!dis_exit() && f++<45)
		{
    setpalarea( &pam_pal[ 768 * wfade[ f ] ], 0, 256 );
    //while(frame_count<4); frame_count=0;
		if(f<=40)
			{
			if(p)   {
				p=0;
				ulosta_frame(shim_vram);
				//tw_setstart(16384);
				}
			else	{
				p=1;
				ulosta_frame(shim_vram);
				//tw_setstart(0U);
				}
			}
		//cop_pal=&pal[768*wfade[f]];
		//do_pal=1;
    for(int i=0; i<4; i++)
      dis_waitb();
    demo_blit();
		}
	//close_copper();
	}

