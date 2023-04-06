%{
    open Ast

    let pairexprs me1 me2 = 
        match me1, me2 with
        | None, None -> failwith "Empty expression"
        | Some e1, None -> e1
        | None, Some e2 -> e2
        | Some e1, Some e2 -> Pair(e1, e2)
    
    let mkseq (bind, br) = 
        let rec constr bind br = 
            match bind with
            | (x, e) :: xs ->
                let e' = List.assoc x br in
                let br' = List.remove_assoc x br in
                let e1, e2 = constr xs br' in
                ((x, e) :: e1 , (x, e') :: e2)
            | [] ->
                match br with
                | [] -> [], []
                | _  -> failwith "Too many arguments in sequencing"
        in
        let l1, l2 = constr bind br in
        Select(l1, l2)

    let mklambda (x, e) = List.fold_right (fun x e' -> Lambda(x, e')) x e

    let mkblambda (x, e) = List.fold_right (fun x e' -> LambdaIndx(x, e')) x e

    let mkuniv (xs, t) = List.fold_right (fun (x, i) e' -> Univ(x, i, e')) xs t

    let mkexist (xs, t) = List.fold_right (fun (x, i) e' -> Exist(x, i, e')) xs t
                          
%}

%token <string> ID
%token <int> NUM
%token <string> STRING
%token <char> CHAR
%token IUNIT LUNIT
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
%token LBRACE RBRACE FOR
%token EOF

%start <Ast.expr> prog

%start <Ast.typ> test_typ

%nonassoc Low
%nonassoc COMMA
%right BAR
%right COLON

%nonassoc Below_Func
%right RARROW LOLI

%%

let test_typ:=
    | ~=typ; EOF; <>

let prog:=
    | ~=exp; EOF; <>

let unit == LPARAN; RPARAN

let exp_atom:=
    | ~=unary_exp; <>
    | ~=nullary_exp; <>
    | LPARAN; ~=exp; RPARAN;               <>
    | LPARAN; e1=exp; COMMA; e2=exp; RPARAN; <Pair>

let exp_atom_list:=
    | ~=exp_atom_list; ~=exp_atom; <App>
    | ~=exp_atom; <>

let exp_app:=
    | ~=exp_atom_list;    <>

let unary_exp:=
    | L; ~=exp_atom; <L>
    | R; ~=exp_atom; <R>
    | F; ~=exp_atom; <EF>
    | G; ~=exp_atom; <EG>
    | P1; ~=exp_atom; <Proj1>
    | P2; ~=exp_atom; <Proj2>
    | RUN; ~=exp_atom; <Run>
    | EVT; LPARAN; ~=exp_atom; RPARAN; <EEvt>
    | AT; ~=exp_atom; <EAt>
    | OUT; ~=exp_atom; <Out>
    | INTO; ~=exp_atom; <Into>

let nullary_exp:=
    | ~=ID;                            <Var>
    | unit;                            {EUnit}
    | ~=STRING;                        <EString>
    | ~=CHAR;                          <EChar>
    | ~=NUM;                           <ENum>

let exp:=
    | ~=exp_app;   <>
    | ~=letexp;    <> %prec Low
    | ~=lambdaexp; <> %prec Low
    | ~=exp; COLON; ~=typ; <Annot>
    | SEQ; ~=binderst; ST; ~=branchst;               <mkseq>
    | FOR; w=ID; i=ID; COLON; LBRACE; 
             cmds=cmdlist; RBRACE; e=exp;          {cmds w i e} %prec Low
    | CASE; LPARAN; e1=exp; COMMA;
                  L; p1=pat; RARROW; e2=exp; COMMA;
                  R; p2=pat; RARROW; e3=exp; RPARAN; <Case>
    | PACK; LPARAN; ~=indx; COMMA; ~=exp; RPARAN;      <Pack>

let letexp==
    | LET; ~=pat; EQ; e1=exp; IN; e2=exp;                          {match pat with PAnnot(p, t) -> Let(p, (Annot(e1, t)), e2) | _ -> Let(pat, e1, e2)}
    | LET; EVT; ~=pat; EQ; e1=exp; IN; e2=exp;                     <LetEvt>
    | LET; EXTERN; ~=ID; COLON; ~=typ; EQ; ~=STRING; IN; e2=exp;     <Extern>
    | LET; FIX; ~=ID; COLON; ~=typ; ~=ID; DOT; e1=exp; IN; e2=exp; <LetFix>

