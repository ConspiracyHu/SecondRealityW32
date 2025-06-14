unsigned char shim_vram[ 320 * 240 ] = { 0 };
unsigned int shim_palette[ 256 ] = { 0 };

int paletteReadIndex = 0;
int paletteReadComponent = 0;
int paletteIndex = 0;
int paletteComponent = 0;

void shim_setpal( int idx, unsigned char r, unsigned char g, unsigned char b )
{
  shim_palette[ idx ] = r | ( g << 8 ) | ( b << 16 );
}

void shim_outp( int reg, int value )
{
  switch ( reg )
  {
  case 0x3c7:
    {
      paletteReadIndex = value;
    }
    break;
  case 0x3c8:
    {
      paletteIndex = value;
      paletteComponent = 0;
    }
    break;
  case 0x3c9:
    {
      unsigned char * pal8 = (unsigned char *)shim_palette;
      pal8[paletteIndex * 4 + ( 2 - paletteComponent ) ] = value << 2;
      paletteComponent++;
      if ( paletteComponent == 3 )
      {
        paletteIndex++;
        paletteComponent = 0;
      }
      if ( paletteIndex > 256 )
      {
        paletteIndex = 0;
      }
    }
    break;
  }
}

unsigned char shim_inp( int reg )
{
  unsigned char result = 0;
  switch ( reg )
  {
  case 0x3c9:
    {
      unsigned char * pal8 = (unsigned char *)shim_palette;
      result = pal8[ paletteReadIndex * 4 + (2 - paletteReadComponent) ] >> 2;

      paletteReadComponent++;
      if ( paletteReadComponent == 3 )
      {
        paletteReadIndex++;
        paletteReadComponent = 0;
      }
      if ( paletteReadIndex > 256 )
      {
        paletteReadIndex = 0;
      }
    }
    break;
  }
  return result;
}