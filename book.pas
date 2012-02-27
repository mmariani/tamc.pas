unit book;

interface
	uses types, option;

	procedure UpdateOpeningWithMove(fm,tu:xycell_t);
	procedure FillWithNextMoveInTheBook(var fm,tu:xycell_t);
	function AreWeStillInsideTheBook: boolean;
	procedure FreeBook;


implementation
	type
		openp_t = ^open_t;
		open_t = record
			mos: move_t;	(* mossa *)
			son: openp_t;	(* figlio (prossima mossa dell'apertura) *)
			bro: openp_t;	(* fratello (altra variante) *)
		end;

	var	root: openp_t;
		curr: openp_t;		(* punta alla prossima mossa da fare *)


(*
**	stom - (string to move) interpreta una mossa in formato ASCII.
*)
procedure stom(var s:string; var m:move_t);
begin
	m.fm.x := Pos(Copy(s,1,1),'abcdefgh');
	m.fm.y := Pos(Copy(s,2,1),'12345678');
	m.tu.x := Pos(Copy(s,3,1),'abcdefgh');
	m.tu.y := Pos(Copy(s,4,1),'12345678');
end;



(*
**	AreWeStillInTheBook - ritorna TRUE se la prossima mossa puo'
**							essere letta dal libro.
*)
function AreWeStillInsideTheBook: boolean;
begin
	AreWeStillInsideTheBook := curr <> nil;
end;



(*
**	equal - ritorna TRUE se le due mosse sono uguali.
*)
function equal(var m1,m2:move_t): boolean;
begin
	if	(m1.fm.x = m2.fm.x) and
		(m1.fm.y = m2.fm.y) and
		(m1.tu.x = m2.tu.x) and
		(m1.tu.y = m2.tu.y)
			then equal := true
			else equal := false;
end;



(*
**	UpdateOpeningWithMove - scende nel libro con la mossa corrente.
*)
procedure UpdateOpeningWithMove(fm,tu:xycell_t);
var mos: move_t;
var c: openp_t;
begin
	if AreWeStillInsideTheBook then begin
		mos.fm := fm;
		mos.tu := tu;
		while not equal(curr^.mos,mos) and (curr<>nil) do
			curr := curr^.bro;
		if curr <> nil then
			curr := curr^.son;
	end;
end;



(*
**	FillWithNextMoveInTheBook - legge una mossa a caso dal libro.
*)
procedure FillWithNextMoveInTheBook(var fm,tu:xycell_t);
var c: openp_t;
var n: integer;
begin
	c := curr;
	n := 0;
	while c<>nil do begin
		inc(n);
		c := c^.bro;
	end;
	c := curr;
	for n := Random(n) downto 1 do c := c^.bro;

	fm := c^.mos.fm;
	tu := c^.mos.tu;
end;



(*
**	AddOpening - aggiunge un'apertura al libro.
*)
function AddOpening(op:openp_t; s:string): openp_t;
var toadd: string;
var mos: move_t;
var opbak: openp_t;
begin
	if s <> '' then begin
		toadd := Copy(s,1,4);
		stom(s,mos);
		opbak := op;
		while not equal(op^.mos,mos) and (op<>nil) do
			op:=op^.bro;
		if op = nil then begin
			new(op);
			op^.bro := opbak;
			op^.mos := mos;
			op^.son := nil;
		end;
		op^.son := AddOpening(op^.son,Copy(s,5,255));
	end;
	AddOpening := op;
end;



(*
**	ReadBook - legge il libro dal file.
*)
procedure ReadBook;
var fin: text;
var s,sold: string;
var i: integer;
begin
	root := nil;
	sold := '';
	Assign(fin,'openings.tmc');
	Reset(fin);
	if IOResult = 0 then begin
		while not Eof(fin) do begin
			readln(fin,s);
			i := 1;
			while i < Length(s) do begin
				if Copy(s,i,1) = '	' then begin		(* TAB *)
					Delete(s,i,1);
					Insert(Copy(sold,i,4),s,i);
				end;
				inc(i);
			end;
			if Copy(s,Length(s),1) = '.'
				then s := Copy(s,1,Length(s)-1);
			sold := s;
			if Copy(s,1,1)<>';'
				then root := AddOpening(root,s);		(* commento *)
		end;
		Close(fin);
	end
	else root := nil;
end;



(*
**	itoa - (integer to ASCII)
*)
function itoa(i:integer): string;
var s: string;
begin
	Str(i,s);
	itoa := s;
end;



(*
**	ResetBook - resetta il puntatore alla madre di tutte le aperture.
*)
procedure ResetBook;
begin
	curr := root;
end;



(*
**	FreeBook - libera la memoria occupata.
*)
procedure FreeBook;

	procedure freenode(op:openp_t);
	begin
		if op <> nil then begin
			freenode(op^.son);
			freenode(op^.bro);
			dispose(op);
		end;
	end;

begin
	freenode(root);
end;


begin	(* inizializza *)
{$ifdef AMAZON}
	curr := nil;
{$else}
	ReadBook;
	ResetBook;
{$endif}
end.



