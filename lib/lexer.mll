{
    open Parser
}

let white = [' ' '\t' '\n' '\r']+
let letter = ['a'-'z' 'A'-'Z']
let digit = ['0'-'9']
let id = (letter|digit)+
let comment = "//" [^'\n']* "\n"
let string = "\"" [^'\"']* "\""
let num = digit+

rule read = 
    parse
    | white       { read lexbuf }
    | comment     { read lexbuf }
    | "Id"        { WID }
    | "()"        { UNIT }
    | "I"         { LUNIT }
    | "1"         { IUNIT }
    | "λ"         { LAMBDA }
    | "fun"       { LAMBDA }
    | "Λ"         { BLAMBDA }
    | "Fun"       { BLAMBDA }
    | "."         { DOT }
    | ","         { COMMA }
    | "|"         { BAR }
    | ";"         { SEMICOLON }
    | "("         { LPARAN }
    | ")"         { RPARAN }
    | ":"         { COLON }
    | "->"        { RARROW }
    | "→"         { RARROW }
    | "<-"        { LARROW }
    | "←"         { LARROW }
    | "let"       { LET }
    | "fix"       { FIX }
    | "L"         { L }
    | "R"         { R }
    | "F"         { F }
    | "G"         { G }
    | "case"      { CASE }
    | "π1"        { P1 }
    | "π2"        { P2 }
    | "run"       { RUN }
    | "="         { EQ }
    | "in"        { IN }
    | "⊸"        { LOLI }
    | "-o"        { LOLI }
    | "*"         { TIMES }
    | "⊗"        { TENSOR }
    | "L*"        { TENSOR }
    | "+"         { PLUS }
    | "⊕"        { LPLUS }
    | "L+"        { LPLUS }
    | "evt"       { EVT }
    | "seq"       { SEQ }
    | "sequence"  { SEQ }
    | "when"      { WHEN }
    | "st"        { ST }
    | "such that" { ST }
    | "♢"         { DIAMOND }
    | "<>"        { DIAMOND }
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
    | string      { let s = Lexing.lexeme lexbuf in let l = String.length s in STRING (String.sub s 1 (l-2))}
    | num         { NUM (int_of_string (Lexing.lexeme lexbuf)) }
    | id          { ID (Lexing.lexeme lexbuf) }
    | eof         { EOF }