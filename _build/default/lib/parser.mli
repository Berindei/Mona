
(* The type of tokens. *)

type token = 
  | WIDGET
  | WID
  | WHEN
  | UNIV
  | UNIT
  | TIMES
  | TIME
  | TENSOR
  | STRING of (string)
  | ST
  | SEQ
  | SEMICOLON
  | RUN
  | RPARAN
  | RARROW
  | R
  | PREFIX
  | PLUS
  | PACK
  | P2
  | P1
  | OUT
  | NUM of (int)
  | LUNIT
  | LPLUS
  | LPARAN
  | LOLI
  | LET
  | LARROW
  | LAMBDA
  | L
  | IUNIT
  | INTO
  | IN
  | ID of (string)
  | G
  | FIX
  | F
  | EXTERN
  | EXIST
  | EVT
  | EQ
  | EOF
  | DOT
  | DIAMOND
  | COMMA
  | COLOR
  | COLON
  | CASE
  | BLAMBDA
  | BAR
  | AT

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val prog: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.expr)
