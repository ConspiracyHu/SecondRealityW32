#ifndef GRAPHICS_H_
#define GRAPHICS_H_

#include <windows.h>
#include <ddraw.h>
#include <stdint.h>

class Graphics
{
public:
  enum WindowType
  {
    Fullscreen,
    Windowed,
    Borderless,
  };

  Graphics();
  virtual ~Graphics();

  void Update(void *buffer, int width, int height);

  virtual bool Init( int _width, int _height, int _zoom, WindowType _fullscreen );
  virtual void Close();

  virtual void HandleMessages() = 0;

  virtual const bool WantsToQuit() const = 0;

protected:
  virtual void Blit( void * _screenBuffer ) = 0;

  /* fast blit function from 32-bit -> some bpp */
  static void FastBlit(const uint32_t* vscr, void* surfacePtr, int bpp,
    uint32_t width, uint32_t height, uint32_t noMansLandSizeInBytes);

  int mPhysicalWidth;
  int mPhysicalHeight;
  int mIntegerZoom;

  WindowType mWindowType;
  uint32_t *mPhysicalScreen;
};

/* graphics stuff specific to Windows */
class GraphicsWindows : public Graphics
{
public:
  GraphicsWindows();
  virtual ~GraphicsWindows();

  virtual bool Init( int _width, int _height, int _zoom, WindowType _fullscreen ) override;
  virtual void HandleMessages() override;
  virtual void Close() override;

  virtual const bool WantsToQuit() const override { return mWantsToQuit; }

protected:
  /* handled by gdi/ddraw/etc */
  virtual void Blit( void * _screenBuffer ) = 0;

  /* and now to the goodies */
  static LRESULT CALLBACK WndProcStatic( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam );
  LRESULT CALLBACK WndProc( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam );

  RECT mRectWindow;
  RECT mRectViewport;
  RECT mRectScreen;

  HWND mHWnd;

  bool mWantsToQuit;
};

class GraphicsWindowsDDraw : public GraphicsWindows
{
public:
  GraphicsWindowsDDraw();
  virtual ~GraphicsWindowsDDraw();

  virtual bool Init(int width, int height, int zoom, WindowType type) override;
  virtual void Close() override;

protected:
  virtual void Blit(void* buffer) override;

  LPDIRECTDRAW7 mDirectDraw;
  LPDIRECTDRAWSURFACE7 mSurfacePrimary;
  LPDIRECTDRAWSURFACE7 mSurfaceSecondary;
  int mBPP; /* BITS per pixel */

  /* needs to stay in memory for as long as graphics are open */
  HMODULE mhDDraw;
};

class GraphicsWindowsGDI : public GraphicsWindows
{
public:
  GraphicsWindowsGDI();
  virtual ~GraphicsWindowsGDI();

  virtual bool Init(int width, int height, int zoom, WindowType type) override;
  virtual void Close() override;

protected:
  virtual void Blit(void* buffer) override;

  HBITMAP mBITMAP;
  uint32_t* mBmpBuf;
};

#endif /* GRAPHICS_H_ */