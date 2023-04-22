open Ast
open Utils

exception UnboundVariable of string

type 'a t = int -> ('a * int)

let return (x: 'a) : 'a t = fun c -> (x, c)

let bind (a: 'a t) (f: 'a -> 'b t) : 'b t = fun c -> let a', c' = a c in f a' c'

let (>>) = bind

let (let*) = bind

let get : int t = fun n -> (n, n)
let set m = fun n -> ((), m)
let getNewBind : string t = fun n -> ("var_" ^ (string_of_int n), n+1)

let rec elevateT (l: 'a t list) : 'a list t =
    match l with
    | []      -> return []
    | x :: xs -> let* x' = x in 
                 let* xs' = elevateT xs in (return (x'::xs'))

let varinpat v p = List.mem v (List.map fst (vars p))

let rec bindpat (p: pat) : (pat * var list) t = 
    match p with
    | PUnit -> return (p, [])
    | PWildcard -> return (p, [])
    | PAt p' -> let* p'', b = bindpat p' in return (PAt p'', b)
    | PF p' -> let* p'', b = bindpat p' in return (PF p'', b)
    | PPack ((i, i'), p') ->
        if i'<>"" then raise (UnexpectedError __LOC__) else
        let* s = getNewBind in
        let* p'', l = bindpat p' in
        return (PPack((i, s), p''), ((i, s) :: l))
    | PPair (p1, p2) ->
        let* p1', l1 = bindpat p1 in
        let* p2', l2 = bindpat p2 in
        return (PPair(p1', p2'), (l1 @ l2))
    | PAtPair (p1, p2) -> 
        let* p1', l1 = bindpat p1 in
        let* p2', l2 = bindpat p2 in
        return (PAtPair(p1', p2'), (l1 @ l2))
    | PVar (x, y) -> if y<>"" then raise (UnexpectedError  __LOC__ )else
        let* s = getNewBind in
        return (PVar(x, s), [(x, s)])
    | PAnnot (p', t) ->
        let* p'', l = bindpat p' in
        return (PAnnot(p'', t), l)



let rec subexpr v e : expr = (* fix later *)
    let sube = subexpr v in
    let subt = subtype v in
    let subi = subindx v in
    let (x, y) = v in
    match (e : expr) with
    | EUnit -> EUnit
    | Var (x', y') -> if x=x' then Var v else e
    | TypedVar (_, _, _) -> raise (UnexpectedError __LOC__ )
    | Lambda ((x', y'), e') -> if x=x' then e else Lambda ((x', y'), sube e')
    | LetFix ((f, f'), t, (x', y'), e1, e2) ->
        if f=x then LetFix ((f, f'), t, (x', y'), e1, e2)
        else if x=x' then LetFix ((f, f'), t, (x', y'), e1, sube e2)
        else LetFix ((f, f'), subt t, (x', y'), sube e1, sube e2)
    | App (e1, e2) -> App (sube e1, sube e2)
    | Pair (e1, e2) -> Pair (sube e1, sube e2)
    | AtUnpair (_, _, _, _) -> raise (UnexpectedError __LOC__ )
    | Annot (e1, t) -> Annot (sube e1, subt t)
    | L e' -> L (sube e')
    | R e' -> R (sube e')
    | Case (e', p1, e1, p2, e2) ->
        let b1 = varinpat x p1 in
        let b2 = varinpat x p2 in
        (match b1, b2 with
        | true, true -> Case (sube e', p1, e1, p2, e2)
        | true, false -> Case (sube e', p1, sube e1, p2, e2)
        | false, true -> Case (sube e', p1, e1, p2, sube e2)
        | false, false -> Case (sube e', p1, sube e1, p2, sube e2))
    | Proj1 e' -> Proj1 (sube e')
    | Proj2 e' -> Proj2 (sube e')
    | EF e' -> EF (sube e')
    | EG e' -> EG (sube e')
    | Run e' -> Run (sube e')
    | EEvt e' -> EEvt (sube e')
    | LetEvt (p, e1, e2) -> if varinpat x p then LetEvt(p, sube e1, e2) else LetEvt(p, sube e1, sube e2)
    | Select (bi, br) ->
        let bi' = List.map (fun (v, e') -> (v, sube e')) bi in
        let br' = if List.mem x (List.map (fun x -> fst (fst x)) br) then br else List.map (fun (v, e') -> (v, sube e')) br in
        Select (bi', br')
    | EAt e' -> EAt (sube e')
    | LambdaIndx ((i, i'), e') -> if x=i then e else LambdaIndx((i, i'), sube e')
    | AppIndx (_, _) -> failwith "????"
    | Pack (i, e') -> Pack(subi i, sube e')
    | Indx i -> Indx (subi i)
    | Extern ((x', y'), t, s, e') -> if x=x' then e else Extern ((x', y'), subt t, s, sube e')
    | Out e' -> Out (sube e')
    | Into e' -> Into (sube e')
    | ENum _ | EChar _ | EString _ -> e
    | Let (p, e1, e2) -> if varinpat x p then Let(p, sube e1, e2) else Let(p, sube e1, sube e2)
    | LetType ((x', y'), t, e') -> if x=x' then e else LetType((x', y'), subt t, sube e')
    | Type t -> Type (subt t)

and subtype v t : typ = 
    let subt = subtype v in
    let subi = subindx v in
    let (x, y) = v in
    match (t : typ) with
    | TVar (x', y') -> if x=x' then TVar v else t
    | AppType (t1, t2) -> AppType (subt t1, subt t2)
    | LUnit | Color -> t
    | Loli (t1, t2) -> Loli (subt t1, subt t2)
    | Tensor (t1, t2) -> Tensor (subt t1, subt t2)
    | LSum (t1, t2) -> LSum (subt t1, subt t2)
    | F t' -> F (subt t')
    | Evt t' -> Evt (subt t')
    | IUnit -> t
    | Arrow (t1, t2) -> Arrow (subt t1, subt t2)
    | Prod (t1, t2) -> Prod (subt t1, subt t2)
    | ISum (t1, t2) -> ISum (subt t1, subt t2)
    | G t' -> G (subt t')
    | IndxT _ -> t
    | At (t', i) -> At (subt t', subi i)
    | Univ ((x', y'), it, t') -> if x=x' then t else Univ((x', y'), it, subt t')
    | Exist ((x', y'), it, t') -> if x=x' then t else Exist((x', y'), it, subt t')
    | Widget i -> Widget (subi i)
    | Prefix (i1, i2) -> Prefix ((subi i1), (subi i2))
    | Num | Char | String | Star -> t

and subindx v i =
    let (x, y) = v in 
    match i with
    | IVar (x', y') -> if x=x' then IVar v else i
    | Time _ | Id _ -> i

and subpat v (p: pat) =
    let subp = subpat v in 
    let subt = subtype v in
    let (x, y) = v in 
    match p with
    | PUnit -> p
    | PWildcard -> p
    | PAt p' -> PAt (subp p')
    | PF p' -> PF (subp p')
    | PPack (i, p') -> PPack (i, (subp p'))
    | PPair (p1, p2) -> PPair (subp p1, subp p2)
    | PAtPair (p1, p2) -> PAtPair (subp p1, subp p2)
    | PVar (x', y') -> if x=x' then PVar v else p
    | PAnnot (p', t) -> PAnnot (subp p', subt t)


let rec alphaExpr e : expr t =
    match e with
    | EUnit -> return e
    | Var (x, y) -> if y="" then raise (UnboundVariable x) else return e
    | TypedVar _  -> raise (UnexpectedError __LOC__)
    | Lambda((x, y), e) -> if y<>"" then raise (UnexpectedError __LOC__) else
        let* s = getNewBind in 
        let newbind = (x, s) in
        let* e' = alphaExpr (subexpr newbind e) in 
        return (Lambda(newbind, e'))
    | LetFix((f, f'), t, (x, y), e1, e2) -> if f'<>"" || y<>"" then raise (UnexpectedError __LOC__)  else
        let* v1 = getNewBind in
        let* v2 = getNewBind in
        let* e1' = alphaExpr (subexpr (x, v2) (subexpr (f, v1) e1)) in
        let* e2' = alphaExpr (subexpr (f, v1) e2) in
        let* t' = alphaTyp t in 
        return (LetFix((f, v1), t', (x, v2), e1', e2'))
    | App (e1, e2) ->
        let* e1' = alphaExpr e1 in
        let* e2' = alphaExpr e2 in
        return (App(e1', e2'))
    | Pair (e1, e2) ->
        let* e1' = alphaExpr e1 in
        let* e2' = alphaExpr e2 in 
        return (Pair(e1', e2'))
    | AtUnpair _ -> failwith "WHYYYY"
    | Annot(e1, t) ->
        let* e1' = alphaExpr e1 in
        let* t' = alphaTyp t in
        return (Annot(e1', t'))
    | L e1 ->
        let* e1' = alphaExpr e1 in
        return (L e1')
    | R e1 ->
        let* e1' = alphaExpr e1 in
        return (R e1')
    | Case (e', p1, e1, p2, e2) ->
        let* e'' = alphaExpr e' in
        let* p1', binds1 = bindpat p1 in
        let* e1' = alphaExpr (List.fold_right subexpr binds1 e1) in 
        let* p2', binds2 = bindpat p2 in
        let* e2' = alphaExpr (List.fold_right subexpr binds2 e2) in
        return (Case (e'', p1', e1', p2', e2'))
    | Proj1 e1 ->
        let* e1' = alphaExpr e1 in 
        return (Proj1 e1')
    | Proj2 e1 ->
        let* e1' = alphaExpr e1 in 
        return (Proj2 e1')
    | EF e1 -> 
        let* e1' = alphaExpr e1 in 
        return (EF e1')
    | EG e1 -> 
        let* e1' = alphaExpr e1 in 
        return (EG e1')
    | Run e1 -> 
        let* e1' = alphaExpr e1 in 
        return (Run e1')
    | EEvt e1 -> 
        let* e1' = alphaExpr e1 in 
        return (EEvt e1')
    | LetEvt (p, e1, e2) ->
        let* p', binds = bindpat p in
        let* e1' = alphaExpr e1 in
        let* e2' = alphaExpr (List.fold_right subexpr binds e2) in
        return (LetEvt (p', e1', e2'))
    | Select (bi, br) ->
        let* bi', binds = (elevateT (List.map (
            fun ((x, y), e1) -> 
                if y<>"" then raise (UnexpectedError __LOC__) else
                let* s = getNewBind in
                let* e1' = alphaExpr e1
                in return (((x, s), e1'), (x, s))) bi)) >> (fun pl -> return (List.split pl)) in
        let* br' = elevateT (List.map (
            fun ((x, y), e1) -> 
                if y<>"" then raise (UnexpectedError __LOC__) else
                let s = List.assoc x binds in
                let* e1' = alphaExpr (List.fold_right subexpr binds e1)
                in return ((x, s), e1')) br) in
        return (Select(bi', br'))
    | EAt e1 -> 
        let* e1' = alphaExpr e1 in 
        return (EAt e1')
    | LambdaIndx((x, y), e) -> if y<>"" then raise (UnexpectedError __LOC__)  else
        let* s = getNewBind in 
        let newbind = (x, s) in
        let* e' = alphaExpr (subexpr newbind e) in 
        return (LambdaIndx(newbind, e'))
    | AppIndx _ -> raise( UnexpectedError __LOC__ )
    | Pack(i, e1) ->
        let* e1' = alphaExpr e1 in 
        return (Pack (i, e1'))
    | Indx i -> return e
    | Extern ((x, y), t, str, e1) -> if y<>"" then raise (UnexpectedError __LOC__)  else
        let* t' = alphaTyp t in
        let* s = getNewBind in
        let* e1' = alphaExpr (subexpr (x, s) e1) in
        return (Extern((x, s), t', str, e1'))
    | Out e1 -> 
        let* e1' = alphaExpr e1 in 
        return (Out e1')
    | Into e1 -> 
        let* e1' = alphaExpr e1 in 
        return (Into e1')
    | ENum _ | EString _ | EChar _ -> return e
    | Let (p, e1, e2) ->
        let* p', binds = bindpat p in
        let* e1' = alphaExpr e1 in
        let* e2' = alphaExpr (List.fold_right subexpr binds e2) in
        return (Let (p', e1', e2'))
    | LetType ((x, y), t, e1) -> if y<>"" then raise (UnexpectedError __LOC__)  else
        let* s = getNewBind in
        let* t' = alphaTyp (subtype (x, s) t) in
        let* e1' = alphaExpr (subexpr (x, s) e1) in
        return (LetType ((x, s), t', e1'))
    | Type t ->
        let* t' = alphaTyp t in
        return (Type t')

and alphaTyp t : typ t =
    match t with
    | Star -> return Star
    | TVar (x, y) -> if y="" then raise (UnexpectedError __LOC__)  else return t
    | AppType (t1, t2) ->
        let* t1' = alphaTyp t1 in
        let* t2' = alphaTyp t2 in
        return (AppType(t1, t2))
    | LUnit | Color -> return t
    | Loli (t1, t2) -> 
        let* t1' = alphaTyp t1 in
        let* t2' = alphaTyp t2 in
        return (Loli(t1, t2))
    | Tensor (t1, t2) -> 
        let* t1' = alphaTyp t1 in
        let* t2' = alphaTyp t2 in
        return (Tensor(t1, t2))
    | LSum (t1, t2) -> 
        let* t1' = alphaTyp t1 in
        let* t2' = alphaTyp t2 in
        return (LSum(t1, t2))
    | F t1 -> 
        let* t1' = alphaTyp t1 in
        return (F t1')
    | Evt t1 -> 
        let* t1' = alphaTyp t1 in
        return (Evt t1')
    | IUnit -> return t
    | Arrow (t1, t2) -> 
        let* t1' = alphaTyp t1 in
        let* t2' = alphaTyp t2 in
        return (Arrow(t1, t2))
    | Prod (t1, t2) -> 
        let* t1' = alphaTyp t1 in
        let* t2' = alphaTyp t2 in
        return (Prod(t1, t2))
    | ISum (t1, t2) -> 
        let* t1' = alphaTyp t1 in
        let* t2' = alphaTyp t2 in
        return (ISum(t1, t2))
    | G t1 -> 
        let* t1' = alphaTyp t1 in
        return (G t1')
    | IndxT _ -> return t
    | At (t1, i) -> 
        let* t1' = alphaTyp t1 in
        return (At(t1', i))
    | Univ ((x, y), it, t1) -> if y<>"" then raise (UnexpectedError __LOC__) else
        let* s = getNewBind in
        let* t1' = alphaTyp (subtype (x, s) t1) in
        return (Univ ((x, s), it, t1'))
    | Exist ((x, y), it, t1) -> if y<>"" then raise (UnexpectedError __LOC__ )else
        let* s = getNewBind in
        let* t1' = alphaTyp (subtype (x, s) t1) in
        return (Exist ((x, s), it, t1'))
    | Widget _ | Prefix (_, _) | Num | Char | String -> return t

