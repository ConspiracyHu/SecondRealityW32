#include <tchar.h>
#include "Graphics.h"
#include "Resources/resource.h"

/* ---------------------------------------------------------------------------------------------- */
/* Graphics (toplevel class, doesn't do much) */

Graphics::Graphics()
  : mPhysicalWidth( 0 )
  , mPhysicalHeight( 0 )
  , mIntegerZoom( 0 )
  , mWindowType( WindowType::Windowed )
  , mPhysicalScreen( NULL )
{
  /* nothing */
}

Graphics::~Graphics()
{
  Close();
}

bool Graphics::Init( int _screenWidth, int _screenHeight, int _zoom, WindowType _windowType )
{
  mPhysicalWidth = _screenWidth;
  mPhysicalHeight = _screenHeight;
  mWindowType = _windowType;
   
  mIntegerZoom = _zoom;

  mPhysicalScreen = new uint32_t[ mPhysicalWidth * mPhysicalHeight ];
  memset(mPhysicalScreen, 0, sizeof(uint32_t) * mPhysicalWidth * mPhysicalHeight);

  /* we're done here */
  return true;
}

void Graphics::Close()
{
  if ( mPhysicalScreen )
  {
    delete[] mPhysicalScreen;
    mPhysicalScreen = NULL;
  }
}

void Graphics::Update( void * _buffer, int _width, int _height )
{
  int zoom = mIntegerZoom;
  if ( zoom == -1 )
  {
    zoom = 1;
    while ( _width * zoom <= mPhysicalWidth && _height * zoom <= mPhysicalHeight )
    {
      zoom++;
    }
    zoom--;
  }

  int zoomedX = _width * zoom;
  int zoomedY = _height * zoom;
  int mCenterX = ( mPhysicalWidth - zoomedX ) / 2;
  int mCenterY = ( mPhysicalHeight - zoomedY ) / 2;

#ifdef _DEBUG
  memset( mPhysicalScreen, 0x30, mPhysicalWidth * mPhysicalHeight * sizeof( unsigned int ) );
#else
  memset( mPhysicalScreen, 0x00, mPhysicalWidth * mPhysicalHeight * sizeof( unsigned int ) );
#endif // _DEBUG

  uint32_t *src = (uint32_t *) _buffer;
  uint32_t *dst = (uint32_t *) mPhysicalScreen + mCenterY * mPhysicalWidth + mCenterX;
  for ( int y = 0; y < _height; y++ )
  {
    uint32_t * srcline = NULL;

    srcline = src;
    for ( int x = 0; x < _width; x++ )
    {
      for ( int xz = 0; xz < zoom; xz++ )
      {
        *( dst++ ) = *srcline;
      }
      srcline++;
    }
    dst += mPhysicalWidth - ( _width * zoom );

    for ( int yz = 1; yz < zoom; yz++ )
    {
      memcpy( dst, dst - mPhysicalWidth, zoomedX * sizeof( unsigned int ) );
      dst += mPhysicalWidth;
    }
    src = srcline;
  }

  Blit( mPhysicalScreen );
}

/* gutted from ddraw */
void Graphics::FastBlit(const uint32_t* vscr, void* surfacePtr, int bpp,
  uint32_t width, uint32_t height, uint32_t noMansLandSizeInBytes)
{
  switch (bpp)
  {
  case 32:
    __asm
    {
      push  es
      mov   ax, ds
      mov   es, ax
      mov   esi, [vscr]
      mov   edi, [surfacePtr]
      mov   ecx, [height]
      Oneline32:
      push  ecx
        mov   ecx, [width]
        rep   movsd
        add   edi, [noMansLandSizeInBytes]
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
      mov   esi, [vscr]
      mov   edi, [surfacePtr]
      mov   ecx, [height]
      Oneline24:
      push  ecx
        mov   ecx, [width]
        Onepix24 :
        movsw
        movsb
        inc   esi
        loop  Onepix24
        add   edi, [noMansLandSizeInBytes]
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
      mov   esi, [vscr]
      mov   edi, [surfacePtr]
      mov   ecx, [height]
      Oneline16:
      push  ecx
        mov   ecx, [width]
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
        add   edi, [noMansLandSizeInBytes]
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
      mov   esi, [vscr]
      mov   edi, [surfacePtr]
      mov   ecx, [height]
      Oneline15:
      push  ecx
        mov   ecx, [width]
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
        add   edi, [noMansLandSizeInBytes]
        pop   ecx
        loop  Oneline15
        pop   es
    } break;
  }
}

/* ---------------------------------------------------------------------------------------------- */
/* GraphicsWindows */

