open Checker
open Compiler
open In_channel
open Alphaconv

let typeCheck e = infer e Lin []

(* let print_position outx lexbuf =
    let pos = lexbuf.lex_curr_p in
    fprintf outx "%s:%d:%d" pos.pos_fname
        pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1) *)

let parse_with_error s =
    let lexbuf = Lexing.from_string s in
    try Parser.prog Lexer.read lexbuf with
    | Parser.Error ->
        Printf.printf "%d:%d: syntax error\n" lexbuf.lex_curr_p.pos_lnum (lexbuf.lex_curr_p.pos_cnum - lexbuf.lex_curr_p.pos_bol + 1);
        exit (-1)

let parse s = Parser.prog Lexer.read (Lexing.from_string s)

let readFile f = with_open_text f input_all

let topfile = "lib/toplevel.mona"

let run inf outf =
    let top = readFile topfile in
    let code = readFile inf in 
    let prog = parse_with_error (top ^ "\n" ^ code) in
    let (alphaprog, _) = alphaExpr prog 0 in 
    match typeCheck alphaprog with
    | Value ((_, prog'), _) -> generate prog' outf; Utils.fstring "Successfully compiled %s in %s" inf outf
    | Error e -> e