#include "Graphics.h"
#include "shims.h"

extern "C" void dots_main( int argc, char * argv[] );

int width = 320;
int height = 200;
unsigned int * screen32;

Graphics graphics;

extern "C" void blit();

void blit()
{
  graphics.HandleMessages();

  for ( int i = 0; i < width * height; i++ ) screen32[ i ] = shim_palette[ shim_vram[ i ] ];
  graphics.Update( screen32 );
}

extern "C" bool demo_wantstoquit();
bool demo_wantstoquit()
{
  return graphics.WantsToQuit();
}

extern "C" void vsync();
void vsync()
{
  Sleep( 1000 / 60 );
}

int main()
{
  int windowWidth = 1280;
  int windowHeight = 720;
  bool fullscreen = false;
  if ( !graphics.Init( GetModuleHandle( NULL ), windowWidth, windowHeight, width, height, fullscreen ) )
  {
    return false;
  }

  screen32 = new unsigned int[ width * height ];

  dots_main( 0, NULL );

  delete[] screen32;

  graphics.Close();
}