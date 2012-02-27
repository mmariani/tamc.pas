unit misc;

interface
	uses types;

	type bottomline_t =
		( EMPTY, CONFIG, LEVHELP, SOURCE, DEST, CYBER, ENDGAME );

	procedure WriteCoord(c:xycell_t);
	procedure BottomLine(bot:bottomline_t);
	procedure Buzz;
	function AskChar(query,answer:string): byte;
	procedure SetPercent(max:integer);
	procedure TellPercent;


implementation
	uses CRT, screen;
	var maxpercent: integer;
		curpercent: integer;



(*
**	SetPercent - inizializza il valore massimo che potra' raggiungere
**				 la barra orizzontale, pari al numero delle mosse
**				 da valutare al primo livello.
*)
procedure SetPercent(max:integer);
var i:integer;
begin
	maxpercent := max;
	curpercent := 0;
	UseWindow(WLEGAL);
	TextColor(Cyan);
	ClrScr;
	for i := 1 to 41 do write('°');
end;



(*
**	TellPercent - mostra la barra orizzontale e ne incrementa il valore.
*)
procedure TellPercent;
var i:integer;
begin
	UseWindow(WLEGAL);
	GotoXY(1,1);
	TextColor(Cyan);
	for i := 1 to (41*curpercent) DIV maxpercent do
		write('²');
	inc(curpercent);
end;



(*
**	WriteCoord - scrive le coordinate della casella.
*)
procedure WriteCoord(c:xycell_t);
begin
	write(Copy('abcdefgh',c.x,1),c.y);
end;



(*
**	BottomLine - aggiorna la linea in fondo allo schermo.
*)
procedure BottomLine(bot:bottomline_t);
const
	c1: byte = Cyan;
	c2: byte = LightCyan;
begin
	UseWindow(WFULL);
	GotoXY(3,25);
	DelLine;
	TextColor(c1);
	case bot of
		CONFIG: begin
					TextColor(c2);	write('h');
					TextColor(c1);	write(' = aiuto');
				end;
		LEVHELP: begin
					TextColor(c2);	write('any');
					TextColor(c1);	write(': senza prese, ');
					TextColor(c2);	write('take');
					TextColor(c1);	write(': con prese, ');
					TextColor(c2);	write('moves');
					TextColor(c1);	write(': con mobilita''');
				end;
		SOURCE: begin
					write('Casella di partenza, ');
					TextColor(c2);	write('?');
					TextColor(c1);	write(' = suggerimento, ');
					TextColor(c2);	write('!');
					TextColor(c1);	write(' = cambia opzioni');
				end;
		DEST: write('Casella di arrivo (pezzo toccato, pezzo mosso)');
		CYBER: write('Premi un tasto per bloccare');
		ENDGAME: write('Fine del gioco. Escape per uscire.');
	end;
end;



(*
**	Buzz - emette una pernacchia.
*)
procedure Buzz;
begin
	Sound(100);
	Delay(100);
	NoSound;
end;



(*
**	AskChar - riceve input dall'utente.
**
**	La stringa 'query' contiene la domanda, 'answer' contiene
**	l'insieme dei caratteri validi come risposta.
*)
function AskChar(query,answer:string): byte;
var p:byte;
begin
	TextColor(Green);
	write(query);
	repeat
		p := Pos(ReadKey,answer);
		if p=0 then Buzz;
	until p>0;
	TextColor(White);
	write(Copy(answer,p,1));
	AskChar := p;
end;

end.



