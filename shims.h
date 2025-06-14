#ifdef __cplusplus
#define EXTERN extern "C"
#else
#define EXTERN extern
#endif

EXTERN unsigned int shim_palette[];
EXTERN unsigned int shim_startpixel;
EXTERN unsigned char shim_vram[];
EXTERN void shim_setpal( int idx, unsigned char r, unsigned char g, unsigned char b );
EXTERN void shim_outp( int reg, unsigned char value );
EXTERN unsigned char shim_inp( int reg );
EXTERN void shim_setstartpixel( int reg );

EXTERN void demo_blit();
