#include <tchar.h>
#include "Graphics.h"

Graphics::Graphics()
  : mDirectDraw( NULL )
  , mSurfacePrimary( NULL )
  , mSurfaceSecondary( NULL )
  , mBPP( 0 )
  , mHWnd( 0 )
  , mPhysicalWidth( 0 )
  , mPhysicalHeight( 0 )
  , mIntegerZoom( 0 )
  , mWantsToQuit( 0 )
  , mFullscreen( 0 )
  , mPhysicalScreen( NULL )
{
  mWantsToQuit = false;
  mFullscreen = false;
  ZeroMemory( &mRectWindow, sizeof( RECT ) );
  ZeroMemory( &mRectViewport, sizeof( RECT ) );
  ZeroMemory( &mRectScreen, sizeof( RECT ) );
}

Graphics::~Graphics()
{
}

bool Graphics::Init( HINSTANCE _instance, int _screenWidth, int _screenHeight, int _zoom, bool _fullscreen )
{
  mPhysicalWidth = _screenWidth;
  mPhysicalHeight = _screenHeight;
  mFullscreen = _fullscreen;

  mIntegerZoom = _zoom;

  mPhysicalScreen = new unsigned int[ mPhysicalWidth * mPhysicalHeight ];
  ZeroMemory( mPhysicalScreen, sizeof( unsigned int ) * mPhysicalWidth * mPhysicalHeight );

  DWORD wExStyle = WS_EX_APPWINDOW;
  DWORD wStyle = WS_POPUP | WS_CLIPSIBLINGS | WS_CLIPCHILDREN | WS_VISIBLE;
  if ( !mFullscreen )
  {
    wStyle |= WS_OVERLAPPED | WS_CAPTION;
  }

  WNDCLASS wndClass;
  wndClass.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
  wndClass.lpfnWndProc = &WndProcStatic;
  wndClass.cbClsExtra = 0;
  wndClass.cbWndExtra = 0;
  wndClass.hInstance = _instance;
  wndClass.hIcon = NULL;
  wndClass.hCursor = LoadCursor( NULL, IDC_ARROW );
  wndClass.hbrBackground = NULL;
  wndClass.lpszMenuName = NULL;
  wndClass.lpszClassName = _T( "ud2dwindow" );

  if ( !RegisterClass( &wndClass ) )
  {
    return false;
  }

  RECT windowRect = { 0,0,mPhysicalWidth,mPhysicalHeight };
  if ( !mFullscreen )
  {
    AdjustWindowRectEx( &windowRect, wStyle, FALSE, wExStyle );
  }

  mHWnd = CreateWindowEx( wExStyle, wndClass.lpszClassName, _T( "Second Reality (Win32)" ), wStyle,
    ( GetSystemMetrics( SM_CXSCREEN ) - mPhysicalWidth ) / 2,
    ( GetSystemMetrics( SM_CYSCREEN ) - mPhysicalHeight ) / 2,
    windowRect.right - windowRect.left, windowRect.bottom - windowRect.top,
    NULL, NULL, _instance, this );

  if ( !mHWnd )
  {
    return false;
  }

  ShowWindow( mHWnd, SW_SHOW );
  SetForegroundWindow( mHWnd );
  SetFocus( mHWnd );

  GetClientRect( mHWnd, &mRectViewport );
  GetClientRect( mHWnd, &mRectScreen );
  ClientToScreen( mHWnd, (POINT *) &mRectScreen.left );
  ClientToScreen( mHWnd, (POINT *) &mRectScreen.right );

  //////////////////////////////////////////////////////////////////////////

  HRESULT result;
  result = DirectDrawCreateEx( NULL, (VOID **) &mDirectDraw, IID_IDirectDraw7, NULL );
  if ( result != DD_OK )
  {
    return false;
  }

  if ( mFullscreen )
  {
    result = mDirectDraw->SetCooperativeLevel( mHWnd, DDSCL_EXCLUSIVE | DDSCL_FULLSCREEN );
    if ( result != DD_OK )
    {
      return false;
    }

    result = mDirectDraw->SetDisplayMode( mPhysicalWidth, mPhysicalHeight, mBPP = 32, 0, 0 );
    if ( result != DD_OK )
    {
      result = mDirectDraw->SetDisplayMode( mPhysicalWidth, mPhysicalHeight, mBPP = 24, 0, 0 );
      if ( result != DD_OK )
      {
        result = mDirectDraw->SetDisplayMode( mPhysicalWidth, mPhysicalHeight, mBPP = 16, 0, 0 );
        if ( result != DD_OK )
        {
          return false;
        }
        else
        {
          DDSURFACEDESC2 ddsd;
          ZeroMemory( &ddsd, sizeof( ddsd ) );
          ddsd.dwSize = sizeof( ddsd );
          mDirectDraw->GetDisplayMode( &ddsd );
          if ( mBPP == 16 )
          {
            if ( ddsd.ddpfPixelFormat.dwRBitMask == 0x7c00 )
            {
              mBPP = 15;
            }
            else if ( ddsd.ddpfPixelFormat.dwRBitMask != 0xf800 )
            {
              return false;
            }
          }
        }
      }
    }

    DDSURFACEDESC2 ddsd;
    ZeroMemory( &ddsd, sizeof( ddsd ) );
    ddsd.dwSize = sizeof( ddsd );
    ddsd.dwFlags = DDSD_CAPS | DDSD_BACKBUFFERCOUNT;
    ddsd.ddsCaps.dwCaps = DDSCAPS_PRIMARYSURFACE | DDSCAPS_FLIP | DDSCAPS_COMPLEX;
    ddsd.dwBackBufferCount = 1;
    result = mDirectDraw->CreateSurface( &ddsd, &mSurfacePrimary, NULL );
    if ( result != DD_OK )
    {
      return false;
    }

    DDSCAPS2 ddscaps;
    ZeroMemory( &ddscaps, sizeof( ddscaps ) );
    ddscaps.dwCaps = DDSCAPS_BACKBUFFER;
    result = mSurfacePrimary->GetAttachedSurface( &ddscaps, &mSurfaceSecondary );
    if ( result != DD_OK )
    {
      return false;
    }

    ShowCursor( FALSE );
  }
  else
  {
    result = mDirectDraw->SetCooperativeLevel( mHWnd, DDSCL_NORMAL );
    if ( result != DD_OK )
    {
      return false;
    }

    DDSURFACEDESC2 ddsd;
    ZeroMemory( &ddsd, sizeof( ddsd ) );
    ddsd.dwSize = sizeof( ddsd );
    ddsd.dwFlags = DDSD_CAPS;
    ddsd.ddsCaps.dwCaps = DDSCAPS_PRIMARYSURFACE;
    result = mDirectDraw->CreateSurface( &ddsd, &mSurfacePrimary, NULL );
    if ( result != DD_OK )
    {
      return false;
    }

    LPDIRECTDRAWCLIPPER pClipper;
    result = mDirectDraw->CreateClipper( 0, &pClipper, NULL );
    if ( result != DD_OK )
    {
      return false;
    }

    pClipper->SetHWnd( 0, mHWnd );
    result = mSurfacePrimary->SetClipper( pClipper );
    pClipper->Release();
    if ( result != DD_OK )
    {
      return false;
    }

    ddsd.dwFlags = DDSD_WIDTH | DDSD_HEIGHT | DDSD_CAPS;
    ddsd.dwWidth = mPhysicalWidth;
    ddsd.dwHeight = mPhysicalHeight;
    ddsd.ddsCaps.dwCaps = DDSCAPS_OFFSCREENPLAIN;
    result = mDirectDraw->CreateSurface( &ddsd, &mSurfaceSecondary, NULL );
    if ( result != DD_OK )
    {
      return false;
    }

    mBPP = GetDeviceCaps( GetDC( mHWnd ), BITSPIXEL );
  }

  ShowCursor( FALSE );

  mWantsToQuit = false;

  return 1;
}

