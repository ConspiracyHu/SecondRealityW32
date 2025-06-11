#include "Graphics.h"
#include "shims.h"

extern "C" void dots_main( int argc, char * argv[] );

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

  dots_main( 0, NULL );

  unsigned int * screen32 = new unsigned int[ width * height ];
  while ( !graphics.WantsToQuit() )
  {
    graphics.HandleMessages();

    for ( int i = 0; i < width * height; i++ ) screen32[ i ] = shim_palette[ shim_vram[ i ] ];
    graphics.Update( screen32 );
  }
  delete[] screen32;

  graphics.Close();
}