GraphicsWindows::GraphicsWindows()
  : Graphics()
  , mHWnd(0)
  , mWantsToQuit(0)
{
  ZeroMemory(&mRectWindow, sizeof(RECT));
  ZeroMemory(&mRectViewport, sizeof(RECT));
  ZeroMemory(&mRectScreen, sizeof(RECT));
}

GraphicsWindows::~GraphicsWindows()
{
  Close();
}

bool GraphicsWindows::Init(int _screenWidth, int _screenHeight, int _zoom, WindowType _windowType)
{
  if (!Graphics::Init(_screenWidth, _screenHeight, _zoom, _windowType))
    return false;

  HINSTANCE _instance = GetModuleHandle(NULL);

  DWORD wExStyle = WS_EX_APPWINDOW;
  DWORD wStyle = WS_POPUP | WS_CLIPSIBLINGS | WS_CLIPCHILDREN | WS_VISIBLE;
  if (mWindowType == WindowType::Windowed)
  {
    wStyle |= WS_OVERLAPPED | WS_CAPTION;
  }

  WNDCLASS wndClass;
  wndClass.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
  wndClass.lpfnWndProc = &WndProcStatic;
  wndClass.cbClsExtra = 0;
  wndClass.cbWndExtra = 0;
  wndClass.hInstance = _instance;
  wndClass.hIcon = LoadIcon(_instance, MAKEINTRESOURCE(IDI_ICON1));
  wndClass.hCursor = LoadCursor(NULL, IDC_ARROW);
  wndClass.hbrBackground = NULL;
  wndClass.lpszMenuName = NULL;
  wndClass.lpszClassName = _T("ud2dwindow");

  if (!RegisterClass(&wndClass) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS)
  {
    return false;
  }

  RECT windowRect = { 0,0,mPhysicalWidth,mPhysicalHeight };
  AdjustWindowRectEx(&windowRect, wStyle, FALSE, wExStyle);

  mHWnd = CreateWindowEx(wExStyle, wndClass.lpszClassName, _T("Second Reality (Win32)"), wStyle,
    (GetSystemMetrics(SM_CXSCREEN) - (windowRect.right - windowRect.left)) / 2,
    (GetSystemMetrics(SM_CYSCREEN) - (windowRect.bottom - windowRect.top)) / 2,
    windowRect.right - windowRect.left, windowRect.bottom - windowRect.top,
    NULL, NULL, _instance, this);

  if (!mHWnd)
  {
    return false;
  }

  ShowWindow(mHWnd, SW_SHOW);
  SetForegroundWindow(mHWnd);
  SetFocus(mHWnd);

  GetClientRect(mHWnd, &mRectViewport);
  GetClientRect(mHWnd, &mRectScreen);
  ClientToScreen(mHWnd, (POINT*)&mRectScreen.left);
  ClientToScreen(mHWnd, (POINT*)&mRectScreen.right);

  mWantsToQuit = false;

  ShowCursor(FALSE);

  return true;
}

void GraphicsWindows::Close()
{
  if (mHWnd) {
    ShowWindow(mHWnd, SW_HIDE); // window doesn't actually get killed without this (?)
    DestroyWindow(mHWnd);
  }

  Graphics::Close();
}

