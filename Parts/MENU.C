#include <stdio.h>
#include <windows.h>

COORD screen_coord = { 0,0 };
CHAR_INFO screen_buffer[ 80 * 50 ];
int screen_color = 0;
void gotoxy( int x, int y )
{
	screen_coord.X = (short)x;
	screen_coord.Y = (short)y;
}

#define dosgotoxy(x,y) gotoxy(x,y)

int col[] = {
0x00, /* 0=default color */
0x08, /* 1=switch name */
0x09, /* 2=switch value */
0x0a, /* 3=switch description */
0x0b, /* 4=bottom line */
0x0c, /* 5=bottom line key */
0x0f, /* 6=DONOTDISTRIBUTE */
};

void menu_prtt( const char * str )
{
	for ( int i = 0; str[ i ]; i++ )
	{
		if ( screen_coord.Y >= 25 )
		{
			break;
		}
		switch ( str[ i ] )
		{
		case 126:
			{
				char a = str[ ++i ];
				if ( !a ) break;
				screen_color = col[ a - '0' ];
				//vramcol = col[ a - '0' ];
				//if ( vramforce ) vramusecol = vramforce;
				//else vramusecol = vramcol | vramor;
			}
			break;
		case 10:
			{
				gotoxy( 0, screen_coord.Y + 1 );
			}
			break;
		default:
			{
				if ( screen_color )
				{
					CHAR_INFO * c = &screen_buffer[ screen_coord.X + screen_coord.Y * 80 ];
					c->Attributes = screen_color;
					c->Char.AsciiChar = str[ i ];
				}
				screen_coord.X++;
				//prtc( a );
			}
		}
	}
}

#define prtf menu_prtt

#define delay(x)

int	nilli = 0;
int	menuy = 0;
int * menux = &nilli;

int	m_detail = 0;
int	m_soundcard = 3;
int	m_soundquality = 2;
int	m_looping = 0;
int	m_proceed = 0;
int	m_exit = 0;

int	m_windowmode = 0;

int mainmenu();

#define DOS_RGB(r,g,b) ((COLORREF)( ((DWORD)((BYTE)(r))<<2) | ((DWORD)((BYTE)(g))<<10) | (((DWORD)(BYTE)(b))<<18) ))

