#include <stdio.h>
#include <memory.h>
#include "dis.h"
#include "../../shims.h"

int dis_version()
{
  return 1;
}

int dis_indemo()
{
  return 1;
}

void st3play_GetOrderRowAndFrame( unsigned short * orderPtr, unsigned short * rowPtr, unsigned int * framePtr );
unsigned short st3play_GetOrder();
unsigned short st3play_GetRow();
unsigned int st3play_GetFrame();
short st3play_GetPlusFlags();

int dis_frame_start = 0;

void demo_vsync();
int dis_waitb()
{
  demo_vsync();
  return 1;
}

unsigned char demo_wantstoquit();
int dis_exit()
{
  return demo_wantstoquit();
}

void dis_partstart()
{
  memset( shim_vram, 0, shim_vram_x * shim_vram_y );
}

void * dis_msgarea( int areanumber )
{
  return NULL;
}

int dis_muscode( int code )
{
  return 0;
}

int dis_musplus()
{
  return st3play_GetPlusFlags();
}

int dis_musrow( int code )
{
  return st3play_GetRow();
}

int dis_musorder( int code )
{
  return st3play_GetOrder();
}

void dis_setcopper( int routine_number, void ( *routine )( void ) )
{
}

void dis_setmframe( int frame )
{
  dis_frame_start = frame;
}

int dis_getmframe( void )
{
  return st3play_GetFrame() - dis_frame_start;
}

struct Sync
{
  unsigned short order_and_row;
  unsigned short syncnumber;
}
syncdata[] =
{
  { 0x0000,0 },
  { 0x0200,1 },
  { 0x0300,2 },
  { 0x032f,3 },

  { 0x042f,4 },
  { 0x052f,5 },
  { 0x062f,6 },
  { 0x072f,7 },

  { 0x082f,8 },
  { 0x0900,9 },
  { 0x0d00,10},
  { 0x3d00,1 },

  { 0x3f00,2 },
  { 0x4100,3 },
  { 0x4200,4 },
};

int dis_sync( void )
{
  unsigned short order = 0;
  unsigned short row = 0;
  unsigned int frame = 0;
  st3play_GetOrderRowAndFrame( &order, &row, &frame );
  unsigned short order_and_row = (order << 8) | row;

  for ( int i = 1; i <= sizeof( syncdata ); i++ )
  {
    if ( syncdata[ i ].order_and_row >= order_and_row )
    {
      return syncdata[ i - 1 ].syncnumber;
    }
  }

  return 0;
}
