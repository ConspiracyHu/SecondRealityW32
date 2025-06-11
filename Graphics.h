#include <windows.h>
#include <ddraw.h>

class Graphics
{
public:
  Graphics();
  ~Graphics();

  bool Init( HINSTANCE _instance, int _screenWidth, int _screenHeight, int _width, int _height, bool _fullscreen );
  void Update( void * _screenBuffer );
  void HandleMessages();
  void Close();

  const bool WantsToQuit() const { return mWantsToQuit; }
  const HWND GetWindowHandle() const { return mHWnd; }

private:
  void Blit( void * _screenBuffer );

  static LRESULT CALLBACK WndProcStatic( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam );
  LRESULT CALLBACK WndProc( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam );

  LPDIRECTDRAW7	mDirectDraw;
  LPDIRECTDRAWSURFACE7 mSurfacePrimary;
  LPDIRECTDRAWSURFACE7 mSurfaceSecondary;
  int mBPP;

  RECT mRectWindow;
  RECT mRectViewport;
  RECT mRectScreen;

  HWND mHWnd;
  
  int mPhysicalWidth;
  int mPhysicalHeight;
  int mVirtualWidth;
  int mVirtualHeight;
  int mIntegerZoom;
  int mCenterX;
  int mCenterY;

  bool mWantsToQuit;
  bool mFullscreen;
  unsigned int * mPhysicalScreen;
};