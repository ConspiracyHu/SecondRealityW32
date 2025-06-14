#include "Graphics.h"
#include "shims.h"

extern "C" void dots_main( int argc, char * argv[] );
extern "C" void jplogo_main();
extern "C" void lens_main();
extern "C" void end_main();
extern "C" void endscrl_main();
extern "C" void pam_main();

extern "C" void rotate( int, int, int, int );

int width = 320;
int height = 200;
unsigned int * screen32;

Graphics graphics;

extern "C" void demo_blit();

void demo_blit()
{
  graphics.HandleMessages();

  for ( int i = 0; i < width * height; i++ ) screen32[ i ] = shim_palette[ shim_vram[ i + shim_startpixel ] ];

  if ( GetAsyncKeyState('P') &0x8000 )
  {
    for ( int i = 0; i < 256; i++ ) screen32[ i ] = shim_palette[ i ];
  }

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
  // self-modifying code in rotozoomer, wahey!
  DWORD old = 0;
  VirtualProtect( &rotate, 8192, PAGE_EXECUTE_READWRITE, &old );

  int windowWidth = 1280;
  int windowHeight = 720;
  bool fullscreen = false;
  if ( !graphics.Init( GetModuleHandle( NULL ), windowWidth, windowHeight, width, height, fullscreen ) )
  {
    return false;
  }

  screen32 = new unsigned int[ width * height ];

  //dots_main( 0, NULL );
  //jplogo_main();
  //lens_main();
  //end_main();
  endscrl_main();
  //pam_main();

  delete[] screen32;

  graphics.Close();
}