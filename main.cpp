#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include "Graphics.h"
#include "shims.h"

extern "C" int dis_exit();
extern "C" int dis_getmframe();
extern "C" int dis_musplus();
extern "C" int dis_waitb();

extern "C" int menu();

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
extern "C" void ddstars_main();

extern "C" void rotate( int, int, int, int );
extern "C" void rotlist();
extern "C" void plzline(int,int);

extern "C" bool st3play_PlaySong( const unsigned char * moduleData, unsigned int dataLength, bool useInterpolationFlag, unsigned int audioFreq, unsigned int startingOrder );
extern "C" void st3play_Close( void );
extern "C" void st3play_SetMasterVol( unsigned short volume );
extern "C" void st3play_GetOrderRowAndFrame( unsigned short * orderPtr, unsigned short * rowPtr, unsigned int * framePtr );
extern "C" short st3play_GetPlusFlags();

extern "C" void load_music();
extern "C" void start_music( int song_idx, int start_order );
extern "C" void end_music();

unsigned int * screen32;

Graphics graphics;

extern "C" void demo_blit();

const int virtual_screen_width = 640;
const int virtual_screen_height = 400;
int demo_screen_width = 320;
int demo_screen_height = 200;

void demo_changemode( int x, int y )
{
  demo_screen_width = x;
  demo_screen_height = y;
}

void demo_blit()
{
#ifdef _DEBUG
  unsigned short order = 0;
  unsigned short row = 0;
  unsigned int frame = 0;
  st3play_GetOrderRowAndFrame( &order, &row, &frame );
  unsigned short plus = st3play_GetPlusFlags();
  printf( "%04X %04X | %04X %4d | %d\r", order, row, plus, (short)plus, frame );
#endif

  graphics.HandleMessages();

  if ( demo_screen_width == 320 && demo_screen_height == 200 )
  {
    unsigned char * src = shim_vram + shim_startpixel;
    unsigned int * dst = screen32;
    for ( int y = 0; y < demo_screen_height; y++ )
    {
      for ( int x = 0; x < demo_screen_width; x++ )
      {
        unsigned int c = shim_palette[ *src++ ];
        *dst++ = c;
        *dst++ = c;
      }
      memcpy( dst, dst - virtual_screen_width, virtual_screen_width * sizeof( unsigned int ) );
      dst += virtual_screen_width;
    }
  }
  else if ( demo_screen_width == 320 && demo_screen_height == 400 )
  {
    unsigned char * src = shim_vram + shim_startpixel;
    unsigned int * dst = screen32;
    for ( int y = 0; y < demo_screen_height; y++ )
    {
      for ( int x = 0; x < demo_screen_width; x++ )
      {
        unsigned int c = shim_palette[ *src++ ];
        *dst++ = c;
        *dst++ = c;
      }
    }
  }
  else if ( demo_screen_width == 640 && demo_screen_height == 350 )
  {
    unsigned char * src = shim_vram + shim_startpixel;
    unsigned int * dst = screen32 + virtual_screen_width * ( virtual_screen_height - 350 ) / 2;
    for ( int y = 0; y < demo_screen_height; y++ )
    {
      for ( int x = 0; x < demo_screen_width; x++ )
      {
        *dst++ = shim_palette[ *src++ ];
      }
    }
  }
  else
  {
    DebugBreak(); // Unknown screen mode?!
  }

#ifdef _DEBUG
  if ( GetAsyncKeyState('P') &0x8000 )
  {
    for ( int i = 0; i < 256; i++ ) screen32[ i ] = shim_palette[ i ];
  }
#endif
  
  graphics.Update( screen32, virtual_screen_width, virtual_screen_height );
}

extern "C" bool demo_wantstoquit();
bool demo_wantstoquit()
{
  return graphics.WantsToQuit();
}

double currentTime = 0.0;
LARGE_INTEGER lastPCV = { 0 };

