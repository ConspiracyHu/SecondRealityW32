typedef struct
{
  object * o;
  long	dist;
  int	index;
  int	on;
} s_co;

typedef struct
{
  char * data;
} s_scl;

#define MAXOBJ 256

#define LONGAT(zz) *((long *)(zz))
#define INTAT(zz) *((short *)(zz))
#define CHARAT(zz) *((char *)(zz))

extern char	tmpname[ 64 ];
extern char * scene0;
extern char * scenem;

extern int	city;
extern int	xit;

extern s_scl scenelist[ 64 ];
extern int scl,sclp;
extern s_co co[MAXOBJ];
extern int conum;

extern int	indemo;

extern char	fpal[768];
extern object camobject;
extern rmatrix cam;

extern int	order[ MAXOBJ ], ordernum;
extern unsigned char * sp;

typedef struct
{
  int	frames;
  int	ready; // 1=to be displayed, 0=displayed
} s_cl;
extern s_cl cl[ 4 ];
extern int	clr, clw;
extern int	firstframe;
extern int	deadlock;
extern int	coppercnt;
extern int	syncframe;
extern int	currframe;
extern int	copperdelay;
extern int	repeat, avgrepeat;

long lsget( unsigned char f );
void	resetscene( void );
void * getmem( long size );
void	freemem( void * p );
char * readfile( char * name );
