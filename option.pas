unit option;

interface
	uses types, CRT, screen, misc;

	var options: record			(* opzioni del menu iniziale *)

		humans: integer;		(* numero degli umani *)
		human_side: side_t;		(* colore del lato in basso *)
		lev: record
			any: levnum_t;		(* livello massimo senza prese *)
			take: levnum_t;		(* livello massimo in caso di prese
									dev'essere >= any *)
			moves: levnum_t;	(* livello massimo per la mobilita'
									dev'essere >= any e <= take *)
		end;

{$ifdef DEBUG}
		debug_level: integer;
{$endif}

	end;


	procedure GetOptions;


implementation



(*
**	GetOptions - modifica le opzioni di gioco.
*)
procedure GetOptions;
var i: integer;
begin
	with options do begin
		BottomLine(CONFIG);
		UseWindow(WINPUT);
		writeln;

		repeat
			humans :=
				AskChar(' Quanti giocatori umani [0..2,h] ? ','012h') - 1;
			writeln;
			if humans = 3 then begin
				writeln;
				writeln('    Film preferito:');
				writeln;
				writeln('    0 - Terminator 2');
				writeln('    1 - Blade Runner');
				writeln('    2 - Highlander');
				writeln;
			end;
		until humans < 3;

		repeat
			i := AskChar(' Livello di gioco [0..3,h] ? ','0123h') - 1;
			writeln;
			with lev do case i of
				0:	begin any:=2; moves:=3; take:=4; end;
				1:	begin any:=2; moves:=3; take:=6; end;
				2:	begin any:=2; moves:=5; take:=8; end;
				3:	begin any:=4; moves:=5; take:=8; end;
				4:	begin
						writeln;
						writeln('    semimosse:           any ³ moves ³ take');
						writeln('                        ÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄ');
						writeln('    0 - banale            2  ³   3   ³  4  ');
						writeln('    1 - facilissimo       2  ³   3   ³  6  ');
						writeln('    2 - molto facile      2  ³   5   ³  8  ');
						writeln('    3 - molto lento       4  ³   5   ³  8  ');
						writeln;
						BottomLine(LEVHELP);
						UseWindow(WINPUT);
					end;
			end;
		until i < 4;

{$ifdef DEBUG}
		repeat
			debug_level :=
				AskChar(' Livello di debug [0..2,h] ? ','012h') - 1;
			writeln;
			if debug_level = 3 then begin
				writeln('    0 - solo il numero delle scacchiere');
				writeln('    1 - elenco delle mosse valutate');
				writeln('    2 - mostra la scacchiera mentre valuta');
				writeln;
			end;
		until debug_level < 3;
{$endif}

		BottomLine(EMPTY);
		UseWindow(WINPUT);

		if AskChar(' Colore in basso [b,n] ? ','bn') = 1
			then human_side := BIANCO
			else human_side := NERO;
		writeln;
		writeln;
	end;
end;

end.



