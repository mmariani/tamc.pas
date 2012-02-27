unit types;

interface
	type
		coord_t = 1..8;				(* coordinata (x o y)	*)
		xycell_t = record			(* casella				*)
			x,y: coord_t;
		end;
		move_t = record				(* mossa (da..a)		*)
			fm,tu: xycell_t;
		end;
		levnum_t = 1..12;			(* semilivelli *)

		color_t = ( BIANCO, NERO, VUOTO );	(* colore caselle	*)
		side_t = BIANCO..NERO;				(* colore pezzi		*)

		shape_t =					(* pezzo astratto	*)
			( NONE, PAWN, KNIGHT, BISHOP, TOWER, QUEEN, KING );

		square_t = record			(* pezzo concreto	*)
			shape: shape_t;
			color: color_t;
			moved: boolean;		(* TRUE se ha gia' mosso *)
		end;

		specialmove_t = ( USUAL, CASTLE, PROMOTE, ENPASSANT );


implementation

end.



