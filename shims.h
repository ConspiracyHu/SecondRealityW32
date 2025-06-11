#ifdef __cplusplus
#define EXTERN extern "C"
#else
#define EXTERN extern
#endif

EXTERN unsigned int shim_palette[];
EXTERN unsigned char shim_vram[];
EXTERN void shim_outp( int reg, unsigned char value );
EXTERN unsigned char shim_inp( int reg );
