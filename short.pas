program short;

(*
**	Questo programma legge un file di aperture senza caratteri di
**	tabulazione e ne genera uno con le tabulazioni, riducendone cosi'
**	le dimensioni almeno del 50%.
**	I commenti non sono previsti, potrebbero creare problemi.
*)

uses CRT;


var last_line: string;
	howmany: integer;

function useful_part(var s:string): string;
var part: string;
	i: integer;
begin
	part := '';
	for i := 0 to (length(s) DIV 4) - 1 do begin
		if Copy(last_line,i*4+1,4) = Copy(s,i*4+1,4)
			then part := part + '	'
			else part := part + Copy(s,i*4+1,4);
	end;
	last_line := s;
	howmany := howmany + 1;
	if Copy(part,length(part),1) = '	' then part := part + '.';
	writeln(howmany);
	useful_part := part;
end;


var fin,fout: text;
	s: string;

begin
	last_line := '';
	howmany := 0;
	Assign(fout,'openings.tab');
	Assign(fin,'openings.tmc');
	Reset(fin);
	Rewrite(fout);
    while not eof(fin) do begin
		readln(fin,s);
		writeln(fout,useful_part(s));
    end;

	Close(fout);
	Close(fin);
end.
