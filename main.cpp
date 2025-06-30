#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include "Graphics.h"
#include "shims.h"

extern "C" int dis_exit();

extern "C" void beg_main();
extern "C" void glenz_main();
extern "C" void dots_main();
extern "C" void jplogo_main();
extern "C" void lens_main();
extern "C" void end_main();
extern "C" void endscrl_main();
extern "C" void pam_main();
extern "C" void alku_main();
extern "C" void coman_main();
extern "C" void plz_main();
extern "C" void credits_main();
extern "C" void u2a_main();
extern "C" void u2e_main();
extern "C" void tun_main();
extern "C" void forest_main();
extern "C" void water_main();
extern "C" void shutdown_main();
extern "C" void koe_main();

extern "C" void rotate( int, int, int, int );
extern "C" void rotlist();
extern "C" void plzline(int,int);

extern "C" bool st3play_PlaySong( const unsigned char * moduleData, unsigned int dataLength, bool useInterpolationFlag, unsigned int audioFreq, unsigned int startingOrder );
extern "C" void st3play_Close( void );
extern "C" void st3play_SetMasterVol( unsigned short volume );
extern "C" void st3play_GetOrderAndRow( unsigned short * orderPtr, unsigned short * rowPtr );
extern "C" short st3play_GetPlusFlags();

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
#if 1
  unsigned short order = 0;
  unsigned short row = 0;
  st3play_GetOrderAndRow( &order, &row );
  unsigned short plus = st3play_GetPlusFlags();
  //printf( "%04X %04X %04X\r", order, row, plus );
#endif

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

//#define WAIT_FOR_KEY
extern "C" void demo_vsync();
unsigned int lastVblank = 0;
void demo_vsync()
{
#ifdef WAIT_FOR_KEY
  while ( !( GetAsyncKeyState( ' ' ) & 0x8000 ) ) { Sleep( 1 ); }
  while ( GetAsyncKeyState( ' ' ) & 0x8000 ) { Sleep( 1 ); }
#else
  const unsigned int now = GetTickCount();
  const unsigned int cycle = 1000 / 70;
  const unsigned int elapsed = 0;// now - lastVblank;
  if ( elapsed < cycle )
  {
    Sleep( cycle - elapsed );
  }
  lastVblank = now;
#endif
}

unsigned char * musicdata = NULL;
void start_music( const char * path, int start_order )
{
  FILE * f1 = fopen( path, "rb" );
  fseek( f1, 0L, SEEK_END );
  unsigned int size = ftell( f1 );
  musicdata = (unsigned char *)malloc( size );
  fseek( f1, 0L, SEEK_SET );
  fread( musicdata, (size_t)size, 1, f1 );
  fclose( f1 );

  st3play_PlaySong( musicdata, size, true, 44100, start_order );
#ifdef _DEBUG
  st3play_SetMasterVol( 100 );
#endif // _DEBUG
}

void end_music( const char * path, int start_order )
{
  st3play_Close();

  free( musicdata );
  musicdata = NULL;
}

#define MUSIC_SKAV 1
#define MUSIC_PM 2

