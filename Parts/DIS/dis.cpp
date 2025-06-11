#include "dis.h"

int dis_version()
{
  return 1;
}

int dis_indemo()
{
  return 1;
}

int dis_waitb()
{
  return 1;
}

int dis_exit()
{
  return 1;
}

void dis_partstart()
{
}

void * dis_msgarea( int areanumber )
{
  return nullptr;
}

int dis_muscode( int )
{
  return 0;
}

int dis_musplus()
{
  return 0;
}

int dis_musrow( int )
{
  return 0;
}

void dis_setcopper( int routine_number, void ( *routine )( ) )
{
}
