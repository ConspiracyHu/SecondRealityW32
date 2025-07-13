#include "..\dis\dis.h"

extern void plz();
extern void vect();
extern void initvect();

void plz_main()  {
	dis_partstart();
	//init_copper();
	initvect();
	plz();
	vect();
	//close_copper();
	}