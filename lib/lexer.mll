{
    open Parser
}

let white = [' ' '\t' '\n' '\r']+
let letter = ['a'-'z' 'A'-'Z']
let digit = ['0'-'9']
let id = (letter|digit)+
let comment = "//" [^'\n']* "\n"
let string = "\"" [^'\"']* "\""
let char = "\'" letter "\'"
let num = digit+

rule read = 
    parse
    | white       { read lexbuf }
    | comment     { read lexbuf }
    | "Id"        { WID }
    | "I"         { LUNIT }
    | "unit"         { IUNIT }
    | "λ" | "fun" { LAMBDA }
    | "Λ" | "Fun" { BLAMBDA }
    | "."         { DOT }
    | ","         { COMMA }
    | "|"         { BAR }
    | ";"         { SEMICOLON }
    | "("         { LPARAN }
    | ")"         { RPARAN }
    | ":"         { COLON }
    | "->" | "→"  { RARROW }
    | "<-" | "←"  { LARROW }
    | "let"       { LET }
    | "fix"       { FIX }
    | "L"         { L }
    | "R"         { R }
    | "F"         { F }
    | "G"         { G }
    | "case"      { CASE }
    | "π1" | "fst"{ P1 }
    | "π2" | "snd"{ P2 }
    | "run"       { RUN }
    | "="         { EQ }
    | "in"        { IN }
    | "⊸" | "-o" { LOLI }
    | "*"         { TIMES }
    | "⊗" | "L*" { TENSOR }
    | "+"         { PLUS }
    | "⊕" | "L+" { LPLUS }
    | "evt"       { EVT }
    | "seq"       { SEQ }
    | "sequence"  { SEQ }
    | "when"      { WHEN }
    | "st"        { ST }
    | "such that" { ST }
    | "♢" | "<>"  { DIAMOND }
    | "@"         { AT }
    | "pack"      { PACK }
    | "∀"         { UNIV }
    | "∃"         { EXIST }
    | "Time"      { TIME }
    | "extern"    { EXTERN }
    | "Widget"    { WIDGET }
    | "Prefix"    { PREFIX }
    | "out"       { OUT }
    | "into"      { INTO }
    | "Color"     { COLOR }
    | "String"    { TSTRING }
    | "Num"       { TNUM }
    | "Char"      { TCHAR }
    | "{"         { LBRACE }
    | "}"         { RBRACE }
    | "for"       { FOR }
    | "_"         { UNDERSCORE }
    | "type"      { TYPE }
    | string      { let s = Lexing.lexeme lexbuf in let l = String.length s in STRING (String.sub s 1 (l-2))}
    | num         { NUM (int_of_string (Lexing.lexeme lexbuf)) }
    | char        { let s = Lexing.lexeme lexbuf in CHAR (String.get s 1) }
    | id          { ID ("_" ^ (Lexing.lexeme lexbuf)) }
    | eof         { EOF }