program TAMC;

(*
**		IMPORTANTE	(le indicazioni valgono sotto Turbo Pascal 6.0)
**
**		Per compilare, abilitare 'Options/Compiler/Extended Syntax'
**
**		In 'Options/Compiler/Conditional defines' si possono
**		abilitare i seguenti simboli:
**
**		DEBUG	-	per la finestra di Thinking.
**		AMAZON	-	per aggiungere alla regina le mosse del cavallo
**					(disabilita il libro di aperture).
**
**		Il sorgente e' stato scritto con
**		'Options/Environment/Editor/Tab size' = 4
*)

(*
**	0.0 (24-6-94):	permette di giocare a due esseri umani, controlla
**					solo la legalita' della casella di partenza.
**	0.1 (25-6-94):	valuta il valore dei pezzi, genera le mosse di
**					tutti i pezzi (con le prese), scrive le mosse
**					legali, controlla la casella di arrivo.
**	0.15 (26-6-94):	elenca i pezzi catturati, migliorata la gestione
**					delle finestre e il layout, scandisce la scacchiera.
**	0.20 (30-6-94): calcola la mossa ma l'alfabeta e' sbagliato,
**					c'e' la finestra di debug.
**	0.21 (1-7-94):	l'alfabeta e' giusto, per ora considera solo il valore.
**	0.30 (2-7-94):	scrive le ultime mosse (finestra history), ci sono
**					piu' livelli di debug, comunica lo scacco, aggiunto
**					il limite massimo alle scacchiere valutate, gioca
**					anche nella parte del bianco, valuta la mobilita'.
**	0.31 (3-7-94):	corretta la mobilita' (l'apertura e' dignitosa), piu'
**					veloce la valutazione, differenziati lev_any, take
**					e moves, non si fa piu' fregare tanto facilmente.
**	0.32 (5-7-94):	scandisce la scacchiera in modo random, corretto un
**					bug nel generatore delle mosse.
**	0.33 (6-7-94):	separate le unit SCREEN.TPU, MISC.TPU, aggiunti
**					i menu a barre.
**	0.40 (7-7-94):	aggiunta la barra di percentuale, separati TYPES.TPU,
**					OPTION.TPU e SHUFFLE.TPU, si possono cambiare le
**					opzioni durante l' esecuzione, tolti i menu a barre,
**					aggiunto l'arrocco, creata la unit BOOK.TPU e il file
**					OPENINGS.TMC (con la King's Indian Defence).
**	0.41 (8-7-94):	corretta la rappresentazione dal p.d.v. del nero,
**					aggiunta una pagina di Difesa Siciliana.
**	0.50 (9-7-94):	sono illegali le mosse che mettono sotto scacco,
**					aggiunta la globale 'attack', riconosce il matto
**					e lo stallo, commentato pesantemente TAMC.PAS.
**	0.55 (10-7-94):	semplificato il sistema di "tracciamento" dei
**					pezzi non ancora mossi, corretta la previsione
**					dell'arrocco (ora prevede anche il movimento
**					della torre), aggiunta la promozione.
**	0.56 (12-7-94):	corretto un insidiosissimo bug in UnderAttack
**					che in situazioni come 1. e3 e6 2. f4 Dh4+ non
**					permetteva 3. g3, aggiunta la presa en-passant,
**					e la difesa Nimzowitsch.
**	0.57 (14-7-94): corretto un bug nell'uso di ScanBoard che non
**					valutava il pezzo in a1, aggiunta la lettura
**					casuale del libro e l'amazzone.
**	0.60 (17-7-94):	aggiunto GNUCHESS.BOO, gioca anche senza libro.
*)


