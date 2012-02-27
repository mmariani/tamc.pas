unit screen;

interface
	type win_t = (	WFULL,		(* schermo intero *)
					WBOARD,		(* bordo della scacchiera *)
					WVALUE,		(* valore della situazione *)
					WLEGAL,		(* mosse legali e scacchiere valutate *)
					WSTATU,		(* stato del gioco *)
					WCAPTU,		(* pezzi catturati *)
{$ifdef DEBUG}		WDEBUG,		(* thinking *)			{$endif}
					WHISTO,		(* partita *)
					WINPUT,		(* ingresso mosse *)
					WLEVEL		(* livello corrente *)
				);

	procedure SaveXY;
	procedure LoadXY;
	procedure UseWindow(w:win_t);
	procedure DrawWindow(w:win_t; c:byte);
	procedure SetWin(w:win_t; xx1,yy1,xx2,yy2:byte; t:string);


implementation
	uses CRT;
	var	curwin: win_t;
		WIN: array[win_t] of record
			x1,x2,y1,y2,xcur,ycur: byte;
			title: string;
		end;



(*
**	SaveXY - salva la posizione del cursore.
*)
procedure SaveXY;
begin
	with WIN[curwin] do begin
		xcur := WhereX;
		ycur := WhereY;
	end;
end;



(*
**	LoadXY - ripristina la posizione del cursore.
*)
procedure LoadXY;
begin
	with WIN[curwin] do
		GotoXY(xcur,ycur);
end;



(*
**	UseWindow - cambia finestra.
*)
procedure UseWindow(w:win_t);
begin
	SaveXY;
	with WIN[w] do
		Window(x1+1,y1+1,x2-1,y2-1);
	curwin := w;
	LoadXY;
end;



(*
**	SetWin - riempie le dimensioni e la posizione della finestra
**			 all'interno del relativo record.
*)
procedure SetWin(w:win_t; xx1,yy1,xx2,yy2:byte; t:string);
begin
	with WIN[w] do begin
		x1:=xx1; y1:=yy1;
		x2:=xx2; y2:=yy2;
		title:=t;
	end;
end;



(*
**	DrawWindow - disegna il bordo e scrive il titolo.
*)
procedure DrawWindow(w:win_t; c:byte);
var x,y:byte;
begin
	with WIN[w] do begin
		UseWindow(WFULL);
		TextColor(c);
		for x := x1 to x2 do begin
			GotoXY(x,y1); write('Ä');
			GotoXY(x,y2); write('Ä');
		end;
		for y := y1 to y2 do begin
			GotoXY(x1,y); write('³');
			GotoXY(x2,y); write('³');
		end;
		GotoXY(x1,y1); write('Ú');
		GotoXY(x1,y2); write('À');
		GotoXY(x2,y1); write('¿');
		GotoXY(x2,y2); write('Ù');
		GotoXY(x1+1,y1);
		TextColor(LightGray);
		if title <> '' then writeln(' ',title,' ');
	end;
end;



begin	(* inizializza *)
	SetWin(WFULL,0,0,81,26,'');
	SetWin(WBOARD,1,2,26,11,'');
	SetWin(WVALUE,30,1,37,4,'Val');
	SetWin(WLEGAL,38,1,80,4,'Legali');
	SetWin(WSTATU,30,5,45,8,'Stato');

{$ifdef DEBUG}
	SetWin(WDEBUG,56,9,80,16,'Thinking');
	SetWin(WHISTO,56,17,80,24,'Partita');
{$else}
	SetWin(WHISTO,56,9,80,24,'Partita');
{$endif}

	SetWin(WCAPTU,46,5,80,8,'Catturati');
	SetWin(WINPUT,1,12,54,24,'');
	SetWin(WLEVEL,30,9,54,11,'Livello');

	curwin := WFULL;
	UseWindow(WFULL);
	TextColor(White);
	TextBackground(Black);
	ClrScr;
end.



