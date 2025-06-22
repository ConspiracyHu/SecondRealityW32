#include "Graphics.h"
#include "shims.h"

extern "C" void beg_main();
extern "C" void glenz_main();
extern "C" void dots_main( int argc, char * argv[] );
extern "C" void jplogo_main();
extern "C" void lens_main();
extern "C" void end_main();
extern "C" void endscrl_main();
extern "C" void pam_main();
extern "C" void alku_main();
extern "C" void coman_main();
extern "C" void plz_main();
extern "C" void credits_main();

extern "C" void rotate( int, int, int, int );
extern "C" void rotlist();
extern "C" void plzline(int,int);

unsigned int * screen32;

Graphics graphics;

extern "C" void demo_blit();

void demo_clear()
{
  ZeroMemory( shim_vram, shim_vram_x * shim_vram_y );
}

int screen_width = 320;
int screen_height = 200;

void demo_changemode( int x, int y )
{
  screen_width = x;
  screen_height = y;
}

void demo_blit()
{
  graphics.HandleMessages();

  int count = screen_width * screen_height;
  for ( int i = 0; i < count; i++ )
  {
    screen32[ i ] = shim_palette[ shim_vram[ i + shim_startpixel ] ];
  }

  if ( GetAsyncKeyState('P') &0x8000 )
  {
    for ( int i = 0; i < 256; i++ ) screen32[ i ] = shim_palette[ i ];
  }

  graphics.Update( screen32, screen_width, screen_height );
}

extern "C" bool demo_wantstoquit();
bool demo_wantstoquit()
{
  return graphics.WantsToQuit();
}

extern "C" void demo_vsync();
unsigned int lastVblank = 0;
void demo_vsync()
{
  const unsigned int now = GetTickCount();
  const unsigned int cycle = 1000 / 60;
  const unsigned int elapsed = now - lastVblank;
  if ( elapsed < cycle )
  {
    Sleep( cycle - elapsed );
  }
  lastVblank = now;
}

int main()
{
  // self-modifying code everywhere, wahey!
  DWORD old = 0;
  VirtualProtect( &rotate, 8192, PAGE_EXECUTE_READWRITE, &old );
  VirtualProtect( &rotlist, 8192, PAGE_EXECUTE_READWRITE, &old );
  VirtualProtect( &plzline, 8192, PAGE_EXECUTE_READWRITE, &old );

  int windowWidth = 1280;
  int windowHeight = 960;
  bool fullscreen = false;
  if ( !graphics.Init( GetModuleHandle( NULL ), windowWidth, windowHeight, -1, fullscreen ) )
  {
    return false;
  }

  screen32 = new unsigned int[ shim_vram_x * shim_vram_y ];
  ZeroMemory( screen32, shim_vram_x * shim_vram_y * sizeof( unsigned int ) );

  // 1   db      'Alkutekstit I (WILDF)       ' / 'ALKU    ' /  'ALKU.EXE',0
  //demo_changemode( 320, 400 );
  //alku_main();

  // 2   db      'Alkutekstit II (PSI)        ' / 'VISU    ' /  'U2A.EXE',0
  // 3   db      'Alkutekstit III (TRUG/WILDF)' / 'PAM     ' /  'PAM.EXE',0
  //demo_changemode( 320, 200 );
  //pam_main();

  //                                            / 'BEG     ' /  'BEGLOGO.EXE',0
  //demo_changemode( 320, 400 );
  //beg_main();

  // 4   db      'Glenz (PSI)                 ' / 'GLENZ   ' /  'GLENZ.EXE',0
  //glenz_main();

  // 5   db      'Dottitunneli (TRUG)         ' / 'TUNNELI ' /  'TUNNELI.EXE',0

  // 6   db      'Techno (PSI)                ' / 'TECHNO  ' /  'TECHNO.EXE',0

  // 7   db      'Panicfake (WILDF)           ' / 'PANIC   ' /  'PANICEND.EXE',0

  // 8   db      'Vuori-Scrolli (TRUG)        ' / 'FOREST  ' /  'MNTSCRL.EXE',0

  // 11  db      'Lens (PSI)                  ' / '        ' / 
  // 12  db      'Rotazoomer (PSI)            ' / 'LENS    ' /  'LNS&ZOOM.EXE',0
  //demo_changemode( 320, 200 );
  //lens_main();

  // 13  db      'Plasma (WILDF)              ' / '        ' / 

  // 14  db      'Plasmacube (WILDF)          ' / 'PLZPART ' /  'PLZPART.EXE',0
  //demo_changemode( 320, 200 );
  //plz_main();

  // 15  db      'MiniVectorBalls (PSI)       ' / 'DOTS    ' /  'MINVBALL.EXE',0
  //demo_changemode( 320, 200 );
  //dots_main( 0, NULL );

  // 16  db      'Peilipalloscroll (TRUG)     ' / 'WATER   ' /  'RAYSCRL.EXE',0

  // 17  db      '3D-Sinusfield (PSI)         ' / 'COMAN   ' /  '3DSINFLD.EXE',0
  //demo_changemode( 320, 200 );
  //coman_main();

  // 18  db      'Jellypic (PSI)              ' / 'JPLOGO  ' /  'JPLOGO.EXE',0
  //demo_changemode( 320, 400 );
  //jplogo_main();

  // 19  db      'Vector Part II',0             / 'VISU    ' /  'U2E.EXE',0

  // 20  db      'Endpictureflash (?)         ' / '        ' / 

  // 21  db      'Credits/Greetings scrl. (?) ' / 'END     ' /  'ENDLOGO.EXE',0
  //demo_changemode( 320, 400 );
  //end_main();

  // 22                                           'CREDITS ' /  'CRED.EXE',0
  demo_changemode( 320, 400 );
  credits_main();

  // 23                                           'ENDSCRL ' /  'ENDSCRL.EXE',0
  //demo_changemode( 640, 350 );
  //endscrl_main();
  
  delete[] screen32;

  graphics.Close();
}