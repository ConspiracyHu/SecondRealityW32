function dis_waitb:integer;cdecl;external;
function dis_exit:boolean;cdecl;external;
function dis_muscode(code:integer):integer;cdecl;external;
function dis_musplus(code:integer):integer;cdecl;external;
function dis_musorder(code:integer):integer;cdecl;external;
function dis_musrow(code:integer):integer;cdecl;external;

procedure shim_setpal(idx:integer; r:byte; g:byte; b:byte);cdecl;external;
procedure demo_blit;cdecl;external;
function demo_isfirstpart:boolean;cdecl;external;

procedure memcpy(dest:pointer; source:pointer; count: sizeint);cdecl;external;
procedure memset(dest:pointer; val:byte; count: sizeint);cdecl;external;