void GraphicsWindows::HandleMessages()
{
  MSG msg;
  if (PeekMessage(&msg, mHWnd, 0U, 0U, PM_REMOVE))
  {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
}

LRESULT CALLBACK GraphicsWindows::WndProc( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam )
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
        if ( mWindowType == WindowType::Fullscreen )
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
              // this isn't necessary, and also isn't how you're supposed to do it.
              // MSDN: "Do not post the WM_QUIT message using the PostMessage function; use PostQuitMessage."
              //PostMessage( hWnd, WM_QUIT, 0, 0 );
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
        //PostMessage( hWnd, WM_QUIT, 0, 0 );
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

LRESULT CALLBACK GraphicsWindows::WndProcStatic(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
  GraphicsWindows* This;

  if (uMsg == WM_CREATE) {
    This = (GraphicsWindows *)((LPCREATESTRUCT)lParam)->lpCreateParams;
    SetWindowLongPtr(hWnd, GWLP_USERDATA, (LONG_PTR)This);
  } else {
    This = (GraphicsWindows*)GetWindowLongPtr(hWnd, GWLP_USERDATA);
  }

  return This->WndProc(hWnd, uMsg, wParam, lParam);
}

/* ---------------------------------------------------------------------------------------------- */
/* GraphicsWindowsDDraw */

GraphicsWindowsDDraw::GraphicsWindowsDDraw()
  : GraphicsWindows()
  , mDirectDraw(NULL)
  , mSurfacePrimary(NULL)
  , mSurfaceSecondary(NULL)
  , mBPP(0)
  , mhDDraw(NULL)
{
  /* nothing */
}

GraphicsWindowsDDraw::~GraphicsWindowsDDraw()
{
  Close();
}

bool GraphicsWindowsDDraw::Init(int _screenWidth, int _screenHeight, int _zoom, WindowType _windowType)
{
  HRESULT result;

  {
    /* dynload ddraw for systems without it (archaic)
     * this is done before window creation, because that works around unnecessary
     * window creation (when ddraw isn't available) */
    typedef HRESULT(__stdcall* tpDirectDrawCreateEx)(GUID* lpGuid, LPVOID* lplpDD, REFIID   iid, IUnknown* pUnkOuter);
    tpDirectDrawCreateEx pDirectDrawCreateEx;

    mhDDraw = LoadLibraryA("DDRAW.DLL");
    if (!mhDDraw)
      return false;

    pDirectDrawCreateEx = (tpDirectDrawCreateEx)GetProcAddress(mhDDraw, "DirectDrawCreateEx");
    if (!pDirectDrawCreateEx)
      return false;

    result = pDirectDrawCreateEx(NULL, (VOID**)&mDirectDraw, IID_IDirectDraw7, NULL);

    if (result != DD_OK)
      return false;
  }

  if (!GraphicsWindows::Init(_screenWidth, _screenHeight, _zoom, _windowType))
    return false;

  if (mWindowType == WindowType::Fullscreen)
  {
    result = mDirectDraw->SetCooperativeLevel(mHWnd, DDSCL_EXCLUSIVE | DDSCL_FULLSCREEN);
    if (result != DD_OK)
    {
      return false;
    }

    result = mDirectDraw->SetDisplayMode(mPhysicalWidth, mPhysicalHeight, mBPP = 32, 0, 0);
    if (result != DD_OK)
    {
      result = mDirectDraw->SetDisplayMode(mPhysicalWidth, mPhysicalHeight, mBPP = 24, 0, 0);
      if (result != DD_OK)
      {
        result = mDirectDraw->SetDisplayMode(mPhysicalWidth, mPhysicalHeight, mBPP = 16, 0, 0);
        if (result != DD_OK)
        {
          return false;
        }
        else
        {
          DDSURFACEDESC2 ddsd;
          ZeroMemory(&ddsd, sizeof(ddsd));
          ddsd.dwSize = sizeof(ddsd);
          mDirectDraw->GetDisplayMode(&ddsd);
          if (mBPP == 16)
          {
            if (ddsd.ddpfPixelFormat.dwRBitMask == 0x7c00)
            {
              mBPP = 15;
            }
            else if (ddsd.ddpfPixelFormat.dwRBitMask != 0xf800)
            {
              return false;
            }
          }
        }
      }
    }

    DDSURFACEDESC2 ddsd;
    ZeroMemory(&ddsd, sizeof(ddsd));
    ddsd.dwSize = sizeof(ddsd);
    ddsd.dwFlags = DDSD_CAPS | DDSD_BACKBUFFERCOUNT;
    ddsd.ddsCaps.dwCaps = DDSCAPS_PRIMARYSURFACE | DDSCAPS_FLIP | DDSCAPS_COMPLEX;
    ddsd.dwBackBufferCount = 1;
    result = mDirectDraw->CreateSurface(&ddsd, &mSurfacePrimary, NULL);
    if (result != DD_OK)
    {
      return false;
    }

    DDSCAPS2 ddscaps;
    ZeroMemory(&ddscaps, sizeof(ddscaps));
    ddscaps.dwCaps = DDSCAPS_BACKBUFFER;
    result = mSurfacePrimary->GetAttachedSurface(&ddscaps, &mSurfaceSecondary);
    if (result != DD_OK)
    {
      return false;
    }
  }
  else
  {
    result = mDirectDraw->SetCooperativeLevel(mHWnd, DDSCL_NORMAL);
    if (result != DD_OK)
    {
      return false;
    }

    DDSURFACEDESC2 ddsd;
    ZeroMemory(&ddsd, sizeof(ddsd));
    ddsd.dwSize = sizeof(ddsd);
    ddsd.dwFlags = DDSD_CAPS;
    ddsd.ddsCaps.dwCaps = DDSCAPS_PRIMARYSURFACE;
    result = mDirectDraw->CreateSurface(&ddsd, &mSurfacePrimary, NULL);
    if (result != DD_OK)
    {
      return false;
    }

    LPDIRECTDRAWCLIPPER pClipper;
    result = mDirectDraw->CreateClipper(0, &pClipper, NULL);
    if (result != DD_OK)
    {
      return false;
    }

    pClipper->SetHWnd(0, mHWnd);
    result = mSurfacePrimary->SetClipper(pClipper);
    pClipper->Release();
    if (result != DD_OK)
    {
      return false;
    }

    ddsd.dwFlags = DDSD_WIDTH | DDSD_HEIGHT | DDSD_CAPS;
    ddsd.dwWidth = mPhysicalWidth;
    ddsd.dwHeight = mPhysicalHeight;
    ddsd.ddsCaps.dwCaps = DDSCAPS_OFFSCREENPLAIN;
    result = mDirectDraw->CreateSurface(&ddsd, &mSurfaceSecondary, NULL);
    if (result != DD_OK)
    {
      return false;
    }

    mBPP = GetDeviceCaps(GetDC(mHWnd), BITSPIXEL);
  }

  return true;
}

void GraphicsWindowsDDraw::Close()
{
  if (mDirectDraw != NULL)
  {
    mDirectDraw->SetCooperativeLevel(mHWnd, DDSCL_NORMAL);
    if (mSurfaceSecondary != NULL)
    {
      mSurfaceSecondary->Release();
      mSurfaceSecondary = NULL;
    }
    if (mSurfacePrimary != NULL)
    {
      mSurfacePrimary->Release();
      mSurfacePrimary = NULL;
    }
    mDirectDraw->Release();
  }

  if (mhDDraw != NULL)
    FreeLibrary(mhDDraw);

  GraphicsWindows::Close();
}

void GraphicsWindowsDDraw::Blit(void* _buffer)
{
  uint32_t* vscr = (unsigned int*)_buffer;

  DDSURFACEDESC2 ddsdBack;
  ZeroMemory(&ddsdBack, sizeof(DDSURFACEDESC));
  ddsdBack.dwSize = sizeof(ddsdBack);
  if (mSurfaceSecondary->Lock(0, &ddsdBack, DDLOCK_SURFACEMEMORYPTR | DDLOCK_WAIT, 0) == DD_OK)
  {
    long noMansLandSizeInBytes = ddsdBack.lPitch - ddsdBack.dwWidth * ((mBPP + 1) / 8);
    LPVOID surfacePtr = ddsdBack.lpSurface;

    FastBlit(vscr, surfacePtr, mBPP, ddsdBack.dwWidth, ddsdBack.dwHeight, noMansLandSizeInBytes);

    mSurfaceSecondary->Unlock(NULL);
  }

  HRESULT hRes = (mWindowType == WindowType::Fullscreen)
    ? mSurfacePrimary->Flip(NULL, NULL)
    : mSurfacePrimary->Blt(&mRectScreen, mSurfaceSecondary, &mRectViewport, DDBLT_WAIT, NULL);

  if (hRes == DDERR_SURFACELOST)
  {
    mSurfacePrimary->Restore();
  }
}

/* ---------------------------------------------------------------------------------------------- */
/* GraphicsWindowsGDI */

GraphicsWindowsGDI::GraphicsWindowsGDI()
  : GraphicsWindows()
  , mBITMAP(NULL)
  , mBmpBuf(NULL)
{
}

GraphicsWindowsGDI::~GraphicsWindowsGDI()
{
  Close();
}

bool GraphicsWindowsGDI::Init(int width, int height, int zoom, WindowType type)
{
  BITMAPINFO bmi = { 0 };
  HDC hdc;

  if (!GraphicsWindows::Init(width, height, zoom, type))
    return false;

  /* now initialize our bitmap :) */
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = width;
  bmi.bmiHeader.biHeight = -height; /* bitmaps are negative */
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  hdc = GetDC(mHWnd);

  mBITMAP = CreateDIBSection(hdc, &bmi, DIB_RGB_COLORS, (void**)&mBmpBuf, NULL, 0);
  if (!mBITMAP || !mBmpBuf)
    return false;

  ReleaseDC(mHWnd, hdc);

  return true;
}

void GraphicsWindowsGDI::Close()
{
  if (mBITMAP) {
    DeleteObject(mBITMAP);
    mBITMAP = NULL;
    mBmpBuf = NULL;
  }
}

void GraphicsWindowsGDI::Blit(void *buffer)
{
  HDC hdc;
  HDC hdcMem;
  HGDIOBJ old;

  hdc = GetDC(mHWnd);
  hdcMem = CreateCompatibleDC(hdc);
  old = SelectObject(hdcMem, mBITMAP);

  /* i'm looking for somebody who is 4 */
  memcpy(mBmpBuf, buffer, mPhysicalWidth * mPhysicalHeight * 4);

  BitBlt(hdc, 0, 0, mPhysicalWidth, mPhysicalHeight, hdcMem, 0, 0, SRCCOPY);

  SelectObject(hdcMem, old);
  DeleteDC(hdcMem);
  ReleaseDC(mHWnd, hdc);
}