uses
	types,			(* tipi per i record, enumerazioni, etc.	*)
	CRT,			(* gestione del cursore e dei colori		*)
	screen,			(* gestione delle finestre					*)
	option,			(* legge le opzioni dall'utente				*)
	shuffle,		(* mescola le caselle della scacchiera		*)
	book,			(* gestisce le aperture						*)
	misc;			(* varie ed eventuali						*)


const
	OTHERSIDE: array[color_t] of color_t = ( NERO, BIANCO, VUOTO );
	COLOR_PIECE: array[color_t] of byte = (White,Red,0);
							(* il rosso e' per ragioni storiche,
								usare DarkGray per il nero *)

	COLOR_SQUARE: array[side_t] of byte = (LightGray,Black);
	COLOR_NAME: array[side_t] of string = ('Bianco','Rosso');
	PIECE_VALUE_SCALE: integer = 2;
		(* valuta l'importanza della mobilita' rispetto ai pezzi.
			Un valore di N significa che un pedone vale N*10 mosse *)

	PIECE_VALUE: array[shape_t] of integer = (0,10,30,32,50,
					{$ifdef AMAZON} 150 {$else} 90 {$endif} ,1000);

	PIECE_PRINT: array[shape_t] of char =
(*		(' ','p','N','B','T','Q','K' );			inglese		*)
		(' ','p','C','A','T','D','R' );		(*	italiano	*)

	INVALID: integer = maxint;		(* valore 'vergine' nel vettore *)

	BOARDSTEP: integer = 50;	(* ogni quante scacchiere valutate
									viene scritto il loro numero? *)

	MAXBOARDNUM: longint = 1000000;	(* limite estremo, usato per impedire
										che l'utente invecchi alla tastiera,
										ma non e' un ottimo sistema per
										rendere il programma piu' veloce *)

	PAWN_LINE: array[side_t] of byte = (2,7);	(* linea di partenza *)


var
	board: array[coord_t,coord_t] of square_t;	(* la scacchiera		*)

	tree: array[levnum_t] of record
		src: xycell_t;						(* sorgente					*)
		dstmax: 0..35;						(* ultima destinazione + 1	*)
		dst: array[0..34] of xycell_t;		(* destinazioni legali		*)
		move: xycell_t;						(* mossa in valutazione		*)
		tmp: square_t;						(* pezzo in presa			*)
		val: integer;						(* valore del livello		*)
		firstmove: boolean;					(* TRUE se il pezzo in src
												e' alla sua prima mossa	*)
		special: specialmove_t;				(* arrocco etc.				*)
		enpass: byte;						(* se la prossima mossa puo'
												essere en-passant, allora
												vale x, altrimenti zero	*)
	end;

	glob: record			(* variabili globali 'raccolte' dall'albero	*)
		val: integer;					(* il valore della scacchiera	*)
		enpass: byte;					(* enpass della mossa precedente *)
	end;

	captured: array[side_t] of string;	(* pezzi catturati *)
	side_to_move: side_t;				(* lato a cui spetta la mossa *)
	boardnum: longint;					(* scacchiere valutate *)

	movenumber: integer;
	moves_to_draw: integer;				(* mosse che mancano alla patta *)
	movetodo: move_t;

	kings: array[side_t] of xycell_t;	(* posizione corrente dei re *)


function UnderAttack(side:side_t; xx,yy:coord_t): boolean;
forward;



(*
**	DrawSquare - disegna una casella sulla scacchiera.
**
**	x,y: coordinate
**	bli: TRUE se deve lampeggiare
*)
procedure DrawSquare(x,y:coord_t; bli:boolean);
var fg,bg: byte;
begin
	UseWindow(WFULL);

	if odd(x) = odd(y)
		then bg := COLOR_SQUARE[NERO]
		else bg := COLOR_SQUARE[BIANCO];

	fg := COLOR_PIECE[board[x,y].color];
	if bli then inc(fg,Blink);

	if options.human_side = BIANCO	then GotoXY(x*3-1,11-y)
									else GotoXY(26-x*3,y+2);
	TextColor(fg);
	TextBackground(bg);

	write(' ',PIECE_PRINT[board[x,y].shape],' ');
	TextBackground(Black);
end;



(*
**	DrawBoard - disegna la scacchiera completa.
*)
procedure DrawBoard;
var xy: xycell_t;
var i: integer;
begin
	xy.x := 1; xy.y := 1;

	with xy do repeat
		xy := RANDXY[x,y];			(* le caselle compaiono	*)
		DrawSquare(x,y,false);		(* in ordine casuale	*)
	until (x=1) and (y=1);

	TextColor(Cyan);
	for i := 1 to 8 do begin
		GotoXY(28,i+2);
		if options.human_side = BIANCO	then write(9-i)
										else write(i);
	end;
	GotoXY(3,1);
	if options.human_side = BIANCO	then write('A  B  C  D  E  F  G  H')
									else write('H  G  F  E  D  C  B  A');
end;



(*
**	InitBoard - produce la scacchiera iniziale.
**
**		clearlines - pulisce e 'colora' alcune colonne
**		pawnline - sistema i pedoni
**		vipline - sistema i pezzi grossi
*)
procedure InitBoard;

	procedure clearlines(y1,y2:coord_t; col:color_t);
	var x: coord_t;
	begin
		for y1 := y1 to y2 do
			for x := 1 to 8 do begin
				board[x,y1].color := col;
				board[x,y1].shape := NONE;
				board[x,y1].moved := false;
			end;
	end;

	procedure pawnline(y:coord_t; side:side_t);		(* pedoni *)
	var x: coord_t;
	begin
		clearlines(y,y,side);
		for x := 1 to 8 do board[x,y].shape := PAWN;
	end;

	procedure vipline(y:coord_t; side:side_t);	(* very important pieces *)
	begin
	clearlines(y,y,side);
		board[1,y].shape := TOWER;
		board[2,y].shape := KNIGHT;
		board[3,y].shape := BISHOP;
		board[4,y].shape := QUEEN;
		board[5,y].shape := KING;
		board[6,y].shape := BISHOP;
		board[7,y].shape := KNIGHT;
		board[8,y].shape := TOWER;
		kings[side].x := 5;
		kings[side].y := y;
	end;

begin	(* InitBoard *)
	clearlines(1,8,VUOTO);

	vipline(1,BIANCO);
	pawnline(2,BIANCO);
	pawnline(7,NERO);
	vipline(8,NERO);
end;



(*
**	SquareValue - ritorna il valore del pezzo in una casella.
**
**	positivo: appartiene al bianco
**	negativo: appartiene al nero
**	zero: casella vuota
*)
function SquareValue(x,y:coord_t): integer;
begin
	with board[x,y] do
	if color = BIANCO
		then SquareValue := PIECE_VALUE[shape]
		else SquareValue := -PIECE_VALUE[shape];
end;



(*
**	ScanBoard - scandisce la scacchiera alla ricerca del prossimo pezzo
**				il cui colore sia 'side'.
**
**	riempie tree[lev].src con le coordinate del primo pezzo se 'first'
**	vale TRUE, altrimenti vi mette le coordinate del pezzo successivo.
**	Ritorna TRUE finche' ci sono altri pezzi, ritorna FALSE ad ogni
**	scansione successiva.
*)
function ScanBoard(lev:levnum_t; side:side_t; first:boolean): boolean;
var xy,tmp: xycell_t;
var break: boolean;
begin
	break := false;

	if first then begin xy.x:=1; xy.y:=1; end
		else xy := tree[lev].src;

	repeat
		xy := RANDXY[xy.x,xy.y];			(* vedere SHUFFLE.TPU *)
		if board[xy.x,xy.y].color = side then begin
			tree[lev].src := xy;
			break := true;
		end;
	until break or ((xy.x=1) and (xy.y=1));
	if (xy.x=1) and (xy.y=1) then break := false;
	ScanBoard := break;
end;



(*
**	HistoryInit - prepara la finestra in cui scrivere le mosse.
*)
procedure HistoryInit;
begin
	DrawWindow(WHISTO,DarkGray);
	UseWindow(WHISTO);
	TextColor(Cyan);
	ClrScr;
	GotoXY(6,1);
	write('³ ',COLOR_NAME[BIANCO]);
	GotoXY(15,1);
	writeln('³ ',COLOR_NAME[NERO]);
	write(' ÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄ');
	movenumber := 0;
end;



(*
**	HistoryPrint - scrive l'ultima mossa.
*)
procedure HistoryPrint(side:color_t);
var y:byte;
	ch:char;
	print: boolean;
begin
	UseWindow(WHISTO);
	TextColor(White);
	print := true;
	with tree[1] do begin
		case side of
			VUOTO: begin
				y := WhereY - 1;
				if movenumber > (Hi(WindMax)-Hi(WindMin)) - 2
					then begin
						GotoXY(1,3);
						DelLine;
						GotoXY(1,y);
					end;
				inc(movenumber);
				writeln;
				TextColor(Cyan);
				write('  ',movenumber);
				GotoXY(6,WhereY);
				write('³        ³');
				print := false;
			end;
			BIANCO: GotoXY(8,WhereY);
			NERO: GotoXY(17,WhereY);
		end;

	if print then begin
			WriteCoord(src);
			TextColor(Green);
			if tmp.shape <> NONE then write('x') else write('-');
				(* funziona anche nel caso di presa en-passant *)
			TextColor(White);
			WriteCoord(move);
		end;
	end;
end;


{$ifdef DEBUG}
(*
**	DebugInit - prepara la finestra in cui tracciare le mosse previste.
*)
procedure DebugInit;
var i: integer;
begin
	DrawWindow(WDEBUG,DarkGray);
	UseWindow(WDEBUG);
	TextColor(Cyan);
	ClrScr;
	writeln(' liv ³ mossa   valore');
	write(' ÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
	for i := 1 to 4 do begin
		writeln;
		write('  ',i,'  ³');
	end;
end;



(*
**	Debug - scrive cio' che sta pensando fino al quarto livello.
*)
procedure Debug(lev:levnum_t);
begin
	if lev <= 4 then with tree[lev] do begin
		UseWindow(WDEBUG);
		TextColor(White);
		GotoXY(8,lev+2);
		WriteCoord(src);
		write('-');
		WriteCoord(move);
		write('   ',glob.val);
	end;
end;



(*
**	UnDebug - cancella la riga del livello attuale.
*)
procedure UnDebug(lev:levnum_t);
begin
	if lev <= 4 then begin
		UseWindow(WDEBUG);
		GotoXY(7,lev+2);
		write('              ');
	end;
end;
{$endif}



(*
**	CheckCheck - ritorna TRUE se il colore 'side' e' sotto scacco.
*)
function CheckCheck(side:side_t): boolean;
begin
	with kings[side] do
		CheckCheck := UnderAttack(OTHERSIDE[side],x,y);
end;



(*
**	DoBoard - esegue la mossa in tree[lev].src -> tree[lev].move
**				ed eventualmente modifica il valore 'globval'.
*)
procedure DoBoard(lev:levnum_t);
begin
	with tree[lev] do begin
		special := USUAL;
		tmp := board[move.x,move.y];

		with board[src.x,src.y] do begin
			if shape = KING then begin
				if abs(src.x-move.x) = 2 then begin		(* arrocco *)
					case move.x of
						3:	begin
								board[4,src.y] := board[1,src.y];
								board[1,src.y].color := VUOTO;
								board[1,src.y].shape := NONE;
							end;
						7:	begin
								board[6,src.y] := board[8,src.y];
								board[8,src.y].color := VUOTO;
								board[8,src.y].shape := NONE;
							end;	(* 7 *)
					end;	(* case move.x *)
					special := CASTLE;
				end;	(* if abs *)
				kings[color] := move;
			end	(* if shape = KING *)
			else if (shape = PAWN) then begin
				enpass := 0;

				if ((color=BIANCO) and (move.y=8) or
						(color=NERO) and (move.y=1))
					then begin
							special := PROMOTE;
							dec(glob.val,SquareValue(src.x,src.y));
							shape := QUEEN;
							inc(glob.val,SquareValue(src.x,src.y));
						end

			(* "The Eight Square at last!" she cried as she bounded
				across, and threw herself down to rest on a lawn as soft
				as moss, with little flower-beds dotted about it here
				and there. "Oh, how glad I am to get here! And what is
				this on my head?" she exclaimed in a tone of dismay,
				as she put her hands up to something very heavy, that
				fitted tight all around her head. *)

					else if abs(src.y-move.y) = 2
						then enpass := src.x

					else if (src.x<>move.x) and (tmp.shape = NONE)
						then begin
							special := ENPASSANT;
							tmp := board[move.x,src.y];
							board[move.x,src.y].shape := NONE;
							board[move.x,src.y].color := VUOTO;
						end;
			end;
		end;

		dec(glob.val,SquareValue(move.x,move.y));
		firstmove := board[src.x,src.y].moved;
		board[move.x,move.y].shape := board[src.x,src.y].shape;
		board[move.x,move.y].color := board[src.x,src.y].color;
		board[move.x,move.y].moved := TRUE;
		board[src.x,src.y].shape := NONE;
		board[src.x,src.y].color := VUOTO;
	end;
end;



(*
**	UndoBoard - corregge l'operazione di DoBoard.
*)
procedure UndoBoard(lev:levnum_t);
begin
	with tree[lev] do begin

		with board[move.x,move.y] do begin
			if shape = KING then begin
				if special = CASTLE then begin		(* arrocco *)
					case move.x of
						3:	begin
								board[1,src.y] := board[4,src.y];
								board[4,src.y].color := VUOTO;
								board[4,src.y].shape := NONE;
							end;
						7:	begin
								board[8,src.y] := board[6,src.y];
								board[6,src.y].color := VUOTO;
								board[6,src.y].shape := NONE;
							end;	(* 7 *)
					end;	(* case move.x *)
				end;	(* if abs *)
				kings[color] := src;
			end	(* if shape *)
			else if special = PROMOTE
				then begin
						dec(glob.val,SquareValue(move.x,move.y));
						shape := PAWN;
						inc(glob.val,SquareValue(move.x,move.y));
				end
			else if special = ENPASSANT
				then begin
					board[move.x,src.y] := tmp;
					tmp.shape := NONE;
					tmp.color := VUOTO;
				end;
		end;

		board[src.x,src.y].moved := firstmove;
		board[src.x,src.y].shape := board[move.x,move.y].shape;
		board[src.x,src.y].color := board[move.x,move.y].color;
		board[move.x,move.y] := tmp;
		inc(glob.val,SquareValue(move.x,move.y));
		enpass := 0;
	end;
end;



(*
**	MakeMoves - genera le mosse legali per un determinato pezzo.
**
**		MakePawn - genera le mosse del pedone
**		MakeKnight -   "    "    "     cavallo
**		MakeBishop -   "    "    "     alfiere
**		MakeTower -    "    "    "     torre
**		MakeKing -     "    "    "     Re
*)
procedure MakeMoves(lev:levnum_t; chk:boolean);
var x,y: coord_t;			(* casella di partenza *)
var mvn: 0..35;				(* cursore della mossa nel vettore dst *)
var side: side_t;			(* lato a cui appartiene il pezzo *)

	(*
	**	SquareFriend - esamina il pezzo in 'x,y' rispetto a 'side'
	**					ritornando il valore:
	**
	**	-1: se appartiene al nemico
	**	0:	se e' vuota
	**	+1:	se e' fuori dalla scacchiera o appartiene a 'side'
	*)
	function SquareFriend(x,y:integer): integer;
	begin
		SquareFriend := 1;
		if (x<9) and (x>0) and (y<9) and (y>0) then
			with board[x,y] do
			if color = VUOTO
				then SquareFriend := 0
				else if color <> side
					then SquareFriend := -1;
	end;

	(*
	**	try - considera la mossa src.x,src.y -> xx,yy
	**			Se xx,yy appartiene alla scacchiera, non vi e' sopra un
	**			proprio pezzo, e non mette il proprio Re sotto scacco,
	**			allora scrive tale destinazione tra quelle legali.
	**			Il valore ritornato e' quello ricevuto da SquareFriend.
	*)
	function try(xx,yy:integer): integer;		(* -1..1 *)
	var t: integer;
	begin
		t := SquareFriend(xx,yy);
		if t < 1 then
		with tree[lev] do begin
			dst[mvn].x := xx;
			dst[mvn].y := yy;
			inc(mvn);
			if chk then begin	(* il controllo richiede tempo.. *)
				move.x := xx;
				move.y := yy;
				DoBoard(lev);			(* se faccio questa mossa.. *)
				if CheckCheck(side)		(* vado in scacco? *)
					then dec(mvn);		(* in tal caso, non e' valida *)
				UndoBoard(lev);
			end;
		end;
		try := t;
	end;

	procedure MakePawn;
	var st: -1..1;				(* passo (in avanti o indietro) *)
	var enp: byte;
	begin
		if side = BIANCO then st := 1 else st := -1;

		if SquareFriend(x,y+st) = 0 then begin
			if (y = PAWN_LINE[side])
				and (SquareFriend(x,y+2*st)=0)
					then try(x,y+2*st);				(* due caselle *)
			try(x,y+st);							(* una casella *)
		end;
		if SquareFriend(x+1,y+st) = -1 then
			try(x+1,y+st);							(* cattura dx *)
		if SquareFriend(x-1,y+st) = -1 then
			try(x-1,y+st);							(* cattura sx *)

		if lev > 1 then enp := tree[lev-1].enpass
					else enp := glob.enpass;

		if (y = PAWN_LINE[side] + 3*st) and (glob.enpass<>0)
			then if abs(x-glob.enpass)=1				(* en passant *)
				then try(glob.enpass,y+st);
	end;

	procedure MakeKnight;
	begin
		try(x+2,y+1);
		try(x+2,y-1);
		try(x-2,y+1);
		try(x-2,y-1);
		try(x+1,y-2);
		try(x+1,y+2);
		try(x-1,y-2);
		try(x-1,y+2);
	end;

	procedure MakeBishop;
	var i: integer;
	begin
		i:=0; repeat inc(i) until try(x+i,y+i) <> 0;
		i:=0; repeat inc(i) until try(x+i,y-i) <> 0;
		i:=0; repeat inc(i) until try(x-i,y+i) <> 0;
		i:=0; repeat inc(i) until try(x-i,y-i) <> 0;
	end;

	procedure MakeTower;
	var i: integer;
	begin
		i:=0; repeat inc(i) until try(x  ,y+i) <> 0;
		i:=0; repeat inc(i) until try(x  ,y-i) <> 0;
		i:=0; repeat inc(i) until try(x+i,y  ) <> 0;
		i:=0; repeat inc(i) until try(x-i,y  ) <> 0;
	end;

	procedure MakeKing;
	var other: side_t;
	begin
		if not board[x,y].moved then begin			(* arrocco *)
			other := OTHERSIDE[side];

			with board[1,y] do
				if	(shape = TOWER) and not moved and
					(board[4,y].color = VUOTO) and
					(board[3,y].color = VUOTO) and
					(board[2,y].color = VUOTO) and
					not UnderAttack(other,5,y) and
					not UnderAttack(other,4,y) and
					not UnderAttack(other,3,y) and
					not UnderAttack(other,2,y) and
					not UnderAttack(other,1,y)
						then try(x-2,y);			(* lungo *)

			with board[8,y] do
				if	(shape = TOWER) and not moved and
					(board[6,y].color = VUOTO) and
					(board[7,y].color = VUOTO) and
					not UnderAttack(other,5,y) and
					not UnderAttack(other,6,y) and
					not UnderAttack(other,7,y) and
					not UnderAttack(other,8,y)
						then try(x+2,y);			(* corto *)
		end;

		try(x-1,y  );
		try(x-1,y+1);
		try(x  ,y+1);
		try(x+1,y+1);
		try(x+1,y  );
		try(x+1,y-1);
		try(x  ,y-1);
		try(x-1,y-1);
	end;

begin	(* MakeMoves *)
	mvn := 0;
	x := tree[lev].src.x;
	y := tree[lev].src.y;
	with board[x,y] do begin
		side := color;
		case shape of
			PAWN:	MakePawn;
			KNIGHT:	MakeKnight;
			BISHOP:	MakeBishop;
			TOWER:	MakeTower;
			QUEEN:	begin
					MakeTower;
					MakeBishop;
{$ifdef AMAZON}		MakeKnight;		{$endif}
					end;
			KING:	MakeKing;
		end;
	end;
	tree[lev].dstmax := mvn;
end;



var attack: boolean;	(* evita la ricorsione infinita *)

(*
**	UnderAttack - guarda se la casella xx,yy e' sotto attacco da
**					parte di 'side'. Usa il livello 12 per non
**					alterare la computazione attuale, e non deve
**					essere eseguito ricorsivamente.
*)
function UnderAttack(side:side_t; xx,yy:coord_t): boolean;
var sb: boolean;
var i: integer;
const lev : levnum_t = 12;
begin
	if not attack then with tree[lev] do begin
		sb := true;
		UnderAttack := false;
		attack := true;

		repeat
			sb := not ScanBoard(lev,side,sb);
			MakeMoves(lev,false);	(* false = non controlla lo scacco *)
				for i := 0 to dstmax-1 do with dst[i] do
					if (x=xx) and (y=yy) then UnderAttack := true;
		until sb;
		attack := false;
	end;
end;



(*
**	TellCheck - se il Re appartenente a 'side_to_move' e' minacciato,
**				lo comunica nella finestra WSTATU e ritorna TRUE.
**				Aggiorna il numero delle mosse che mancano alla patta.
*)
function TellCheck: boolean;
var tc: boolean;
begin
	UseWindow(WSTATU);
	ClrScr;

	tc := CheckCheck(side_to_move);

	if tc then begin
		TextColor(COLOR_PIECE[side_to_move]+Blink);
		writeln(' Scacco');
	end
	else begin
		TextColor(DarkGray);
		write(' ',moves_to_draw);
	end;
	TellCheck := tc;
end;



(*
**	MoveCount -	ritorna il numero delle mosse che il colore 'side'
**				puo' effettuare. Il primo parametro vale TRUE se
**				devono essere contate anche le mosse di Re e Regina.
**				Il secondo parametro vale TRUE se devono essere
**				escluse le mosse che lasciano il re sotto scacco.
**				In realta' questo secondo parametro dovrebbe essere
**				quasi sempre TRUE, ma nella valutazione della mobilita'
**				rallenterebbe molto se non in situazioni di effettivo
**				pericolo per il Re, che durante il gioco sono poche.
*)
function MoveCount(lev:levnum_t; quin:boolean; chk:boolean): integer;
var mc: integer;
var sb: boolean;
var side: side_t;
begin
	mc := 0;
	sb := true;
	if odd(lev)
		then side := side_to_move
		else side := OTHERSIDE[side_to_move];

	repeat
		sb := not ScanBoard(lev,side,sb);
		with tree[lev] do
			if quin or (board[src.x,src.y].shape < QUEEN) then begin
				MakeMoves(lev,chk);
				inc(mc,dstmax);
			end;
	until sb;

	MoveCount := mc;
end;



(*
**	TellLevel - indica il livello di gioco selezionato.
*)
procedure TellLevel;
const
	c1: byte = Green;
	c2: byte = White;
begin
	UseWindow(WLEVEL);
	ClrScr;
	with options.lev do begin
		TextColor(c1); write(' any '); TextColor(c2); write(any);
		TextColor(c1); write(', move '); TextColor(c2); write(moves);
		TextColor(c1); write(', take '); TextColor(c2); write(take);
	end;
end;



(*
**	TellValue - scrive il valore dei pezzi e il numero delle mosse
**				permesse all'attuale giocatore.
*)
function TellValue: integer;
var tv: integer;
begin
	UseWindow(WVALUE);
	TextColor(Yellow);
	ClrScr;
	write(' ');
	if (glob.val <> 0) then if (glob.val > 0) xor (side_to_move = NERO)
		then write('+')			(*	-1 < -0 < 0 < +0 < +1	*)
		else write('-');
	writeln(abs(glob.val) DIV 30);
	TextColor(COLOR_PIECE[side_to_move]);
	tv := MoveCount(1,true,true);
	write(' ',tv);
	TellValue := tv;
end;



(*
**	TellCaptured - stampa i pezzi catturati.
*)
procedure TellCaptured;
begin
	UseWindow(WCAPTU);
	GotoXY(1,1);
	TextColor(COLOR_PIECE[NERO]);
	writeln(captured[NERO]);
	TextColor(COLOR_PIECE[BIANCO]);
	write(captured[BIANCO]);
end;



(*
**	IsLegal - verifica che la destinazione introdotta dall'utente sia
**				tra quelle generate in precedenza.
*)
function IsLegal(lev:levnum_t; x,y:coord_t): boolean;
var mvn: 0..35;
var done: boolean;
begin
	mvn := 0;
	done := false;
	with tree[lev] do while (mvn<dstmax) and not done do begin
		done := (x=dst[mvn].x) and (y=dst[mvn].y);
		inc(mvn);
	end;
	IsLegal := done;
end;



(*
**	MakeTree - crea e valuta l'albero di gioco.
*)
procedure MakeTree(lev:levnum_t; side:side_t);
var break,				(* vale TRUE quando c'e' un taglio nell'albero *)
	ecsor: boolean;		(* indica se giocare come MIN o come MAX *)

	(*
	**	MinMax - valuta il livello attuale e quello sottostante,
	**			 operando se necessario il movimento del valore
	**			 dal basso verso l'alto.
	*)
	procedure MinMax;
	var up: boolean;
	begin
		up := false;

		with tree[lev+1] do begin					(* .val *)

			if val = INVALID
				then if lev <= options.lev.moves
					then if ecsor
						then val := glob.val + MoveCount(lev+1,false,false)
						else val := glob.val - MoveCount(lev+1,false,false)
					else val := glob.val;

			if tree[lev].val <> INVALID
				then if ecsor
						then up := (val < tree[lev].val)
						else up := (val > tree[lev].val)
				else up := true;

			if up then begin
				tree[lev].val := val;
				if lev = 1 then begin
					movetodo.fm := tree[1].src;
					movetodo.tu := tree[1].move;
				end;
			end;
			val := INVALID;
		end;
	end;


{$ifdef DEBUG}
	(*
	**	debugboard - visualizza la scacchiera valutata.
	**				 Inutile ma altamente spettacolare :-))
	*)
	procedure debugboard;
	begin
		with tree[lev] do begin
			DrawSquare(src.x,src.y,false);
			DrawSquare(move.x,move.y,false);
			GotoXY(1,1); Delay(80);
		end;
	end;
{$endif}


var i: integer;
var first, sb: boolean;
begin	(* MakeTree *)
	break := false;
	first := true;
	sb := true;

	ecsor := odd(lev) xor (side_to_move = BIANCO);

	while sb and not break do begin
		sb := ScanBoard(lev,side,first);
		first := false;
		MakeMoves(lev,false);	(* e' necessario che le mosse che
									mettono il re sotto scacco siano
									legali, altrimenti tratta il matto
									come una situazione di stallo *)

		i := 0;
		with tree[lev] do while (i<dstmax) and not break do begin
			move := dst[i];
			DoBoard(lev);

			break := (tmp.shape = KING);	(* inutile continuare *)

{$ifdef DEBUG}
			if options.debug_level > 0 then Debug(lev);
			if options.debug_level > 1 then debugboard;
{$endif}

			inc(boardnum);

			if boardnum MOD BOARDSTEP = 0 then begin
				UseWindow(WLEGAL);
				GotoXY(2,2);
				TextColor(White);
				write(boardnum);
			end;

			if lev = 1 then TellPercent;

			if not break and (lev < options.lev.take) then
				if (lev < options.lev.any) or (tmp.shape <> NONE)
					then MakeTree(lev+1,OTHERSIDE[side]);

			MinMax;
			UndoBoard(lev);
{$ifdef DEBUG}
			if options.debug_level > 1 then debugboard;
			if options.debug_level > 0 then UnDebug(lev);
{$endif}

			if (lev > 1) and (tree[lev-1].val <> INVALID)
				then if ecsor				(* alfabeta *)
					then break := break or (val <= tree[lev-1].val)
					else break := break or (val >= tree[lev-1].val);

			if (boardnum=MAXBOARDNUM) or KeyPressed then break := true;
			inc(i);
		end;
	end;
end;



(*
**	MakeThisMove - effettua la mossa in modo definitivo.
**
**	cyber vale TRUE se la mossa e' del computer (serve per la promozione).
*)
procedure MakeThisMove(cyber:boolean);
begin
	if board[tree[1].src.x,tree[1].src.y].shape = PAWN
		then moves_to_draw := 50;

	DoBoard(1);
	with tree[1] do begin
		with tmp do if shape <> NONE then
			captured[color] := captured[color] + ' ' + PIECE_PRINT[shape];

		case special of
			CASTLE:	DrawBoard;
			PROMOTE: with board[move.x,move.y] do begin
				dec(glob.val,SquareValue(move.x,move.y));
				if cyber then shape := QUEEN
					else begin
						writeln;
						case AskChar(' Cosa scegli: [A,C,T,D] ? ','actd') of
							1: shape := BISHOP;
							2: shape := KNIGHT;
							3: shape := TOWER;
							4: shape := QUEEN;
						end;	(* case askchar *)
					end;	(* else *)
				inc(glob.val,SquareValue(move.x,move.y));
				end;	(* PROMOTE *)
			ENPASSANT: DrawBoard;
		end;	(* case special *)

	glob.enpass := tree[1].enpass;

	DrawSquare(src.x,src.y,false);
	DrawSquare(move.x,move.y,false);
	end;
end;




(*
**	TellMove - comunica la mossa scelta.
**
**	Se 'buk' vale TRUE, scrive che l'ha presa dal libro, altrimenti
**	scrive il numero di posizioni valutate.
*)
procedure TellMove(buk:boolean);
begin
	UseWindow(WLEGAL);
	ClrScr;
	TextColor(Cyan);
	write(' mossa: ');
	with tree[1] do begin
		TextColor(White);
		WriteCoord(src);
		TextColor(Cyan);
		if board[move.x,move.y].color <> VUOTO
			then write('x') else write('-');
			(* non funziona nel caso di presa en-passant *)
		TextColor(White);
		WriteCoord(move);
	end;
	writeln;
	TextColor(Cyan);
	if buk then write(' (libro)')
		else write(' ',boardnum,' scacchiere valutate');
end;



(*
**	GuessMove - cerca la prossima mossa.
*)
procedure GuessMove;
var i: integer;
var c: char;
begin
	with tree[1] do if AreWeStillInsideTheBook			(* BOOK.TPU *)
		then begin
			FillWithNextMoveInTheBook(src,move);
			Delay(250);
			TellMove(true);
		end
		else begin
			boardnum := 0;
			for i := 1 to 10 do tree[i].val := INVALID;
			BottomLine(CYBER);							(* MISC.TPU *)
			SetPercent(MoveCount(1,true,false));		(* MISC.TPU *)
			MakeTree(1,side_to_move);
			src := movetodo.fm;
			move := movetodo.tu;
			TellMove(false);
			if KeyPressed then c := ReadKey;	(* vuota il buffer *)
	end;
	ShuffleXY;
end;



(*
**	CyberMove - valuta ed esegue una mossa.
*)
procedure CyberMove;
begin
	GuessMove;
	MakeThisMove(true);
end;



(*
**	GetMove - legge una mossa dall'utente.
**
**		goandblink - fa lampeggiare il pezzo sulla scacchiera se il
**					 proprio parametro e' TRUE, lo spegne altrimenti
**		goprintlegal - stampa la lista delle mosse legali
**		goclearlegal - pulisce la finestra delle mosse
*)
procedure GetMove;

	procedure goandblink(xy:xycell_t; bli:boolean);
	begin
		DrawSquare(xy.x,xy.y,bli);
		UseWindow(WINPUT);
	end;

	procedure goprintlegal;
	var i: integer;
	begin
		UseWindow(WLEGAL);
		TextColor(Yellow);
		ClrScr;
		with tree[1] do
			for i := 0 to dstmax-1 do begin
				GotoXY((i MOD 14)*3+1,(i DIV 14)+1);
				WriteCoord(dst[i]);
			end;
		UseWindow(WINPUT);
	end;

	procedure goclearlegal;
	begin
		UseWindow(WLEGAL);
		ClrScr;
		UseWindow(WINPUT);
	end;

var fm,tu: xycell_t;
	x: integer;
	legal: boolean;
begin	(* GetMove *)

	BottomLine(SOURCE);
	UseWindow(WINPUT);

	with movetodo do begin
	repeat	(* se il pezzo e' bloccato *)
		repeat	(* se il pezzo non e' del colore giusto *)
			GotoXY(1,WhereY);
		repeat	(* se x>8 *)
			DelLine;
			x := AskChar(' '+COLOR_NAME[side_to_move]+': ','abcdefgh?!');
			if x = 10 then begin
				GetOptions;		(* cambio opzioni *)
				TellLevel;		(* cambiato livello? *)
				DrawBoard;		(* cambiato lato? *)
				BottomLine(SOURCE);
				UseWindow(WINPUT)
			end
			else if x = 9 then begin
				GuessMove;		(* richiesta di un consiglio *)
				BottomLine(SOURCE);
				UseWindow(WINPUT);
				writeln;
			end;
		until x<9;

			fm.x := x;
			fm.y := AskChar('','12345678');
			legal := (board[fm.x,fm.y].color = side_to_move);
			if not legal then Buzz;
		until legal;

		tree[1].src := fm;
		MakeMoves(1,true);
		legal := (tree[1].dstmax > 0);		(* impedisce di selezionare *)
		if not legal then Buzz;				(* pezzi che non hanno mosse *)
	until legal;

	goandblink(fm,true);
	goprintlegal;
	BottomLine(DEST);
	UseWindow(WINPUT);
	SaveXY;

	repeat	(* se la destinazione non e' legale *)
		LoadXY;
		tu.x := AskChar('-','abcdefgh');
		tu.y := AskChar('','12345678');
		legal := IsLegal(1,tu.x,tu.y);
		if not legal then Buzz;
	until legal;

	tree[1].src := fm;
	tree[1].move := tu;
	MakeThisMove(false);

	goandblink(fm,false);
	writeln;
	goclearlegal;
	BottomLine(EMPTY);
	end;	(* with movetodo *)
end;



(*
**	PlayOn - gioca fino al matto o patta.
**
**	Ritorna TRUE in caso di matto.
*)
function PlayOn: boolean;
var gameover,
	chk: boolean;
begin
	gameover := false;

	with options do repeat

		if side_to_move = BIANCO
			then HistoryPrint(VUOTO);

		chk := TellCheck;

		if chk
			then moves_to_draw := 50
			else dec(moves_to_draw);

		if (TellValue = 0) or (moves_to_draw < 0)
			then gameover := true
			else begin
				case humans of
					0: CyberMove;
					1: if human_side = side_to_move
						then GetMove
						else CyberMove;
					2: GetMove;
				end;
				UpdateOpeningWithMove(tree[1].src,tree[1].move);
				TellCaptured;
				HistoryPrint(side_to_move);
			end;

		side_to_move := OTHERSIDE[side_to_move];
	until gameover;

	PlayOn := chk;
end;



(*
**	VarInit - inizializza alcune variabili, principalmente per evitare
**				l'out-of-range se tale controllo e' abilitato.
*)
procedure VarInit;
var i: integer;
var piece: shape_t;
begin
	with movetodo do begin fm.x:=1; fm.y:=1; tu:=fm; end;

	for i := 1 to 10 do with tree[i] do begin
		src.x := 1;
		src.y := 1;
		move := src;
		dstmax := 0;
		tmp.shape := NONE;
		val := INVALID;
		enpass := 0;
	end;

	for piece := NONE to KING do
		PIECE_VALUE[piece] := PIECE_VALUE[piece] * PIECE_VALUE_SCALE;
end;



var mate: boolean;
const
	c1: byte = Cyan;
	c2: byte = LightCyan;
begin	(* program TAMC *)
	VarInit;
	DrawWindow(WINPUT,Brown);
	UseWindow(WINPUT);
	ClrScr;

	TextColor(c2);	write(' T');
	TextColor(c1);	write('amc-');
	TextColor(c2);	write('A');
	TextColor(c1);	write('imed ');
	TextColor(c2);	write('M');
	TextColor(c1);	write('ariani''s ');
	TextColor(c2);	write('C');
	TextColor(c1);	write('hessplayer');
	writeln(' v0.60');
	writeln(' programma )C( copyleft 1994 Marco Mariani');
	writeln(' aperture (C) copyright 1988 F.S.F.');

	GetOptions;
	InitBoard;
	DrawWindow(WBOARD,Cyan);
	DrawBoard;

	DrawWindow(WVALUE,DarkGray);
	DrawWindow(WLEGAL,DarkGray);
	DrawWindow(WSTATU,DarkGray);
	DrawWindow(WCAPTU,DarkGray);
	DrawWindow(WLEVEL,DarkGray);
	TellLevel;

{$ifdef DEBUG}
	DebugInit;
{$endif}
	HistoryInit;

	attack := false;
	glob.val := 0;				(* presume la posizione simmetrica *)
	glob.enpass := 0;
	moves_to_draw := 50;		(* non ricordo bene la regola.. *)

	captured[BIANCO] := '';
	captured[NERO] := '';
	side_to_move := BIANCO;

	mate := PlayOn;
	UseWindow(WSTATU);
	TextColor(Yellow + Blink);
	writeln;

	if mate
		then begin
			writeln(' Matto');
			if side_to_move = BIANCO	then write(' 1 - 0')
										else write(' 0 - 1');
		end
	else if moves_to_draw < 0
		then begin
			writeln(' 50 mosse');
			write(' « - «');
		end
	else begin
		writeln(' Stallo');
		write(' « - «');
	end;
	FreeBook;
	UseWindow(WINPUT);
	BottomLine(ENDGAME);
    TextColor(White);
	repeat until KeyPressed and (Ord(ReadKey) = 27);
end.


(** That's all folks **)
