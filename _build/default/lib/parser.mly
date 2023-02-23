%{
    open Ast
%}

%token <string> ID
%token <int> NUM
%token <string> STRING
%token UNIT IUNIT LUNIT
%token LAMBDA BLAMBDA
%token LPARAN RPARAN
%token DOT COLON COMMA BAR SEMICOLON
%token RARROW LARROW LOLI
%token LET IN EXTERN FIX
%token L R
%token CASE
%token P1 P2
%token F G
%token RUN
%token EQ
%token TIMES TENSOR
%token PLUS LPLUS
%token EVT SEQ ST WHEN
%token DIAMOND
%token AT
%token PACK
%token UNIV EXIST
%token TIME WID
%token WIDGET PREFIX
%token OUT INTO
%token COLOR
%token EOF

%start <Ast.expr> prog

%%

prog:
    | e = expr; EOF { e }
    ;

expr:
    | x = ID                                                                                                           { Var x }
    | UNIT                                                                                                             { EUnit }
    | LAMBDA; x = ID; DOT; e = expr                                                                                    { Lambda(x, e) }
    | BLAMBDA; i = ID; DOT; e = expr                                                                                   { LambdaIndx(i, e) }
    | e1 = expr; e2 = expr                                                                                             { App(e1, e2) }
    | e1 = expr; i = indx                                                                                              { App(e1, Indx(i)) }
    | e = expr; COLON; t = typ                                                                                         { Annot(e, t) }
    | CASE; LPARAN; e = expr; COMMA; L; x = paranv; RARROW; e1 = expr; COMMA; R; y = paranv; RARROW; e2 = expr; RPARAN { Case(e, x, e1, y, e2) }
    | e1 = expr; COMMA; e2 = expr                                                                                      { Pair(e1, e2) }
    | SEQ; x = ID; LARROW; e1 = expr; SEMICOLON; y = ID; LARROW; e2 = expr; ST; BAR WHEN a = ID; RARROW; e3 = expr; BAR WHEN b = ID; RARROW e4 = expr { if a=x && b=y then Select(x, y, e1, e2, e3, e4)
                                                                                                                                             else if a=y && b=x then Select(x, y, e1, e2, e3, e4)
                                                                                                                                             else failwith "parsing error"}
    | PACK LPARAN x=indx COMMA y=expr RPARAN                                                                           { Pack(x, y) }
    | e = lete                                                                                                         { e }
    | e = funclike                                                                                                     { e }
    | e = parane                                                                                                       { e }
    ;

funclike:
    | L; e = expr                                                                                                    { L(e) }
    | R; e = expr                                                                                                    { R(e) }
    | F; e = expr                                                                                                    { EF(e) }
    | G; e = expr                                                                                                    { EG(e) }
    | P1; e = expr                                                                                                   { Proj1(e) }
    | P2; e = expr                                                                                                   { Proj2(e) }
    | RUN; e = expr                                                                                                  { Run(e) }
    | EVT; e = expr                                                                                                  { EEvt(e) }
    | AT; e = expr                                                                                                   { EAt e }
    | OUT; e = expr                                                                                                  { Out e }
    | INTO; e = expr                                                                                                 { Into e }
    ;

lete:
    | LET; x = ID; EQ; e1 = expr; IN; e2 = expr                                                                        { Let(x, e1, e2) }
    | LET; LPARAN RPARAN EQ e1=expr IN e2=expr                                                                         { LetUnit(e1, e2) }
    | LET; F; x = paranv; EQ; e1 = expr; IN; e2 = expr                                                                 { LetF(x, e1, e2) }
    | LET; LPARAN; x = ID; COMMA; y = ID; RPARAN; EQ; e1 = expr; IN; e2 = expr                                         { Unpair(x, y, e1, e2) }
    | LET; EVT; x = paranv; EQ; e1 = expr; IN; e2 = expr                                                               { LetEvt(x, e1, e2) }
    | LET; AT; x = paranv; EQ; e1 = expr; IN; e2 = expr                                                                { LetAt(x, e1, e2) }
    | LET PACK LPARAN x=ID COMMA y=ID RPARAN EQ e1=expr IN e2=expr                                                     { LetPack(x, y, e1, e2) }
    | LET EXTERN x=ID COLON t=typ EQ s=STRING IN e=expr                                                                { Extern(x, t, s, e) }
    | LET FIX f=ID COLON LPARAN t=typ RPARAN x=ID DOT e1=expr IN e2=expr                                               { LetFix(f, t, x, e1, e2) }
    ;

paranv:
    | x = ID                 {x}
    | LPARAN; x = ID; RPARAN {x}
    ;

parane:
    | LPARAN; e = expr; RPARAN {e}
    ;

typ:
    | x = ID                                                     { TVar x }
    | IUNIT                                                      { IUnit }
    | LUNIT                                                      { LUnit }
    | COLOR                                                      { Color }
    | t1 = typ; RARROW; t2 = typ                                 { Arrow(t1, t2) }
    | t1 = typ; LOLI; t2 = typ                                   { Loli(t1, t2) }
    | t1 = typ; TIMES; t2 = typ                                  { Prod(t1, t2) }
    | t1 = typ; TENSOR; t2 = typ                                 { Tensor(t1, t2) }
    | t1 = typ; PLUS; t2 = typ                                   { ISum(t1, t2) }
    | t1 = typ; LPLUS; t2 = typ                                  { LSum(t1, t2) }
    | DIAMOND; t = typ                                           { Evt t }
    | t = typ; AT; i = indx                                      { At(t, i) }
    | UNIV LPARAN i = ID COLON it=indxtype RPARAN DOT t = typ    { Univ(i, it, t) }
    | EXIST LPARAN i = ID COLON it=indxtype RPARAN DOT t=typ     { Exist(i, it, t) }
    | WIDGET i = indx                                            { Widget i}
    | PREFIX i = indx t = indx                                   { Prefix (i, t)}
    | t = funcliket                                              { t }
    | t = parant                                                 { t }
    ;

parant:                                               
    | LPARAN; t = typ; RPARAN                                    { t }
    ;

funcliket:
    | F; t = typ                                                 { F t }
    | G; t = typ                                                 { G t }
    | DIAMOND; t = typ                                           { Evt t }

indx:
    | x = ID  { IVar x }
    | n = NUM { Time n }

indxtype:
    | TIME { TTime }
    | WID  { TId }