let lambdaexp==
    | LAMBDA; ~=idlist; DOT; ~=exp;  <mklambda>
    | BLAMBDA; ~=idlist; DOT; ~=exp; <mkblambda>

let idlist:=
    | ~=ID; ~=idlist; <(::)>
    |                 {[]}

let binderst:=
    | SEMICOLON?; ~=binder; ~=binders; <(::)>

let binders:=
    | SEMICOLON; ~=binder; ~=binders; <(::)>
    | SEMICOLON; ~=binder;            {[binder]}

let binder:=
    | ~=ID; LARROW; ~=exp; <> %prec Low

let branchst:=
    | BAR?; ~=branch; ~=branches; <(::)>

let branches:=
    | BAR; ~=branch; ~=branches; <(::)>
    | BAR; ~=branch;             {[branch]}

let branch:=
    | WHEN; ~=ID; RARROW; ~=exp;  <> %prec Low

let cmdlist:=
    | ~=cmd;                    <>
    | c=cmd; COMMA; cl=cmdlist; { (fun w -> fun i -> fun e -> c w i (cl w i e)) }

let cmd:=
    | p=pat; EQ; f=ID; LPARAN; e=exp?; RPARAN; { fun w i e' -> Let(PPair((PVar w), p), App(App(Var(f), Var(i)), pairexprs (Some(Var w)) e), e') }
    | f=ID; LPARAN; e=exp?; RPARAN;            { fun w i e' -> Let(PVar w, App(App(Var(f), Var(i)), pairexprs (Some(Var w)) e), e') }

let pat_atom:=
    | unit; {PUnit}
    | ~=ID; <PVar>
    | LPARAN; ~=pat; RPARAN; <>

let pat:=
    | ~=pat_atom; <>
    | p1=pat; COMMA; p2=pat; <PPair>
    | ~=pat; COLON; ~=typ; <PAnnot>
    | AT; ~=pat_atom; <PAt>
    | F; ~=pat_atom; <PF>
    | PACK; LPARAN; ~=ID; COMMA; ~=pat; RPARAN; <PPack>

let indxidlistst:=
    | ~=unit_indx_def; ~=indxidlist; <(::)>

let indxidlist:=
    | COMMA; ~=unit_indx_def; ~=indxidlist; <(::)>
    | {[]}

let unit_indx_def:=
    | LPARAN; ~=unit_indx_def; RPARAN; <>
    | ~=ID; COLON; ~=indxtyp;          <>

let indxtyp:=
    | TIME; {TTime}
    | WID;  {TId}

let indx:=
    | ~=ID; <IVar>

let typ:=
    | ~=func_typ; <> 

let func_typ:=
    | UNIV; ~=indxidlistst; DOT; ~=typ;  <mkuniv>
    | EXIST; ~=indxidlistst; DOT; ~=typ; <mkexist>
    | ~=sum_typ; RARROW; ~=func_typ; <Arrow>
    | ~=sum_typ; LOLI; ~=func_typ; <Loli>
    | ~=sum_typ; <> %prec Below_Func

let sum_typ:=
    | t1=prod_typ; PLUS; t2=sum_typ;  <ISum>
    | t1=prod_typ; LPLUS; t2=sum_typ; <LSum>
    | ~=prod_typ; <>

let prod_typ:=
    | t1=at_typ; TIMES; t2=prod_typ;  <Prod>
    | t1=at_typ; TENSOR; t2=prod_typ; <Tensor>
    | ~=at_typ; <>

let at_typ:=
    | ~=at_typ; AT; ~=indx; <At>
    | ~=tp_atom; <>

let tp_atom:=
    | ~=unary_tp;            <>
    | ~=nullary_tp;           <>
    | LPARAN; ~=typ; RPARAN; <>

let nullary_tp:=
    | LUNIT;   {LUnit}
    | IUNIT;   {IUnit}
    | COLOR;   {Color}
    | TSTRING; {String}
    | TCHAR;   {Char}
    | TNUM;    {Num}
    | WIDGET; ~=indx;       <Widget>
    | PREFIX; i1=indx; i2=indx; <Prefix>

let unary_tp==
    | F; ~=tp_atom;       <F>
    | G; ~=tp_atom;       <G>
    | DIAMOND; ~=tp_atom; <Evt>