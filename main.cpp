#include "Graphics.h"
#include "shims.h"

extern "C" void dots_main( int argc, char * argv[] );
extern "C" void jplogo_main();
extern "C" void lens_main();
extern "C" void end_main();
extern "C" void endscrl_main();
extern "C" void pam_main();

extern "C" void rotate( int, int, int, int );

unsigned int * screen32;

Graphics graphics;

extern "C" void demo_blit();

void demo_clear()
{
  ZeroMemory( shim_vram, shim_vram_x * shim_vram_y );
}

int width = 320;
int height = 200;

void demo_blit()
{
  graphics.HandleMessages();

  int count = width * height;
  for ( int i = 0; i < count; i++ )
  {
    screen32[ i ] = shim_palette[ shim_vram[ i + shim_startpixel ] ];
  }

  if ( GetAsyncKeyState('P') &0x8000 )
  {
    for ( int i = 0; i < 256; i++ ) screen32[ i ] = shim_palette[ i ];
  }

  graphics.Update( screen32, width, height );
}

extern "C" bool demo_wantstoquit();
bool demo_wantstoquit()
{
  return graphics.WantsToQuit();
}

extern "C" void demo_vsync();
void demo_vsync()
{
  Sleep( 1000 / 60 );
}

int main()
{
  // self-modifying code in rotozoomer, wahey!
  DWORD old = 0;
  VirtualProtect( &rotate, 8192, PAGE_EXECUTE_READWRITE, &old );

  int windowWidth = 1280;
  int windowHeight = 800;
  bool fullscreen = false;
  if ( !graphics.Init( GetModuleHandle( NULL ), windowWidth, windowHeight, 1, fullscreen ) )
  {
    return false;
  }

  screen32 = new unsigned int[ shim_vram_x * shim_vram_y ];
  ZeroMemory( screen32, shim_vram_x * shim_vram_y * sizeof( unsigned int ) );

  //dots_main( 0, NULL );

  //width = 320;
  //height = 400;
  //jplogo_main();

  //lens_main();
  //end_main();

  width = 640;
  height = 350;
  endscrl_main();

  //pam_main();

  delete[] screen32;

  graphics.Close();
}