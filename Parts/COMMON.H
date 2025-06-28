#pragma once

void readp( char * dest, int row, char * src );
void setpalarea( char * p, int offset, int count );
void getpalarea( char * p, int offset, int count );
#define setpal(p) setpalarea(p,0,256)
#define getpal(p) getpalarea(p,0,256)

extern int frame_count;
extern char * cop_pal;
extern int do_pal;
extern int cop_start;
extern int cop_scrl;
extern int cop_dofade;
extern int cop_drop;
extern short * cop_fadepal;
extern short fadepal[];

void copper2();
void copper3();