void menu()
{
	int	y, a;

	delay( 1 );

	CONSOLE_SCREEN_BUFFER_INFOEX info = { 0 };
	info.cbSize = sizeof( CONSOLE_SCREEN_BUFFER_INFOEX );
	GetConsoleScreenBufferInfoEx( GetStdHandle( STD_OUTPUT_HANDLE ), &info );
	info.dwSize.Y = 25;
	info.dwMaximumWindowSize.Y = 25;
	int color = 0;
	info.ColorTable[ color++ ] = DOS_RGB( 0, 0, 0 );
	info.ColorTable[ color++ ] = DOS_RGB( 16, 16, 24 ); // bar
	info.ColorTable[ color++ ] = DOS_RGB( 13, 0, 0 );
	info.ColorTable[ color++ ] = DOS_RGB( 43, 0, 0 );
	info.ColorTable[ color++ ] = DOS_RGB( 23, 0, 0 );
	info.ColorTable[ color++ ] = DOS_RGB( 53, 0, 0 );
	info.ColorTable[ color++ ] = DOS_RGB( 33, 0, 0 ); // do not use
	info.ColorTable[ color++ ] = DOS_RGB( 63, 0, 0 );

	info.ColorTable[ color++ ] = DOS_RGB( 0, 50, 63 );
	info.ColorTable[ color++ ] = DOS_RGB( 0, 60, 63 );
	info.ColorTable[ color++ ] = DOS_RGB( 25, 25, 30 );
	info.ColorTable[ color++ ] = DOS_RGB( 0, 30, 60 );
	info.ColorTable[ color++ ] = DOS_RGB( 0, 50, 60 );
	info.ColorTable[ color++ ] = DOS_RGB( 63, 0, 0 );
	info.ColorTable[ color++ ] = DOS_RGB( 63, 0, 0 );
	info.ColorTable[ color++ ] = DOS_RGB( 63, 0, 0 );

	SetConsoleScreenBufferInfoEx( GetStdHandle( STD_OUTPUT_HANDLE ), &info );

//	outp( 0x3c8, 0 );
//	for ( a = 0; a < 768; a++ ) outp( 0x3c9, 0 );

	delay( 5 );

	dosgotoxy( 0, 50 );
	gotoxy( 0, 0 );
	for ( y = 0; y < 50; y++ ) menu_prtt( "~0                                                                                " );
	gotoxy( 0, 0 );
	menu_prtt( "    ~4\xF9~5S~4\xF9~5E~4\xF9~5C~4\xF9~5O~4\xF9~5N~4\xF9~5D~4\xF9~5 ~4\xF9~5R~4\xF9~5E~4\xF9~5A~4\xF9~5L~4\xF9~5I~4\xF9~5T~4\xF9~5Y~4\xF9  "
		"~3(7-OCT-93)~0 ~4 Copyright (C) 1993 ~5Future Crew~4" );
	/*
	gotoxy(0,2);
	prtt("  ~6Do not distribute! (just had to say that) This version must not be shown to \n");
	prtt("  ~6anyone outside Future Crew. Remember, officially: we aren't sure we can get \n");
	prtt("  ~6this thing finished for Assembly, but we sure are trying to!");
	*/
	gotoxy( 0, 24 );
	menu_prtt( "    ~5\x18~4/~5\x19~4 - change selection  ~5\x1b~4/~5\x1a~4 - change an entry  ~5<\xC4\xD9~4 - continue  ~5ESC~4 - exit " );

	mainmenu();

	delay( 20 );

	for (;;)
	{
		//a = getch();
		INPUT_RECORD inputs[ 10 ] = { 0 };
		DWORD event_count = 0;
		ReadConsoleInput( GetStdHandle( STD_INPUT_HANDLE ), inputs, 10, &event_count );
		static int debounceTimer = 0;

		for ( int i = 0; i < event_count; i++ )
		{
			const INPUT_RECORD * input = &inputs[ i ];
			if ( input->EventType != KEY_EVENT )
			{
				continue;
			}
			int time = GetTickCount();
			if ( time - debounceTimer < 100 )
			{
				continue;
			}
			debounceTimer = time;

			a = 0;
			if ( input->Event.KeyEvent.wVirtualKeyCode == 13 )
			{
				m_proceed = 1;
				break;
			}
			if ( input->Event.KeyEvent.wVirtualKeyCode == 27 )
			{
				m_exit = 1;
				break;
			}
			//if ( !a ) a = 1000 + getch();
			switch ( input->Event.KeyEvent.wVirtualKeyCode )
			{
			case VK_UP: menuy--; break;
			case VK_DOWN: menuy++; break;
			case VK_LEFT: ( *menux )--; break;
			case VK_RIGHT: ( *menux )++; break;
			}
			FlushConsoleInputBuffer( GetStdHandle( STD_INPUT_HANDLE ) );
			break;
		}
		if ( m_exit || m_proceed )
		{
			break;
		}
		mainmenu();

		const COORD full_screen = { 80,50 };
		const COORD screen_start = { 0,0 };
		SMALL_RECT write_region = { 0,0,80,50 };
		WriteConsoleOutput( GetStdHandle( STD_OUTPUT_HANDLE ), screen_buffer, full_screen, screen_start, &write_region );
	}

	gotoxy( 0, 0 );
	for ( y = 0; y < 50; y++ ) menu_prtt( "~0                                                                                " );

	if ( !m_soundcard )
	{
		gotoxy( 0, 10 );
		menu_prtt( "~4        You have selected the ~5no sound~4 option. Please note that even\n"
			"        though the music is not playing, the demo is still syncronized to\n"
			"        it. This means that there are delays (like in the beginning) that\n"
			"        feel unnecessarily long. There is no way to skip parts while you\n"
			"        watch the demo, so you can only wait.\n" );
		menu_prtt( "~5\n        Press any key to continue...\n" );
		//getch();
		gotoxy( 0, 0 );
		for ( y = 0; y < 50; y++ ) menu_prtt( "~0                                                                                " );
	}
}

int	menucolorize( int index, int * x )
{
	int	a;
	static char * v;
	if ( menuy == index - 1 )
	{
		screen_buffer[ 4 + screen_coord.X + screen_coord.Y * 80 ].Char.AsciiChar = 175;
		//v[4*2+1]=7;
		screen_buffer[ 80 - 4 + screen_coord.X + screen_coord.Y * 80 ].Char.AsciiChar = 174;
		//v[80*2-4*2+1]=7;
	}
	if ( menuy == index )
	{
		menux = x;
		col[ 1 ] |= 0x10;
		col[ 2 ] |= 0x10;
	}
	else
	{
		col[ 1 ] &= ~0x10;
		col[ 2 ] &= ~0x10;
	}
	//v = vram + vramp;
	return 0;
}