void Graphics::Close()
{
  if ( mDirectDraw != NULL )
  {
    mDirectDraw->SetCooperativeLevel( mHWnd, DDSCL_NORMAL );
    if ( mSurfaceSecondary != NULL )
    {
      mSurfaceSecondary->Release();
      mSurfaceSecondary = NULL;
    }
    if ( mSurfacePrimary != NULL )
    {
      mSurfacePrimary->Release();
      mSurfacePrimary = NULL;
    }
    mDirectDraw->Release();
  }
  if ( mPhysicalScreen )
  {
    delete[] mPhysicalScreen;
    mPhysicalScreen = NULL;
  }

  DestroyWindow( mHWnd );
}

void Graphics::HandleMessages()
{
  MSG msg;
  if ( PeekMessage( &msg, mHWnd, 0U, 0U, PM_REMOVE ) )
  {
    TranslateMessage( &msg );
    DispatchMessage( &msg );
  }
}

void Graphics::Update( void * _buffer, int _width, int _height )
{
  int zoomedX = _width * mIntegerZoom;
  int zoomedY = _height * mIntegerZoom;
  int mCenterX = ( mPhysicalWidth - zoomedX ) / 2;
  int mCenterY = ( mPhysicalHeight - zoomedY ) / 2;

  memset( mPhysicalScreen, 0x30, mPhysicalWidth * mPhysicalHeight * sizeof( unsigned int ) );

  unsigned int * src = (unsigned int *) _buffer;
  unsigned int * dst = (unsigned int *) mPhysicalScreen + mCenterY * mPhysicalWidth + mCenterX;
  for ( int y = 0; y < _height; y++ )
  {
    unsigned int * srcline = NULL;

    for ( int yz = 0; yz < mIntegerZoom; yz++ )
    {
      srcline = src;
      for ( int x = 0; x < _width; x++ )
      {
        for ( int xz = 0; xz < mIntegerZoom; xz++ )
        {
          *( dst++ ) = *srcline;
        }
        srcline++;
      }
      dst += mPhysicalWidth - ( _width * mIntegerZoom );
    }
    src = srcline;
  }

  Blit( mPhysicalScreen );
}

