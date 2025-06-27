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

int dis_frame = 0;

void demo_vsync();
int dis_waitb()
{
  demo_vsync();
  dis_frame++;
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

unsigned short st3play_GetOrder();
unsigned short st3play_GetRow();
short st3play_GetPlusFlags();

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

}

int dis_getmframe( void )
{
  return dis_frame;
}

int sync = 0;
int dis_sync( void )
{
  return sync++;
}