int	mainmenu( void )
{
	int	a;

#ifdef OLD_MENU
	int menucount = 3;
#else
	int menucount = 2;
#endif

	if ( menuy < 1 ) menuy = 1;
	if ( menuy > menucount ) menuy = menucount;

#ifdef OLD_MENU
	if ( m_detail < 0 ) m_detail = 1;
	if ( m_detail > 1 ) m_detail = 0;
	if ( m_soundcard < 0 ) m_soundcard = 3;
	if ( m_soundcard > 3 ) m_soundcard = 0;
	if ( m_soundquality < 0 ) m_soundquality = 2;
	if ( m_soundquality > 2 ) m_soundquality = 0;
#else
        if ( m_windowmode < 0 ) m_windowmode = 1;
        if ( m_windowmode > 1 ) m_windowmode = 0;
#endif
	if ( m_looping < 0 ) m_looping = 1;
	if ( m_looping > 1 ) m_looping = 0;

	gotoxy( 0, 2 );

	/*
		menucolorize(0,&m_detail);
		switch(m_detail)
		{
		case 0:	prtf(
	"~0    ~1       Detail:~2 Full (486 or higher)                                      ~0  \n"
			); break;
		case 1:	prtf(
	"~0    ~1       Detail:~2 Reduced (386)                                             ~0  \n"
			); break;
		}
	*/
	col[ 1 ] &= ~0x10; col[ 2 ] &= ~0x10; prtf(
		"~0        ~3 This demonstration has been designed for fast machines, which         ~0  \n"
		"~0        ~3 in this case means 33Mhz 486 computers. The demo also runs on         ~0  \n"
		"~0        ~3 slower 386 computers, but some parts will naturally slow down.        ~0  \n"
		"~0        ~3 In case you encounter difficulties running this demo, try             ~0  \n"
		"~0        ~3 rebooting you computer with a clean boot (no TSRs etc.)               ~0  \n"
		"\n" );

	int menu_index = 1;
#ifdef OLD_MENU
	menucolorize( menu_index++, &m_soundcard );
	switch ( m_soundcard )
	{
	case 0:	prtf(
		"~0    ~1       Soundcard:~2 No sound                                               ~0  \n"
	); break;
	case 1:	prtf(
		"~0    ~1       Soundcard:~2 SoundBlaster (mono)                                    ~0  \n"
	); break;
	case 2:	prtf(
		"~0    ~1       Soundcard:~2 SoundBlaster Pro (stereo)                              ~0  \n"
	); break;
	case 3:	prtf(
		"~0    ~1       Soundcard:~2 Gravis Ultrasound, 512K of memory (stereo)             ~0  \n"
	); break;
	}
	col[ 1 ] &= ~0x10; col[ 2 ] &= ~0x10; prtf(
		"~0        ~3 With Gravis Ultrasound or no music, the demo requires only            ~0  \n"
		"~0        ~3 570,000 bytes of conventional memory. With SoundBlaster, an           ~0  \n"
		"~0        ~3 additional 1MB of expanded memory (EMS) is required.                  ~0  \n"
		"\n" );


	menucolorize( menu_index++, &m_soundquality );
	switch ( m_soundquality )
	{
	case 0:	prtf(
		"~0    ~1       Sound quality:~2 Poor                                               ~0  \n"
	); break;
	case 1:	prtf(
		"~0    ~1       Sound quality:~2 Standard                                           ~0  \n"
	); break;
	case 2:	prtf(
		"~0    ~1       Sound quality:~2 High                                               ~0  \n"
	); break;
	}
	col[ 1 ] &= ~0x10; col[ 2 ] &= ~0x10; prtf(
		"~0        ~3 For SoundBlaster cards, the quality directly effects the mixing       ~0  \n"
		"~0        ~3 rate. For the Gravis Ultrasound, the quality has no effect. If        ~0  \n"
		"~0        ~3 the demo runs too slowly, try decreasing the sound quality.           ~0  \n"
		"\n" );

#else
	menucolorize( menu_index++, &m_windowmode );
	switch ( m_windowmode )
	{
	case 0:	prtf(
		"~0    ~1       Window mode:~2 Fullscreen                                           ~0  \n"
	); break;
	case 1:	prtf(
		"~0    ~1       Window mode:~2 Windowed (1280x720)                                  ~0  \n"
	); break;
	}
	col[ 1 ] &= ~0x10; col[ 2 ] &= ~0x10; prtf(
		"~0        ~3 The fullscreen mode is actually just borderless window,               ~0  \n"
		"~0        ~3 because disabling vertical synchronization in fullscreen              ~0  \n"
		"~0        ~3 DirectDraw is problematic.                                            ~0  \n"
		"\n" );
#endif

        menucolorize( menu_index++, &m_looping );
        switch ( m_looping )
        {
        case 0:	prtf(
                "~0    ~1       Demo looping:~2 Disabled                                            ~0  \n"
        ); break;
        case 1:	prtf(
                "~0    ~1       Demo looping:~2 Enabled (no end scroller shown)                     ~0  \n"
        ); break;
        }
        col[ 1 ] &= ~0x10; col[ 2 ] &= ~0x10; prtf(
                "~0        ~3 If you wish the demo to run continuously, enable this option.         ~0  \n"
                "\n" );

        menucolorize( menu_index++, &m_looping );

	return 0;
}
