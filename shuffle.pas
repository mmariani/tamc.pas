unit shuffle;

interface
	uses types;
	var RANDXY: array[coord_t,coord_t] of xycell_t;

	procedure ShuffleXY;



implementation
	var randvec: array[1..64] of xycell_t;



(*
**	ShuffleXY - rimescola le caselle.
*)
procedure ShuffleXY;
var tmp: xycell_t;
var r,r1,r2: integer;
begin
	for r := 1 to 1000 do begin
		r1 := Random(63) + 1;
		r2 := Random(63) + 1;
		tmp := randvec[r1];
		randvec[r1] := randvec[r2];
		randvec[r2] := tmp;
	end;

	tmp := randvec[1];
	for r := 2 to 64 do begin
		RANDXY[tmp.x,tmp.y] := randvec[r];
		tmp := randvec[r];
	end;
	RANDXY[tmp.x,tmp.y] := randvec[1];
end;


var r:integer;
begin	(* inizializza *)
	for r := 1 to 64 do begin
		randvec[r].x := ((r-1) DIV 8) + 1;
		randvec[r].y := (r MOD 8) + 1;
	end;
	Randomize;
	ShuffleXY;
end.



