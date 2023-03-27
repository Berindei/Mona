%{
    open Ast
%}

%token <string> ID
%token <int> NUM
%token <string> STRING
%token <char> CHAR
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
%token TNUM TSTRING TCHAR
%token EOF

%start <Ast.expr> prog

%left LEFTASSOC 

%%

prog:
    | e = expr; EOF { e }
    ;

expr:
    | x = ID                                                                                                           { Var x }
    | UNIT                                                                                                             { EUnit }
    | s = STRING                                                                                                       { EString s }
    | c = CHAR                                                                                                         { EChar c }
    | n = NUM                                                                                                          { ENum n }
    | LAMBDA; x = ID; DOT; e = expr                                                                                    { Lambda(x, e) }
    | BLAMBDA; i = ID; DOT; e = expr                                                                                   { LambdaIndx(i, e) }
    | e1 = expr; e2 = expr                                                                                             { App(e1, e2) }
    | e = expr; COLON; t = typ                                                                                         { Annot(e, t) }
    | CASE; LPARAN; e = expr; COMMA; L; x = paranv; RARROW; e1 = expr; COMMA; R; y = paranv; RARROW; e2 = expr; RPARAN { Case(e, x, e1, y, e2) }
    | e1 = expr; COMMA; e2 = expr                                                                                      { Pair(e1, e2) }
    | SEQ; x = ID; LARROW; e1 = expr; SEMICOLON; y = ID; LARROW; e2 = expr; ST; BAR WHEN a = ID; RARROW; e3 = expr; BAR WHEN b = ID; RARROW e4 = expr { if a=x && b=y then Select(x, y, e1, e2, e3, e4)
                                                                                                                                             else if a=y && b=x then Select(x, y, e1, e2, e3, e4)
                                                                                                                                             else failwith "parsing error"}
    | PACK LPARAN x=ID COMMA y=expr RPARAN                                                                             { Pack((IVar x), y) }
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
    | LET p=pat EQ e1=expr IN e2=expr                                                                                { match p with PAnnot(p', t) -> Let(p', Annot(e1, t), e2) | _ -> Let(p, e1, e2)}
    //| LET; x = ID; COLON; t = typ; EQ; e1 = expr; IN; e2 = expr                                                        { Let(x, Annot(e1, t), e2) }
    | LET AT LPARAN p1 = pat COMMA p2 = pat RPARAN EQ e1 = expr IN e2 = expr                                         { AtUnpair(p1, p2, e1, e2) }
    //| LET; x = ID; EQ; e1 = expr; IN; e2 = expr                                                                        { Let(x, e1, e2) }
    //| LET; UNIT EQ e1=expr IN e2=expr                                                                                  { LetUnit(e1, e2) }
    //| LET; F; x = paranv; EQ; e1 = expr; IN; e2 = expr                                                                 { LetF(x, e1, e2) }
    //| LET; LPARAN; x = ID; COMMA; y = ID; RPARAN; EQ; e1 = expr; IN; e2 = expr                                         { Unpair(x, y, e1, e2) }
    | LET; EVT; x = pat; EQ; e1 = expr; IN; e2 = expr                                                                { LetEvt(x, e1, e2) }
    //| LET; AT; x = paranv; EQ; e1 = expr; IN; e2 = expr                                                                { LetAt(x, e1, e2) }
    //| LET PACK LPARAN x=ID COMMA y=ID RPARAN EQ e1=expr IN e2=expr                                                     { LetPack(x, y, e1, e2) }
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
    | TSTRING                                                    { String }
    | TCHAR                                                      { Char }
    | TNUM                                                       { Num }
    | t1 = typ; RARROW; t2 = typ                                 { Arrow(t1, t2) }
    | t1 = typ; LOLI; t2 = typ                                   { Loli(t1, t2) }
    | t1 = typ; TIMES; t2 = typ                                  { Prod(t1, t2) }
    | t1 = typ; TENSOR; t2 = typ                                 { Tensor(t1, t2) }
    | t1 = typ; PLUS; t2 = typ                                   { ISum(t1, t2) }
    | t1 = typ; LPLUS; t2 = typ                                  { LSum(t1, t2) }
    | DIAMOND; t = typ                                           { Evt t }
    | t = typ; AT; i = ID                                        { At(t, (IVar i)) }
    | UNIV LPARAN i = ID COLON it=indxtype RPARAN DOT t = typ    { Univ(i, it, t) }
    | EXIST LPARAN i = ID COLON it=indxtype RPARAN DOT t=typ     { Exist(i, it, t) }
    | WIDGET i = ID                                              { Widget (IVar i)}
    | PREFIX i = ID t = ID                                       { Prefix ((IVar i), (IVar t))}
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

indxtype:
    | TIME { TTime }
    | WID  { TId }

pat:
    | LPARAN p=pat RPARAN                 { p }
    | UNIT                                { PUnit }
    | x=ID                                { PVar x }
    | p=pat COLON t=typ                   { PAnnot(p, t) }
    | F p=pat                             { PF p }
    | AT p=pat                            { PAt p }
    | PACK LPARAN x=ID COMMA p=pat RPARAN { PPack(x, p) }
    | p1=pat COMMA p2=pat                 { PPair(p1, p2) }