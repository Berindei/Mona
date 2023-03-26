open Utils

type var = string
type time = int
type id = int

type indx = 
    | IVar of var
    | Time of time
    | Id of id

type indxtype = 
    | (*Ho-kago*) TTime
    | TId

let printindx i =
    match i with 
    | IVar x -> x
    | Time t -> string_of_int t
    | Id i -> string_of_int i

let printindxtype t = 
    match t with
    | TTime -> "Time" 
    | TId -> "Id"

type typ = 
    | TVar   of var
    | LUnit
    | Color
    | Loli   of typ * typ
    | Tensor of typ * typ
    | LSum   of typ * typ
    | F      of typ
    | Evt    of typ
    | IUnit
    | Arrow  of typ * typ
    | Prod   of typ * typ
    | ISum   of typ * typ
    | G      of typ
    | IndxT  of indxtype
    | At     of typ * indx
    | Univ   of var * indxtype * typ
    | Exist  of var * indxtype * typ
    | Widget of indx
    | Prefix of indx * indx
    | Num  
    | Char  
    | String

let rec printtype t = 
    match t with
    | TVar x            -> x
    | LUnit             -> "I"
    | Loli (t1, t2)     -> fstring "(%s⊸%s)" (printtype t1) (printtype t2)
    | Tensor (t1, t2)   -> fstring "(%s⊗%s)" (printtype t1) (printtype t2)
    | LSum (t1, t2)     -> fstring "(%s⊕%s)" (printtype t1) (printtype t2)
    | F t'              -> fstring "F(%s)" (printtype t')
    | Evt t'            -> fstring "♢(%s)" (printtype t')
    | IUnit             -> "1"
    | Arrow (t1, t2)    -> fstring "(%s→%s)" (printtype t1) (printtype t2)
    | Prod (t1, t2)     -> fstring "(%s*%s)" (printtype t1) (printtype t2)
    | ISum (t1, t2)     -> fstring "(%s+%s)" (printtype t1) (printtype t2)
    | G t'              -> fstring "G(%s)" (printtype t')
    | IndxT i           -> printindxtype i
    | At (t1, t')       -> fstring "%s@%s" (printtype t1) (printindx t')
    | Univ (x, t1, t2)  -> fstring "∀%s:%s. %s" x (printindxtype t1) (printtype t2)
    | Exist (x, t1, t2) -> fstring "∃%s:%s. %s" x (printindxtype t1) (printtype t2)
    | Widget i          -> fstring "Widget %s" (printindx i)
    | Prefix (i, t)     -> fstring "Prefix %s %s" (printindx i) (printindx t)
    | Color             -> "Color"
    | Num               -> "Num"
    | Char              -> "Char"
    | String            -> "String"

type pat = 
    | PUnit
    | PAt of pat
    | PF of pat
    | PPack of var * pat
    | PPair of pat * pat
    | PAtPair of pat * pat
    | PVar of var
    | PAnnot of pat * typ

let rec printpat p =
    match p with
    | PUnit -> "()"
    | PAt p -> fstring "@(%s)" (printpat p)
    | PF p -> fstring "F(%s)" (printpat p)
    | PPack (i, p) -> fstring "pack(%s, %s)" i (printpat p)
    | PPair(p1, p2) -> fstring "Pair(%s, %s)" (printpat p1) (printpat p2)
    | PAtPair(p1, p2) -> fstring "P@(%s, %s)" (printpat p1) (printpat p2)
    | PVar x -> x
    | PAnnot(p, t) -> fstring "(%s: %s)" (printpat p) (printtype t)


type expr = 
    | EUnit
    (* | LetUnit       of expr * expr *)
    | Var           of var
    | TypedVar      of var * typ * indx
    | Lambda        of var * expr
    | LetFix        of var * typ * var * expr * expr
    | App           of expr * expr
    | Pair          of expr * expr
    (* | Unpair        of var * var * expr * expr *)
    | AtUnpair      of pat * pat * expr * expr
    | Annot         of expr * typ
    | L             of expr
    | R             of expr
    | Case          of expr * var * expr * var * expr
    | Proj1         of expr
    | Proj2         of expr
    | EF            of expr
    | EG            of expr
    | Run           of expr
    (* | LetF          of var * expr * expr *)
    | EEvt          of expr
    | LetEvt        of var * expr * expr
    (* | Let           of var * expr * expr *)
    | Select        of var * var * expr * expr * expr * expr
    | EAt           of expr
    (* | LetAt         of var * expr * expr *)
    | LambdaIndx    of var * expr
    | AppIndx       of expr * indx
    | Pack          of indx * expr
    (* | LetPack       of var * var * expr * expr *)
    | Indx          of indx
    | Extern        of var * typ * string * expr
    | Out           of expr
    | Into          of expr
    | ENum          of int
    | EChar         of char
    | EString       of string
    | Let           of pat * expr * expr