float get_time_ms_precise()
{
  LARGE_INTEGER count, freq;
  if ( !lastPCV.QuadPart )
  {
    QueryPerformanceCounter( &lastPCV );
  }
  QueryPerformanceCounter( &count );
  QueryPerformanceFrequency( &freq );

  currentTime += (double)( count.QuadPart - lastPCV.QuadPart ) / (double)( freq.QuadPart );

  lastPCV = count;

  return (float)( currentTime * 1000.0f );
}

//#define WAIT_FOR_KEY
extern "C" void demo_vsync();
float lastVblank = 0;
void demo_vsync()
{
#ifdef WAIT_FOR_KEY
  while ( !( GetAsyncKeyState( ' ' ) & 0x8000 ) ) { Sleep( 1 ); }
  while ( GetAsyncKeyState( ' ' ) & 0x8000 ) { Sleep( 1 ); }
#else
  const float cycle_ms = 1000.0f / 70.0f;
  float now = get_time_ms_precise();
  float elapsed = now - lastVblank;
  while ( elapsed < cycle_ms )
  {
    now = get_time_ms_precise();
    elapsed = now - lastVblank;
  }
  lastVblank = now;
#endif
}

#define MUSIC_SKAV 0
#define MUSIC_PM 1

int main( int argc, char * argv[] )
{
  // self-modifying code everywhere, wahey!
  DWORD old = 0;
  VirtualProtect( &rotate, 8192, PAGE_EXECUTE_READWRITE, &old );
  VirtualProtect( &rotlist, 8192, PAGE_EXECUTE_READWRITE, &old );
  VirtualProtect( &plzline, 8192, PAGE_EXECUTE_READWRITE, &old );
  VirtualProtect( &tun_main, 8192, PAGE_EXECUTE_READWRITE, &old );

  load_music();

#ifdef _DEBUG
  Graphics::WindowType windowType = Graphics::WindowType::Windowed;
  int windowWidth = 1280;
  int windowHeight = 960;
#else
  Graphics::WindowType windowType = Graphics::WindowType::Borderless;
  int windowWidth = GetSystemMetrics( SM_CXSCREEN );
  int windowHeight = GetSystemMetrics( SM_CYSCREEN );
  menu();
#endif // _DEBUG
  if ( !graphics.Init( GetModuleHandle( NULL ), windowWidth, windowHeight, -1, windowType ) )
  {
    return false;
  }

  screen32 = new unsigned int[ virtual_screen_width * virtual_screen_height ];
  ZeroMemory( screen32, virtual_screen_width * virtual_screen_height * sizeof( unsigned int ) );

  typedef struct 
  {
    unsigned char music;
    unsigned char music_startorder;
    unsigned short x;
    unsigned short y;
    void (*part)();
  } t_part;

  t_part main_parts[] = {
    /* 00       */ { MUSIC_SKAV,  0x00, 320, 400, alku_main },      // 1   db  'Alkutekstit I (WILDF)       ' / 'ALKU    ' / 'ALKU.EXE'
    /* 01       */ { MUSIC_SKAV,  0x0C, 320, 200, u2a_main },       // 2   db  'Alkutekstit II (PSI)        ' / 'VISU    ' / 'U2A.EXE'
    /* 02       */ { MUSIC_SKAV,  0x0D, 320, 200, pam_main },       // 3   db  'Alkutekstit III (TRUG/WILDF)' / 'PAM     ' / 'PAM.EXE'
    /* 03       */ { MUSIC_SKAV,  0x0E, 320, 400, beg_main },                  
    /* 04       */ { MUSIC_PM,    0x00, 320, 400, glenz_main },     // 4   db  'Glenz (PSI)                 ' / 'GLENZ   ' / 'GLENZ.EXE'
    /* 05       */ { MUSIC_PM,    0x0F, 320, 200, tun_main },       // 5   db  'Dottitunneli (TRUG)         ' / 'TUNNELI ' / 'TUNNELI.EXE'
    /* 06       */ { MUSIC_PM,    0x14, 320, 200, koe_main },       // 6   db  'Techno (PSI)                ' / 'TECHNO  ' / 'TECHNO.EXE'
    /* 07       */ { MUSIC_PM,    0x27, 320, 400, shutdown_main },  // 7   db  'Panicfake (WILDF)           ' / 'PANIC   ' / 'PANICEND.EXE'
    /* 08       */ { MUSIC_PM,    0x2A, 320, 200, forest_main },    // 8   db  'Vuori-Scrolli (TRUG)        ' / 'FOREST  ' / 'MNTSCRL.EXE'
                                                                    // 11  db  'Lens (PSI)                  ' / '        ' / 
    /* 09       */ { MUSIC_PM,    0x2F, 320, 200, lens_main },      // 12  db  'Rotazoomer (PSI)            ' / 'LENS    ' / 'LNS&ZOOM.EXE'
                                                                    // 13  db  'Plasma (WILDF)              ' / '        ' / 
    /* 10       */ { MUSIC_PM,    0x3E, 320, 200, plz_main },       // 14  db  'Plasmacube (WILDF)          ' / 'PLZPART ' / 'PLZPART.EXE'
    /* 11       */ { MUSIC_PM,    0x4D, 320, 200, dots_main },      // 15  db  'MiniVectorBalls (PSI)       ' / 'DOTS    ' / 'MINVBALL.EXE'
    /* 12       */ { MUSIC_PM,    0x58, 320, 200, water_main },     // 16  db  'Peilipalloscroll (TRUG)     ' / 'WATER   ' / 'RAYSCRL.EXE'
    /* 13       */ { MUSIC_PM,    0x5E, 320, 200, coman_main },     // 17  db  '3D-Sinusfield (PSI)         ' / 'COMAN   ' / '3DSINFLD.EXE'
    /* 14       */ { MUSIC_PM,    0x62, 320, 400, jplogo_main },    // 18  db  'Jellypic (PSI)              ' / 'JPLOGO  ' / 'JPLOGO.EXE'
    /* 15       */ { MUSIC_SKAV,  0x12, 320, 400, u2e_main },       // 19  db  'Vector Part II              ' / 'VISU    ' / 'U2E.EXE'
    /* 16       */ { MUSIC_SKAV,  0x19, 320, 400, end_main },       // 20  db  'Endpictureflash (?)         ' / 'END     ' / 'ENDLOGO.EXE'
    /* 17       */ { MUSIC_SKAV,  0x1C, 320, 400, credits_main },   // 21  db  'Credits/Greetings scrl. (?) ' / 'CREDITS ' / 'CRED.EXE'
    /* 18       */ { MUSIC_SKAV,  0x2B, 640, 350, endscrl_main },   // 23                                       'ENDSCRL ' / 'ENDSCRL.EXE'
                   { 0         ,  0x00,   0,   0, NULL },
  };

  t_part hidden_part[] = {
    /* 00       */ { MUSIC_SKAV,  0x46, 320, 400, ddstars_main },   // hidden part
                   { 0         ,  0x00,   0,   0, NULL },
  };

  t_part * parts = main_parts;

#ifdef _DEBUG
  int start = 16;
#else
  int start = 0;
#endif
  if ( argc > 1 )
  {
    switch( argv[ 1 ][ 0 ] )
    {
    case '2': start = 3; break;
    case '3': start = 8; break;
    case '4': start = 15; break;
    case '5': start = 18; break;
    case 'u':
    case 'U': start = 0; parts = hidden_part; break;
    }
  }

  int lastmusic = -1;
  for ( int i = start; parts[ i ].x; i++ )
  {
    if ( lastmusic != parts[ i ].music )
    {
      lastmusic = parts[ i ].music;
      start_music( parts[ i ].music, parts[ i ].music_startorder );
    }
    demo_changemode( parts[ i ].x, parts[ i ].y );
    parts[ i ].part();
    if ( dis_exit() )
    {
      break;
    }

    demo_finishedfirstpart();

    if ( i == 7 )
    {
      // wait for music between the shutdown / forest parts (see @@zh5 in U2.ASM)
      while ( !dis_exit() && dis_musplus() >= 0 )
      {
        dis_waitb();
        demo_blit();
      }
      while ( !dis_exit() && dis_musplus() < 0 )
      {
        dis_waitb();
        demo_blit();
      }
    }
  }

  end_music();
  delete[] screen32;

  graphics.Close();
}