void Graphics::Blit( void * _buffer )
{
  unsigned int * vscr = (unsigned int *) _buffer;

  DDSURFACEDESC2 ddsdBack;
  ZeroMemory( &ddsdBack, sizeof( DDSURFACEDESC ) );
  ddsdBack.dwSize = sizeof( ddsdBack );
  if ( mSurfaceSecondary->Lock( 0, &ddsdBack, DDLOCK_SURFACEMEMORYPTR | DDLOCK_WAIT, 0 ) == DD_OK )
  {
    long noMansLandSizeInBytes = ddsdBack.lPitch - ddsdBack.dwWidth * ( ( mBPP + 1 ) / 8 );
    LPVOID surfacePtr = ddsdBack.lpSurface;

    switch ( mBPP )
    {
      case 32:
        __asm
        {
          push  es
          mov   ax, ds
          mov   es, ax
          mov   esi, [ vscr ]
          mov   edi, [ surfacePtr ]
          mov   ecx, [ ddsdBack.dwHeight ]
          Oneline32:
          push  ecx
            mov   ecx, [ ddsdBack.dwWidth ]
            rep   movsd
            add   edi, [ noMansLandSizeInBytes ]
            pop   ecx
            loop  Oneline32
            pop   es
        } break;
      case 24:
        __asm
        {
          push  es
          mov   ax, ds
          mov   es, ax
          mov   esi, [ vscr ]
          mov   edi, [ surfacePtr ]
          mov   ecx, [ ddsdBack.dwHeight ]
          Oneline24:
          push  ecx
            mov   ecx, [ ddsdBack.dwWidth ]
            Onepix24 :
            movsw
            movsb
            inc   esi
            loop  Onepix24
            add   edi, [ noMansLandSizeInBytes ]
            pop   ecx
            loop  Oneline24
            pop   es
        } break;
      case 16:
        __asm
        {
          push  es
          mov   ax, ds
          mov   es, ax
          mov   esi, [ vscr ]
          mov   edi, [ surfacePtr ]
          mov   ecx, [ ddsdBack.dwHeight ]
          Oneline16:
          push  ecx
            mov   ecx, [ ddsdBack.dwWidth ]
            Onepix16 :
            lodsd
            shr   ax, 2
            shl   al, 2
            shr   ax, 3
            mov   bx, ax
            shr   eax, 8
            and ax, 1111100000000000b
            or ax, bx
            stosw
            loop  Onepix16
            add   edi, [ noMansLandSizeInBytes ]
            pop   ecx
            loop  Oneline16
            pop   es
        } break;
      case 15:
        __asm
        {
          push  es
          mov   ax, ds
          mov   es, ax
          mov   esi, [ vscr ]
          mov   edi, [ surfacePtr ]
          mov   ecx, [ ddsdBack.dwHeight ]
          Oneline15:
          push  ecx
            mov   ecx, [ ddsdBack.dwWidth ]
            Onepix15 :
            lodsd
            shr   ax, 3
            shl   al, 3
            shr   ax, 3
            mov   bx, ax
            shr   eax, 9
            and ax, 0111110000000000b
            or ax, bx
            stosw
            loop  Onepix15
            add   edi, [ noMansLandSizeInBytes ]
            pop   ecx
            loop  Oneline15
            pop   es
        } break;
    }

    mSurfaceSecondary->Unlock( NULL );
  }

  HRESULT hRes = NULL;
  if ( mFullscreen )
  {
    hRes = mSurfacePrimary->Flip( NULL, NULL );
  }
  else
  {
    hRes = mSurfacePrimary->Blt( &mRectScreen, mSurfaceSecondary, &mRectViewport, DDBLT_WAIT, NULL );
  }

  if ( hRes == DDERR_SURFACELOST )
  {
    mSurfacePrimary->Restore();
  }
}

