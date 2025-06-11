#include "Graphics.h"

int main()
{
  Graphics graphics;

  int windowWidth = 1280;
  int windowHeight = 720;
  int width = 320;
  int height = 240;
  bool fullscreen = false;
  if ( !graphics.Init( GetModuleHandle( NULL ), windowWidth, windowHeight, width, height, fullscreen ) )
  {
    return false;
  }

  unsigned char * screen = new unsigned char[ width * height ];
  unsigned int palette[ 256 ] = { 0 };
  for ( int i = 0; i < 256; i++ ) palette[ i ] = i * 0x01010101;
  unsigned int * screen32 = new unsigned int[ width * height ];
  while ( !graphics.WantsToQuit() )
  {
    graphics.HandleMessages();

    for ( int i = 0; i < width * height; i++ ) screen32[ i ] = palette[ screen[ i ] ];
    graphics.Update( screen32 );
  }
  delete[] screen32;
  delete[] screen;

  graphics.Close();
}