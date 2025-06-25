#pragma once

void readp( char * dest, int row, char * src );
void setpalarea( char * p, int offset, int count );
void getpalarea( char * p, int offset, int count );
#define setpal(p) setpalarea(p,0,256)
#define getpal(p) getpalarea(p,0,256)