LRESULT CALLBACK Graphics::WndProc( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam )
{
  switch ( uMsg )
  {
    case WM_MOVE:
      {
        GetWindowRect( hWnd, &mRectWindow );
        GetClientRect( hWnd, &mRectViewport );
        GetClientRect( hWnd, &mRectScreen );
        ClientToScreen( hWnd, (POINT *) &mRectScreen.left );
        ClientToScreen( hWnd, (POINT *) &mRectScreen.right );
      }
      break;

    case WM_PAINT:
      {
        if ( mFullscreen )
        {
          return 0;
        }
      }
      break;

    case WM_KEYDOWN:
      {
        switch ( wParam )
        {
          case VK_ESCAPE:
            {
              PostMessage( hWnd, WM_QUIT, 0, 0 );
              mWantsToQuit = true;
              return 0L;
            } 
            break;
        }
      } 
      break;

    case WM_CLOSE:
    case WM_DESTROY:
      {
        mWantsToQuit = true;
        PostMessage( hWnd, WM_QUIT, 0, 0 );
      }
      break;

    case WM_SYSCOMMAND:
      {
        switch ( wParam )
        {
          case SC_SCREENSAVE:
          case SC_MONITORPOWER:
            {
              return 0;
            }
        }
        break;
      }
      break;

  }
  return DefWindowProc( hWnd, uMsg, wParam, lParam );
}

Graphics * pGlobalDisp = NULL;

LRESULT CALLBACK Graphics::WndProcStatic( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam )
{
  if ( uMsg == WM_CREATE )
  {
    CREATESTRUCT * createStruct = (CREATESTRUCT *) lParam; // todo: split to multiple hWnd-s! (if needed)
    pGlobalDisp = (Graphics *) createStruct->lpCreateParams;
  }

  if ( !pGlobalDisp->WndProc( hWnd, uMsg, wParam, lParam ) )
  {
    return 0;
  }

  return DefWindowProc( hWnd, uMsg, wParam, lParam );
}