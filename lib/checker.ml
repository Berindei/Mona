open Ast
open Plss
open Ctx
open Utils

let withvar: state -> 'a t -> 'a t = fun (x: state) -> fun (m: 'a t) ->
                                    let* ctx = get in (*print_endline (fstring "Withvar on %s" (printctx (x::ctx)));*)
                                    let* r = ((set (x::ctx)) >> m) in
                                    let* ctx' = get in
                                    let* s = lookup x.var in
                                    match s.used with
                                    | Inf | Used | Ext | Typ -> set (rm ctx' s) >> return r
                                    | Fresh -> error (fstring "Unused linear variable %s" (printvar x.var))

(*let rec withvars: state list -> 'a t -> 'a t = fun xs -> fun m ->
                                               match xs with
                                               | []    -> m
                                               | x::xs -> withvar x (withvars xs m)*)

let withvars: state list -> 'a t -> 'a t = fun xs -> fun m ->
                                           let* ctx = get in
                                           let* r = ((set (xs@ctx)) >> m) in
                                           let* ctx' = get in
                                           let rec checker l c=
                                               match l with
                                               | []    -> set c >> return r
                                               | x::xs -> let* s = lookup x.var in
                                                          match s.used with
                                                          | Inf | Used | Ext | Typ -> checker xs (rm c s)
                                                          | Fresh -> error (fstring "Unused linear variable %s" (printvar s.var))
                                           in checker xs ctx'

let empty: ctx -> unit t = fun ctx ->
    match List.find_opt (fun s -> s.used=Fresh && use s) ctx with
    | Some s -> error (fstring "Unused variable %s in linear context" (printvar s.var))
    | None -> return ()

let lim: ctx -> ctx t = fun ctx ->
    return (filtermap ctx (fun s -> {s with ignore=Ignore}) (fun s -> s.used=Fresh || s.used=Used)) (*(List.map (fun s -> if s.used!=Inf then {s with incl=Ignore} else s) ctx)*)

let nolin: 'a t -> 'a t = fun m ->
                          let* ctx = get in
                          let* r = lim ctx >>> set >> m in
                          get >>> empty >> set ctx >> return r

let withonly: state list -> 'a t -> 'a t = fun sl -> fun m ->
                                           let* ctx = get in
                                           let* r = lim ctx >>> set >> withvars sl m in
                                           get >>> empty >> set ctx >> return r

(*figure out delay somehow, would need to change at somehow*)
(*Might work now idk*)

let delay: indx -> 'a t -> 'a t = fun t -> fun m ->
                                  let* ctx = get in
                                  let ctx' = List.map (fun s -> {s with delay = (if (not (islins s) || actualAt s = t) then Use else Ignore)::s.delay}) ctx in
                                  let* r = set ctx' >> m in
                                  let* ctx'' = get in
                                  set (List.map (fun s -> {s with delay = (List.tl s.delay)}) ctx'') >> return r

(* let timed: ctx -> time -> ctx t = fun ctx -> fun t ->
    return (filtermap ctx (fun s -> {s with incl=Ignore}) (fun s -> (s.used=Fresh || s.used=Used) && s.delay!=t)) *)

type ent = Lin | Int | Ind

let printent e = match e with Lin->"linear" | Int->"intuitionistic" | Ind->"index"

let rec getPatVar p t ent= let* t = getNormal t in 
    if ent = Lin then 
        match p, t with
        | PVar x, t -> return [fresh x t]
        | PUnit, LUnit -> return []
        | PPair(p1, p2), Tensor(t1, t2) -> let* l1 = getPatVar p1 t1 Lin in
                                           let* l2 = getPatVar p2 t2 Lin in
                                           return (l1 @ l2)
        | PAtPair(p1, p2), At(Tensor(t1, t2), i) -> let* l1 = getPatVar p1 (At(t1, i)) Lin in
                                                    let* l2 = getPatVar p2 (At(t2, i)) Lin in
                                                    return (l1 @ l2)
        | PF p, F t -> getPatVar p t Int
        | PAt (PVar x), At(t, i) -> return [(delayed x t i)]
        | PAt (PPair(p1, p2)), At(Tensor(t1, t2), i) -> let* l1 = getPatVar p1 (At(t1, i)) Lin in
                                                        let* l2 = getPatVar p2 (At(t2, i)) Lin in
                                                        return (l1 @ l2)
        | PPack(i, p), Exist(j, jt, t) -> let* l = getPatVar p (subIndx j (IVar i) t) Lin in
                                          return ((int i (IndxT jt))::l)
        | PAnnot(p, t'), t -> if t=t' then getPatVar p t Lin
                              else error (fstring "Type mismatch in pattern %s with %s" (printpat p) (printtype t))
        | _, _ -> error (fstring "Can't pattern match %s with %s" (printpat p) (printtype t))
    else
        match p, t with
        | PVar x, t -> return [int x t]
        | PPair(p1, p2), Prod(t1, t2) -> let* l1 = getPatVar p1 t1 Int in
                                         let* l2 = getPatVar p2 t2 Int in
                                         return (l1 @ l2)
        | PUnit, IUnit -> return []
        | PWildcard, _ -> return []
        | PAnnot(p, t'), _ -> if t=t' then getPatVar p t Int
                              else error (fstring "Type mismatch in pattern %s with %s" (printpat p) (printtype t))
        | _, _ -> error (fstring "Can't pattern match %s with %s" (printpat p) (printtype t))
    
let rec elevateT (l: 'a t list) : 'a list t =
    match l with
    | []      -> return []
    | x :: xs -> let* x' = x in 
                 let* xs' = elevateT xs in (return (x'::xs'))

let rec selectVarList l x =
    match l with
    | [] -> []
    | (y, t) :: ys when y=x -> (fresh y t) :: (selectVarList ys x)
    | (y, t) :: ys          -> (fresh y (Evt t)) :: (selectVarList ys x)


let rec checkNewType (t: typ) : unit t = (*needs fixing i think*)
    match t with
    | TVar x -> let* s = lookup x in
                (match s.used with
                | Typ -> return ()
                | Inf when s.typ = IndxT TType -> return ()
                | _ -> error (fstring "Expression variable in type definition, %s" (printstate s) ))
    | LUnit | Color | IUnit | Num | Char | String -> return ()
    | F t | Evt t | G t  -> checkNewType t
    | Loli (t1, t2) | Tensor (t1, t2) | LSum (t1, t2) | Arrow (t1, t2) | Prod (t1, t2) | ISum (t1, t2) | AppType (t1, t2) -> checkNewType t1 >> checkNewType t2
    | At (t, i) -> let* _ = check (Indx i) (IndxT TTime) Ind in checkNewType t
    | Widget i -> let* _ = check (Indx i) (IndxT TId) Ind in return ()
    | Prefix (i, t) -> let* _ = check (Indx i) (IndxT TId) Ind in let* _ = check (Indx i) (IndxT TTime) Ind in return ()
    | Univ(x, t1, t2) | Exist(x, t1, t2) -> withvar (int x (IndxT t1)) (checkNewType t2)
    | IndxT _ -> failwith "new type type checking fail"
    | Star -> raise (UnexpectedError __LOC__)
    (* | _ -> return () *)

and check (e: expr) (t: typ) (ent: ent) : expr t = print_endline (fstring "Checking %s against %s in %s" (printexpr e) (printtype t) (printent ent));
    let* t = getNormal t in
    match e, t, ent with
    | Var x, IndxT TType, ent -> let* ctx = get in print_endline (printctx ctx); let* s = lookup x in if s.used = Typ then if s.typ = Star then return (Type (TVar x)) else return (Type s.typ) else error ""
    | Type t', IndxT TType, ent -> let* () = checkNewType t' in return (Type t')
    | Indx(Time _), IndxT TTime, Ind -> return e
    | Indx(Id _), IndxT TId, Ind -> return e
    | Indx(IVar x), IndxT _, Ind -> let* s = lookup x in if s.typ = t then return e else raise (UnexpectedError __LOC__) 
    | Let(p, e1, e2), t , ent -> let* t1, ef1 = infer e1 ent in 
                                 let* l = getPatVar p t1 ent in
                                 let* ef2 = withvars l (check e2 t ent) in
                                 return (Let(p, ef1, ef2))
    | LetType(x, t', e'), t, ent -> withvar (vartyp x t') (checkNewType t' >> check e' t ent)
    | Lambda (x, e'), Loli (t1, t2), Lin -> let* ef = withvar (fresh x t1) (check e' t2 Lin) in return(Lambda(x, ef))
    | Lambda (x, e'), Arrow (t1, t2), Int -> let* ef = withvar (int x t1) (check e' t2 Int) in return(Lambda(x, ef))
    | Pair (e1, e2), Tensor (t1, t2), Lin -> let* ef1 = check e1 t1 Lin in let* ef2 = check e2 t2 Lin in return(Pair(ef1, ef2))
    | Pair (e1, e2), Prod (t1, t2), Int -> let* ef1 = check e1 t1 Int in let* ef2 = check e2 t2 Int in return(Pair(ef1, ef2))
    (* | Unpair (x1, x2, e1, e2), _, Lin -> let* t1, t2, ef1 = infer e1 Lin >>> plsTensor in
                                         let* ef2 = withvars ([fresh x1 t1; fresh x2 t2]) (check e2 t Lin) in return(Unpair(x1, x2, ef1, ef2)) *)
    | L(e'), LSum(t1, t2), Lin -> let* ef = check e' t1 Lin in return(L ef)
    | R(e'), LSum(t1, t2), Lin -> let* ef = check e' t2 Lin in return(R ef)
    | L(e'), ISum(t1, t2), Int -> let* ef = check e' t1 Int in return(L ef)
    | R(e'), ISum(t1, t2), Int -> let* ef = check e' t2 Int in return(R ef)
    | Case (e', p1, e1, p2, e2), _ , Lin -> let* t1, t2, ef' = infer e' Lin >>> plsLSum in
                                            let* ctx = get in
                                            let* vl1 = getPatVar p1 t1 Lin in
                                            let* vl2 = getPatVar p2 t2 Lin in
                                            let* ef1 = withvars vl1 (check e1 t Lin) in
                                            let* ctx1 = get in
                                            let* ef2 = set ctx >> withvars vl2 (check e2 t Lin) in
                                            let* ctx2 = get in
                                            same ctx1 ctx2 >> return(Case(ef', p1, ef1, p2, ef2))
                                            (* if same ctx1 ctx2 then return () (*make same also monadic and make it error with a diff*)
                                                                else error (fstring "Different resulting contexts in linear case statement %s:\n%s\n%s" (printexpr e) (printctx ctx1) (printctx ctx2))                                        *)
    | Case (e', p1, e1, p2, e2), _ , Int -> let* t1, t2, ef' = infer e' Int >>> plsISum in
                                            let* ctx = get in
                                            let* vl1 = getPatVar p1 t1 Int in
                                            let* vl2 = getPatVar p2 t2 Int in
                                            let* ef1 = withvars vl1 (check e1 t Int) in
                                            let* ef2 = set ctx >> (*is this necessary?*) withvars vl2 (check e2 t Int)
                                            in return(Case(ef', p1, ef1, p2, ef2))
    (* | LetF (x, e1, e2), _, Lin -> let* t', ef1 = infer e1 Lin >>> plsF in
                                  let* ef2 = withvar (int x t') (check e2 t Lin) in
                                  return(LetF(x, ef1, ef2)) *)
    | EG(e'), G(t'), Int -> let* ef' = nolin (check e' t' Lin) in return (EG ef')
    | EF(e'), F(t'), Lin -> nolin ( let* ef' = check e' t' Int in return (EF(ef')))
    | EEvt(e'), Evt(t'), Lin -> let* ef' = check e' t' Lin in return (EEvt ef')
    | LetEvt(p, e1, e2), Evt(_), Lin -> let* t1, ef1 = infer e1 Lin >>> plsEvt in
                                        let* l = getPatVar p t1 Lin in
                                        let* ef2 = nolin (withvars l (check e2 t Lin)) in
                                        return (LetEvt(p, ef1, ef2))
    (* | Let(x, e1, e2), _, ent -> let* t', ef1 = infer e1 ent in 
                                let s = (match ent with
                                        | Lin -> fresh x t'
                                        | Int -> int x t'
                                        | Ind -> failwith "TODO: error not allowed") in
                                let* ef2 = withvar s (check e2 t ent) in
                                return(Let(x, ef1, ef2)) *)
    (* | LetUnit(e1, e2), _, Lin -> let* ef1 = check e1 LUnit Lin in
                                 let* ef2 = check e2 t Lin in
                                 return(LetUnit(ef1, ef2)) *)
    | LetFix(f, t', x, e1, e2), _, Lin -> (match t' with
                                          | Loli(a, b) -> let* ef1 = withvar (int f (G t')) (withonly [fresh x a] (check e1 b Lin)) in
                                                          let* ef2 = withvar (int f (G t')) (check e2 t Lin) in
                                                          return (LetFix(f, t', x, ef1, ef2))
                                          | Univ(i, it, b) -> (match it with
                                                              | TType -> let* ef1 = withvars [(int f (G t')); (vartyp x Star)] (nolin (check e1 (subType i (TVar x) b) ent)) in
                                                                         let* ef2 = withvar (int f (G t')) (check e2 t Lin) in 
                                                                         return (LetFix(f, t', x, ef1, ef2))
                                                              | _ -> let* ef1 = withvars [(int f (G t')); (int x (IndxT it))] (nolin (check e1 (subIndx i (IVar x) b) Lin)) in
                                                                     let* ef2 = withvar (int f (G t')) (check e2 t Lin) in
                                                                     return (LetFix(f, t', x, ef1, ef2))
                                                              )
                                          (* | Univ(i, it, b) -> let* ef1 = withvars [(int f (G t')); (int i (IndxT it))] (nolin (check e1 b Lin)) in
                                                              let* ef2 = withvar (int f (G t')) (check e2 t Lin) in
                                                              return (LetFix(f, t', x, ef1, ef2)) *)
                                          | _ -> failwith "AAAAAAAAAAA")
                                          (* let* a, b, _ = plsLoli (t', EUnit) in 
                                          let* ef1 = withvar (fresh f (G t')) (withonly [(fresh x a)] (check e1 b Lin)) in
                                          let* ef2 = withvar (fresh f t') (check e2 t Lin) in
                                          return(LetFix(f, t', x, ef1, ef2)) *)
    | LetFix(f, t', x, e1, e2), _, Int -> (match t' with 
                                          | Arrow (a, b) -> let* ef1 = withvars [(int f t'); (int x a)] (check e1 b Int) in
                                                            let* ef2 = withvar (int f t') (check e2 t Int) in
                                                            return(LetFix(f, t', x, e1, e2))
                                          | Univ(i, it, b) -> (match it with
                                                              | TType -> let* ef1 = withvars [(int f t'); (vartyp x Star)] ((check e1 (subType i (TVar x) b) ent)) in
                                                                         let* ef2 = withvar (int f t') (check e2 t ent) in 
                                                                         return (LetFix(f, t', x, ef1, ef2))
                                                              | _ -> let* ef1 = withvars [(int f (G t')); (int x (IndxT it))] (nolin (check e1 (subIndx i (IVar x) b) ent)) in
                                                                     let* ef2 = withvar (int f (G t')) (check e2 t ent) in
                                                                     return (LetFix(f, t', x, ef1, ef2))
                                                              )
                                          (* | Univ(i, it, b) -> let* ef1 = withvars [(int f t'); (int x (IndxT it))] (check e1 b Int) in
                                                              let* ef2 = withvar (int f t') (check e2 t Int) in
                                                              return(LetFix(f, t', x, e1, e2)) *)
                                          | _ -> failwith "AAAAAAAAAA")
    | Select (l1, l2), Evt t', Lin -> let l' = List.map (fun (x, e') -> let* t1, ef1 = infer e' Lin >>> plsEvt in (return ((x, t1), (x, ef1)))) l1 in
                                      let* l3, lf1 = (let* l'' = elevateT l' in return (List.split l'')) in
                                      let* lf2 = nolin(
                                          let* ctx = get in
                                          let l' = List.map (fun (x, e') -> 
                                                let vl = selectVarList l3 x in
                                                let* ef = withvars vl (check e' t Lin) in
                                                let* ctx' = get in
                                                return ((x, ef), ctx')                 
                                          ) l2 in
                                          let* efs, ctxs = (let* l'' = elevateT l' in return (List.split l'')) in
                                          allsame ctxs >> return efs
                                      ) in return (Select(lf1, lf2))
    (* | Select(x1, x2, e1, e2, e1', e2'), Evt(t'), Lin -> let* t1, ef1 = infer e1 Lin >>> plsEvt in
                                                        let* t2, ef2 = infer e2 Lin >>> plsEvt in
                                                        let* ef1', ef2' = nolin ( let* ctx = get in
                                                                                  let* ef1' = withvars ([fresh x1 t1; fresh x2 (Evt(t2))]) (check e1' t Lin) in
                                                                                  let* ctx1 = get in
                                                                                  let* ef2' = set ctx >> withvars ([fresh x1 (Evt(t1)); fresh x2 t2]) (check e2' t Lin) in
                                                                                  let* ctx2 = get in
                                                                                  same ctx1 ctx2 >> return(ef1', ef2')) in return(Select(x1, x2, ef1, ef2, ef1', ef2'))
                                                                (* if same ctx1 ctx2 then return ()
                                                                                else error (fstring "Different resulting contexts in select statement %s" (printexpr e)))                                                         *) *)
    | EAt(e')(*might want to add time to expr but not necessary*), At(t', i), Lin -> let* _ = check (Indx i) (IndxT TTime) Ind in
                                                                                     let* ef' = delay i (check e' t' Lin) in return (EAt ef')
    | AtUnpair(p1, p2, e1, e2), _, Lin -> let* t', ef1 = infer e1 Lin in
                                          let* l1 = getPatVar (PAtPair(p1, p2)) t' Lin in
                                          let* ef2 = withvars l1 (check e2 t Lin) in
                                          return (AtUnpair(p1, p2, ef1, ef2))
    | LambdaIndx(i, e'), Univ(ti, it, t'), ent ->
        (match it with
        | TType -> let* ef' = withvar (vartyp i Star) (check e' (subType ti (TVar i) t') ent) in return (LambdaIndx(i, ef'))
        | _ -> let* ef' = withvar (int i (IndxT it)) (check e' (subIndx ti (IVar i) t') ent) in return (LambdaIndx(i, ef'))
        )
    (* | LetAt(x, e1, e2), _, Lin -> let* t', tau, ef1 = infer e1 Lin >>> plsAt in
                                  let* ef2 = withvar (delayed x t' tau) (check e2 t Lin) in
                                  return (LetAt(x, ef1, ef2)) *)
    | Pack(i, e'), Exist(ti, it, t'), Lin -> let* _ = check (Indx i) (IndxT it) Ind in
                                             let* ef' = check e' (subIndx ti i t') Lin in
                                             return(Pack(i, ef'))
    (* | LetPack(x1, x2, e1, e2), _, Lin -> let* x, it, t', ef1 = infer e1 Lin >>> plsExist in
                                         let t'' = if (x = x1) then t'
                                                   else sub x (IVar x1) t'
                                         in
                                         let* ef2 = withvars [int x1 (IndxT it); fresh x2 t''] (check e2 t Lin) in
                                         return(LetPack(x1, x2, ef1, ef2)) *)
    | Extern(f, t, s, e'), t', ent -> let* ef' = withvar (ext f t) (check e' t' ent) in return(Extern(f, t, s, ef'))
    | _, _, _ -> let* t', ef = infer e ent ~attempt:t in let* t'' = getNormal t' in 
                 if t=t'' then return ef
                         else error (fstring "Can't type check %s with %s in a %s context, got %s" (printexpr e) (printtype t) (printent ent) (printtype t'))
and infer ?attempt (e: expr) (ent: ent) : (typ*expr) t = print_endline (fstring "Infering %s in %s" (printexpr e) (printent ent));let* res, ef = 
    (match e, ent with 
    | Var x, _ -> let* s = lookup_update x in let* t' = (
                      if not ((actualAt s) = (Time 0)) then error (fstring "Variable %s not available in the requested time" (printvar x)) else
                      match s.used with
                      | Ext -> return s.typ
                      | Fresh when ent=Lin -> return s.typ
                      | Inf when ent=Int -> return s.typ
                      | Used when ent=Lin -> error (fstring "Multiple usages of variable %s in linear context" (printvar x))
                      | Inf -> error (fstring "Improper usage of intuitionistic variable %s in linear context" (printvar x))
                      | _ -> error (fstring "Improper usage of linear variable %s in intuitionistic context" (printvar x))
                  ) in return (t', (TypedVar(x, t', s.at)))
    | EUnit, Int -> return (IUnit, EUnit)
    | EUnit, Lin -> return (LUnit, EUnit)
    | ENum n, Int -> return (Num, e)
    | EChar c, Int -> return (Char, e)
    | EString s, Int -> return (String, e)
    | Proj1(e'), Int -> let* t1, t2, ef' = infer e' Int >>> plsProd in return (t1, (Proj1 ef'))
    | Proj2(e'), Int -> let* t1, t2, ef' = infer e' Int >>> plsProd in return (t2, (Proj2 ef'))
    | Annot (e', t), _ -> let* ef' = check e' t ent in
                          return (t, (Annot(ef', t)))
    (* | App (e1, e2), Int -> let* t1, t2, ef1 = infer e1 ent >>> plsArrow in
                           let* ef2 = check e2 t1 ent in
                           return (t2, (App(ef1, ef2))) *)
    (* | App (e', Indx(s)), Lin -> let* i, it, t' = infer e' Lin >>> plsUniv in
                                check (Indx s) (IndxT it) Ind >> return (sub i s t') *)
    (* | App (e1, Var(x)), ent -> let* t, ef1 = infer e1 ent in
                           (match t with
                           | Arrow(t1, t2) -> let* ef = check (Var x) t1 Int in return (t2, App(ef1, ef))
                           | Loli (t1, t2) -> let* ef = check (Var x) t1 Lin in return (t2, (App(ef1, ef)))
                           | Univ (i, it, t') -> let* ef = check (Indx(IVar(x))) (IndxT it) Ind in return (subIndx i (IVar(x)) t', (App(ef1, ef)))
                           | _ -> error (unexpectedform "α⊸β or ∀i.α" t))
    | App (e1, e2), Lin -> let* t1, t2, ef1 = infer e1 Lin >>> plsLoli in
                           let* ef2 = check e2 t1 Lin in
                           return (t2, App(ef1, ef2)) *)
    | App (e1, e2), ent ->
        let* t, ef1 = infer e1 ent in
        (match t with
        | Arrow (t1, t2) | Loli (t1, t2) -> let* ef = check e2 t1 ent in return (t2, App(ef1, ef))
        | Univ (i, TType, t') ->
            let* ef2 = check e2 (IndxT TType) ent in
            (match ef2 with
            | Type t -> return (subType i t t', (App(ef1, ef2)))
            | _ -> raise (UnexpectedError __LOC__)
            )
        | Univ (i, it, t') -> 
            (match e2 with
            | Var x -> let* ef = check (Indx(IVar(x))) (IndxT it) Ind in return (subIndx i (IVar(x)) t', (App(ef1, ef)))
            | _ -> error ""
            )
        | _ -> error ""
        )
    | Run(e'), Lin -> let* t', ef' = nolin (infer e' Int >>> plsG >>> return) in return(t', Run(ef'))
    | EF(e'), Lin -> nolin ( let* t', ef' = infer e' Int in return ((F t'), EF(ef')))
    (* | AppIndx(e', s), Lin -> let* i, it, t' = infer e' Lin >>> plsUniv in
                             check (Indx s) (IndxT it) Ind >> return (sub i s t') *)
    | Extern(f, t, s, e'), ent -> let* t', ef' = withvar (ext f t) (infer e' ent) in return(t', (Extern(f, t, s, ef')))
    | Out(e'), Lin -> let* t', ef' = infer e' Lin >>> plsEvt in
                      return ((Exist(("n", "n"), TTime, At(t', IVar(("n", "n"))))), (Out ef'))
    | Into(e'), Lin -> let* n, it, t', ef' = infer e' Lin >>> plsExist in
                       (match it with
                       | TId -> error "Into can only be used with Time existentials, used with Id"
                       | TType -> error "Into can only be used with Time existentials, used with *"
                       | TTime -> let* t'', n', _ = plsAt (t', EUnit) in
                                  let* n'' = plsIndxVar n' in
                                  if n=n'' then return ((Evt(t'')), Into ef')
                                  else error (fstring "Inner @ type must be index by the same variable as the existential, expected type of the form (∃n:Time. α@n), got %s" (printtype t')))
    | Pair(e1, e2), ent -> let* t1, ef1 = infer e1 ent in
                           let* t2, ef2 = infer e2 ent in
                           (match ent with
                           | Int -> return (Prod(t1, t2), Pair(ef1, ef2))
                           | Lin -> return (Tensor(t1, t2), Pair(ef1, ef2))
                           | _ -> failwith "AAAAAAA")
    | LetType(x, t, e'), ent -> withvar (vartyp x t) (checkNewType t >> infer e' ent)
    | Let(p, e1, e2), ent -> let* t1, ef1 = infer e1 ent in
                             let* l = getPatVar p t1 ent in
                             let* t2, ef2 = withvars l (infer e2 ent) in
                             return (t2, Let(p, ef1, ef2))
    | LetFix(f, t', x, e1, e2), Lin -> (match t' with
                                        | Loli(a, b) -> let* ef1 = withvar (int f (G t')) (withonly [fresh x a] (check e1 b Lin)) in
                                                        let* tf, ef2 = withvar (int f (G t')) (infer e2 Lin) in
                                                        return (tf, LetFix(f, t', x, ef1, ef2))
                                        | Univ(i, it, b) -> (match it with
                                                            | TType -> let* ef1 = withvars [(int f (G t')); (vartyp x Star)] (nolin (check e1 (subType i (TVar x) b) ent)) in
                                                                       let* tf, ef2 = withvar (int f (G t')) (infer e2 Lin) in 
                                                                       return (tf, LetFix(f, t', x, ef1, ef2))
                                                            | _ -> let* ef1 = withvars [(int f (G t')); (int x (IndxT it))] (nolin (check e1 b Lin)) in
                                                                   let* tf, ef2 = withvar (int f (G t')) (infer e2 Lin) in
                                                                   return (tf, LetFix(f, t', x, ef1, ef2))
                                                            )
                             (* | Univ(i, it, b) -> let* ef1 = withvars [(int f (G t')); (int i (IndxT it))] (nolin (check e1 b Lin)) in
                                                 let* ef2 = withvar (int f (G t')) (check e2 t Lin) in
                                                 return (LetFix(f, t', x, ef1, ef2)) *)
                                        | _ -> failwith "AAAAAAAAAAA")
                             (* let* a, b, _ = plsLoli (t', EUnit) in 
                             let* ef1 = withvar (fresh f (G t')) (withonly [(fresh x a)] (check e1 b Lin)) in
                             let* ef2 = withvar (fresh f t') (check e2 t Lin) in
                             return(LetFix(f, t', x, ef1, ef2)) *)
    | LetFix(f, t', x, e1, e2), Int -> (match t' with 
                                        | Arrow (a, b) -> let* ef1 = withvars [(int f t'); (int x a)] (check e1 b Int) in
                                                          let* tf, ef2 = withvar (int f t') (infer e2 Int) in
                                                          return(tf, LetFix(f, t', x, e1, e2))
                                        | Univ(i, it, b) -> (match it with
                                                            | TType -> let* ef1 = withvars [(int f t'); (vartyp x Star)] ((check e1 (subType i (TVar x) b) ent)) in
                                                                       let* tf, ef2 = withvar (int f t') (infer e2 Lin) in 
                                                                       return (tf, LetFix(f, t', x, ef1, ef2))
                                                            | _ -> let* ef1 = withvars [(int f (G t')); (int x (IndxT it))] (nolin (check e1 b Lin)) in
                                                                   let* tf, ef2 = withvar (int f (G t')) (infer e2 Lin) in
                                                                   return (tf, LetFix(f, t', x, ef1, ef2))
                                                            )
                                        (* | Univ(i, it, b) -> let* ef1 = withvars [(int f t'); (int x (IndxT it))] (check e1 b Int) in
                                                            let* ef2 = withvar (int f t') (check e2 t Int) in
                                                            return(LetFix(f, t', x, e1, e2)) *)
                                        | _ -> failwith "AAAAAAAAAA")
    | _ -> match attempt with
           | None   -> error (fstring "Can't infer type of %s" (printexpr e))
           | Some t -> error (fstring "Can't check %s against %s" (printexpr e) (printtype t)))
    in let () = print_endline (fstring "Infered %s as %s" (printexpr e) (printtype res)) in return ((res, ef))