let rec printexpr e =
    match e with
    | EUnit -> "()"
    (* | LetUnit (e1, e2)                -> fstring "let () = %s in %s" (printexpr e1) (printexpr e2) *)
    | Var x -> x
    | Lambda (x, e')                  -> fstring "λ%s.%s" x (printexpr e')
    | LetFix (f, t, x, e1, e2)        -> fstring "let fix %s:(%s) %s. %s in %s" f (printtype t) x (printexpr e1) (printexpr e2)
    | App (e1, e2)                    -> fstring "(%s)(%s)" (printexpr e1) (printexpr e2)
    | Pair (e1, e2)                   -> fstring "(%s, %s)" (printexpr e1) (printexpr e2)
    (* | Unpair (x1, x2, e1, e2)         -> fstring "let (%s,%s) = %s in %s" x1 x2 (printexpr e1) (printexpr e2) *)
    | AtUnpair (x1, x2, e1, e2)       -> fstring "let @(%s, %s) = %s in %s" (printpat x1) (printpat x2) (printexpr e1) (printexpr e2)
    | Annot (e', t)                   -> fstring "(%s: %s)" (printexpr e') (printtype t)
    | L e'                            -> fstring "L(%s)" (printexpr e')
    | R e'                            -> fstring "R(%s)" (printexpr e')
    | Case (e', x1, e1, x2, e2)       -> fstring "case(%s, L(%s)->%s, R(%s)->%s)" (printexpr e') x1 (printexpr e1) x2 (printexpr e2)
    | Proj1 e'                        -> fstring "π1(%s)" (printexpr e')
    | Proj2 e'                        -> fstring "π2(%s)" (printexpr e')
    | EF e'                           -> fstring "F(%s)" (printexpr e')
    | EG e'                           -> fstring "G(%s)" (printexpr e')
    | Run e'                          -> fstring "run(%s)" (printexpr e')
    (* | LetF (x, e1, e2)                -> fstring "let F(%s) = %s in %s" x (printexpr e1) (printexpr e2) *)
    | EEvt e'                         -> fstring "evt(%s)" (printexpr e')
    | LetEvt (x, e1, e2)              -> fstring "let evt(%s) = %s in %s" x (printexpr e1) (printexpr e2)
    (* | Let (x, e1, e2)                 -> fstring "let %s = %s in %s" x (printexpr e1) (printexpr e2) *)
    | Select (x1, x2, e1, e2, e3, e4) -> fstring "(from {%s←%s; %s←%s} select %s→%s | %s→%s)" x1 (printexpr e1) x2 (printexpr e2) x1 (printexpr e3) x2 (printexpr e4)
    | EAt e'                          -> fstring "@(%s)" (printexpr e')
    (* | LetAt (x, e1, e2)               -> fstring "let @%s = %s in %s" x (printexpr e1) (printexpr e2) *)
    | LambdaIndx (x, e')              -> fstring "Λ%s. %S" x (printexpr e')
    | AppIndx (e1, e2)                -> fstring "(%s [%s])" (printexpr e1) (printindx e2)
    | Pack (e1, e2)                   -> fstring "pack(%s, %s)" (printindx e1) (printexpr e2)
    (* | LetPack (i, x, e1, e2)          -> fstring "let pack(%s, %s) = %s in %s" i x (printexpr e1) (printexpr e2) *)
    | Indx (indx)                     -> printindx indx
    | Extern (f, t, s, e')            -> fstring "let extern %s:(%s) = %s in %s" f (printtype t) s (printexpr e')
    | Out e'                          -> fstring "out %s" (printexpr e')
    | Into e'                         -> fstring "into %s" (printexpr e')
    | ENum n                          -> string_of_int n
    | EChar c                         -> fstring "\'%c\'" c
    | EString s                       -> fstring "\"%s\"" s
    | Let (p, e1, e2)                 -> fstring "let %s = %s in %s" (printpat p) (printexpr e1) (printexpr e2)
    | _ -> "##############"

