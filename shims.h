#pragma warning(disable: 4101)

#include <stdio.h>

#ifdef __cplusplus
#define EXTERN extern "C"
#else
#define EXTERN extern
#endif

#define shim_vram_x 640
#define shim_vram_y 960

EXTERN unsigned int shim_palette[];
EXTERN unsigned int shim_startpixel;
EXTERN unsigned char shim_vram[];
EXTERN void shim_setpal( int idx, unsigned char r, unsigned char g, unsigned char b );
EXTERN void shim_outp( int reg, unsigned int value );
EXTERN unsigned char shim_inp( int reg );
EXTERN void shim_setstartpixel( int reg );

EXTERN void demo_blit();
EXTERN void demo_changemode( int x, int y );
EXTERN char demo_isfirstpart();
EXTERN void demo_finishedfirstpart();

EXTERN FILE * blob_fopen( const char * filename, const char * mode );
EXTERN int blob_fread( void * buffer, int element_size, int element_count, FILE * file );
EXTERN void blob_fseek( FILE * file, int offset, int origin );
EXTERN int blob_ftell( FILE * file );
EXTERN void blob_fclose( FILE * file );
EXTERN unsigned int blob_hash( const char * p );