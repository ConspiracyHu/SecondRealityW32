%macro FIXWORD 0 ;go to word boundary
	if ($-start) mod 1
	db 0
	endif
%endmacro
	
%macro CDS 0
	mov	ax,cs
	mov	ds,ax
%endmacro

%macro CBEG 0 ;C/Assembler procedure begin
	;push	bp
	;mov	bp,sp
	;push	si
	;push	di
	;push	ds
  push ebp
%endmacro

%macro CEND 0 ;C/Assembler procedure end
	;pop	ds
	;pop	di
	;pop	si
	;pop	bp
  pop ebp
	ret
%endmacro

%macro CBEG0 0 ;C/Assembler procedure begin, minimal
	push	bp
	mov	bp,sp
%endmacro

%macro CEND0 0 ;C/Assembler procedure end, minimal
	pop	bp
	ret
%endmacro

%macro movpar	2 ;loads parameter [par(0..)] to register [reg]
	mov	%1,[bp+%2*2+6]
%endmacro

%macro LOOP_LARGE 1
  loop %%notDone
  jmp %%done
  %%notDone:
  jmp %1
  %%done:
%endmacro