#define _CRT_SECURE_NO_WARNINGS

#include "shims.h"

unsigned char shim_vram[ shim_vram_x * shim_vram_y ] = { 0 };
unsigned int shim_palette[ 256 ] = { 0 };
unsigned int shim_startpixel = 0;

int paletteReadIndex = 0;
int paletteReadComponent = 0;
int paletteIndex = 0;
int paletteComponent = 0;

void shim_setpal( int idx, unsigned char r, unsigned char g, unsigned char b )
{
  shim_palette[ idx ] = ( b << 2 ) | ( g << 10 ) | ( r << 18 );
}

void shim_outp( int reg, unsigned int value )
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
      paletteIndex = value & 0xFF;
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
      if ( paletteIndex >= 256 )
      {
        paletteIndex = 0;
      }
    }
    break;
  }
}

void __declspec( naked ) shim_outp_naked()
{
  __asm
  {
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad

    movzx ebx,ax
    push ebx
    movzx ebx,dx
    push ebx
    call shim_outp
    add esp, 8

    popad
    mov esp, ebp
    pop ebp
    retn
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

void shim_setstartpixel( int reg )
{
  shim_startpixel = reg;
}

char is_first_part = 1;
char demo_isfirstpart()
{
  return is_first_part;
}

void demo_finishedfirstpart()
{
  is_first_part = 0;
}

#define BLOB

#ifdef BLOB
typedef struct
{
  unsigned int hash;
  char * ptr;
  unsigned int size;
  unsigned int offset;
} t_blob;

extern t_blob blob_index[];
extern unsigned int blob_file_count;

unsigned int blob_hash( const char * p )
{
  unsigned short u1 = 0x1111;
  unsigned short u2 = 0x1111;
  for ( int a = 0; p[ a ]; a++ )
  {
    unsigned short b = p[ a ];
    b &= ~0x20;
    _asm
    {
      mov	ax, b
      xor u1, ax
      rol	u1, 1
      add	u2, ax
    }
  }
  return (u2 << 16) + u1;
}
#endif

FILE * blob_fopen( const char * filename, const char * mode )
{
#ifdef BLOB
  unsigned int hash = blob_hash( filename );
  for ( int i = 0; i < blob_file_count; i++ )
  {
    if ( blob_index[ i ].hash == hash )
    {
      blob_index[ i ].offset = 0;
      return (FILE *)&blob_index[ i ];
    }
  }
  return NULL;
#else
  char path[ 256 ] = { 0 };
  strncpy( path, "Data\\", sizeof( path ) );
  strncat( path, filename, sizeof( path ) );
  return fopen( path, mode );
#endif // _DEBUG
}

int blob_fread( void * buffer, int element_size, int element_count, FILE * file )
{
#ifdef BLOB
  t_blob * blob = (t_blob *)file;
  int count = element_size * element_count;
  if ( count > blob->size - blob->offset )
  {
    count = blob->size - blob->offset;
  }
  memcpy( buffer, blob->ptr + blob->offset, count );
  blob->offset += count;
  return count;
#else
  return fread( buffer, element_size, element_count, file );
#endif // _DEBUG
}

void blob_fseek( FILE * file, int offset, int origin )
{
#ifdef BLOB
  t_blob * blob = (t_blob *)file;
  switch ( origin )
  {
    case SEEK_SET: blob->offset = offset;  break;
    case SEEK_CUR: blob->offset += offset;  break;
    case SEEK_END: blob->offset = blob->size - offset;  break;
  }
#else
  fseek( file, offset, origin );
#endif
}

int blob_ftell( FILE * file )
{
#ifdef BLOB
  t_blob * blob = (t_blob *)file;
  return blob->offset;
#else
  return ftell( file );
#endif
}


void blob_fclose( FILE * file )
{
#ifndef BLOB
  fclose( file );
#endif // _DEBUG
}