int main( int argc, char * argv[] )
{
  // self-modifying code everywhere, wahey!
  DWORD old = 0;
  VirtualProtect( &rotate, 8192, PAGE_EXECUTE_READWRITE, &old );
  VirtualProtect( &rotlist, 8192, PAGE_EXECUTE_READWRITE, &old );
  VirtualProtect( &plzline, 8192, PAGE_EXECUTE_READWRITE, &old );
  VirtualProtect( &tun_main, 8192, PAGE_EXECUTE_READWRITE, &old );

  int windowWidth = 1280;
  int windowHeight = 960;
  bool fullscreen = false;
  if ( !graphics.Init( GetModuleHandle( NULL ), windowWidth, windowHeight, -1, fullscreen ) )
  {
    return false;
  }

  screen32 = new unsigned int[ shim_vram_x * shim_vram_y ];
  ZeroMemory( screen32, shim_vram_x * shim_vram_y * sizeof( unsigned int ) );

  struct  
  {
    unsigned char music;
    unsigned char music_startorder;
    unsigned short x;
    unsigned short y;
    void (*part)();
  } parts[] = {
    /* 00  BUG  */ { MUSIC_SKAV,  0x00, 320, 400, alku_main },      // 1   db  'Alkutekstit I (WILDF)       ' / 'ALKU    ' / 'ALKU.EXE'
    /* 01  CTD  */ { MUSIC_SKAV,  0x0C, 320, 200, u2a_main },       // 2   db  'Alkutekstit II (PSI)        ' / 'VISU    ' / 'U2A.EXE'
    /* 02  BUG  */ { MUSIC_SKAV,  0x0D, 320, 200, pam_main },       // 3   db  'Alkutekstit III (TRUG/WILDF)' / 'PAM     ' / 'PAM.EXE'
    /* 03       */ { MUSIC_SKAV,  0x0E, 320, 400, beg_main },                  
    /* 04  BUG  */ { MUSIC_PM,    0x00, 320, 200, glenz_main },     // 4   db  'Glenz (PSI)                 ' / 'GLENZ   ' / 'GLENZ.EXE'
    /* 05       */ { MUSIC_PM,    0x0F, 320, 200, tun_main },       // 5   db  'Dottitunneli (TRUG)         ' / 'TUNNELI ' / 'TUNNELI.EXE'
    /* 06  BUG  */ { MUSIC_PM,    0x14, 320, 200, koe_main },       // 6   db  'Techno (PSI)                ' / 'TECHNO  ' / 'TECHNO.EXE'
    /* 07  BUG  */ { MUSIC_PM,    0x18, 320, 200, shutdown_main },  // 7   db  'Panicfake (WILDF)           ' / 'PANIC   ' / 'PANICEND.EXE'
    /* 08       */ { MUSIC_PM,    0x2A, 320, 200, forest_main },    // 8   db  'Vuori-Scrolli (TRUG)        ' / 'FOREST  ' / 'MNTSCRL.EXE'
                                                                    // 11  db  'Lens (PSI)                  ' / '        ' / 
    /* 09       */ { MUSIC_PM,    0x2F, 320, 200, lens_main },      // 12  db  'Rotazoomer (PSI)            ' / 'LENS    ' / 'LNS&ZOOM.EXE'
                                                                    // 13  db  'Plasma (WILDF)              ' / '        ' / 
    /* 10  BUG  */ { MUSIC_PM,    0x3F, 320, 200, plz_main },       // 14  db  'Plasmacube (WILDF)          ' / 'PLZPART ' / 'PLZPART.EXE'
    /* 11       */ { MUSIC_PM,    0x4E, 320, 200, dots_main },      // 15  db  'MiniVectorBalls (PSI)       ' / 'DOTS    ' / 'MINVBALL.EXE'
    /* 12       */ { MUSIC_PM,    0x58, 320, 200, water_main },     // 16  db  'Peilipalloscroll (TRUG)     ' / 'WATER   ' / 'RAYSCRL.EXE'
    /* 13  BUG  */ { MUSIC_PM,    0x5E, 320, 400, coman_main },     // 17  db  '3D-Sinusfield (PSI)         ' / 'COMAN   ' / '3DSINFLD.EXE'
    /* 14       */ { MUSIC_PM,    0x63, 320, 400, jplogo_main },    // 18  db  'Jellypic (PSI)              ' / 'JPLOGO  ' / 'JPLOGO.EXE'
    /* 15  CTD  */ { MUSIC_SKAV,  0x12, 320, 200, u2e_main },       // 19  db  'Vector Part II              ' / 'VISU    ' / 'U2E.EXE'
                                                                               
    /* 16       */ { MUSIC_SKAV,  0x19, 320, 400, end_main },       // 20  db  'Endpictureflash (?)         ' / 'END     ' / 'ENDLOGO.EXE'
    /* 17       */ { MUSIC_SKAV,  0x1C, 320, 400, credits_main },   // 21  db  'Credits/Greetings scrl. (?) ' / 'CREDITS ' / 'CRED.EXE'
    /* 18       */ { MUSIC_SKAV,  0x2B, 640, 350, endscrl_main },   // 23                                       'ENDSCRL ' / 'ENDSCRL.EXE'
                   { 0         ,  0x00,   0,   0, NULL },
  };

  int start = 10;
  if ( argc > 1 )
  {
    switch( argv[ 1 ][ 0 ] )
    {
    case '2': start = 3; break;
    case '3': start = 8; break;
    case '4': start = 15; break;
    case '5': start = 18; break;
    }
  }

  const char * music_paths[ 3 ] = { NULL };
  music_paths[MUSIC_SKAV] = "Data\\2ND_SKAV.S3M";
  music_paths[MUSIC_PM] = "Data\\2ND_PM.S3M";

  int lastmusic = 0;
  for ( int i = start; parts[ i ].x; i++ )
  {
    if ( lastmusic != parts[ i ].music )
    {
      lastmusic = parts[ i ].music;
      start_music( music_paths[ parts[ i ].music ], parts[ i ].music_startorder );
    }
    demo_changemode( parts[ i ].x, parts[ i ].y );
    parts[ i ].part();
    if ( dis_exit() )
    {
      break;
    }
  }
  
  delete[] screen32;

  graphics.Close();
}
