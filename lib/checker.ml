open Ast
open Plss
open Ctx
open Utils

let withvar: state -> 'a t -> 'a t = fun (x: state) -> fun (m: 'a t) ->
                                    let* ctx = get in print_endline (fstring "Withvar on %s" (printctx (x::ctx)));
                                    let* r = ((set (x::ctx)) >> m) in
                                    let* ctx' = get in
                                    let* s = lookup x.var in
                                    match s.used with
                                    | Inf | Used | Ext -> set (rm ctx' s) >> return r
                                    | Fresh -> error (fstring "Unused linear variable %s" x.var)

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
                                                          | Inf | Used | Ext -> checker xs (rm c s)
                                                          | Fresh -> error (fstring "Unused linear variable %s" s.var)
                                           in checker xs ctx'

let empty: ctx -> unit t = fun ctx ->
    match List.find_opt (fun s -> s.used=Fresh && use s) ctx with
    | Some s -> error (fstring "Unused variable %s in linear context" s.var)
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

let rec sub: var -> indx -> typ -> typ = fun x -> fun s -> fun t ->
    let subber = sub x s in
    match t with
    | TVar x -> TVar x
    | LUnit -> LUnit
    | Color -> Color
    | Loli (x, y) -> Loli (subber x, subber y)
    | Tensor (x, y) -> Tensor (subber x, subber y)
    | LSum (x, y) -> LSum (subber x, subber y)
    | F x -> F (subber x)
    | Evt x -> Evt (subber x)
    | IUnit -> IUnit
    | Arrow (x, y) -> Arrow (subber x, subber y)
    | Prod (x, y) -> Prod (subber x, subber y)
    | ISum (x, y) -> ISum (subber x, subber y)
    | G x -> G (subber x)
    | IndxT x -> IndxT x
    | At (t', IVar y) when x=y -> At (t', s)
    | At (x, y) -> At (subber x, y)
    | Univ (x, y, z) -> Univ (x, y, subber z)
    | Exist (x, y, z) -> Exist (x, y, subber z)
    | Widget (IVar i) when x=i -> Widget s
    | Widget i -> Widget i
    | Prefix ((IVar i), t) when x=i -> Prefix (s, t)
    | Prefix (i, (IVar t)) when x=t -> Prefix (i, s)
    | Prefix (i, t) -> Prefix (i, t)

let rec check (e: expr) (t: typ) (ent: ent) : unit t = print_endline (fstring "Checking %s against %s in %s" (printexpr e) (printtype t) (printent ent));
    match e, t, ent with
    | Indx(Time _), IndxT TTime, Ind -> return ()
    | Indx(Id _), IndxT TId, Ind -> return ()
    | Indx(IVar x), IndxT _, Ind -> let* s = lookup x in if s.typ = t then return () else raise UnexpectedError
    | Lambda (x, e'), Loli (t1, t2), Lin -> withvar (fresh x t1) (check e' t2 Lin)
    | Lambda (x, e'), Arrow (t1, t2), Int -> withvar (int x t1) (check e' t2 Int)
    | Pair (e1, e2), Tensor (t1, t2), Lin -> check e1 t1 Lin >> check e2 t2 Lin
    | Pair (e1, e2), Prod (t1, t2), Int -> check e1 t1 Int >> check e2 t2 Int
    | Unpair (x1, x2, e1, e2), _, Lin -> let* t1, t2 = infer e1 Lin >>> plsTensor in
                                    withvars ([fresh x1 t1; fresh x2 t2]) (check e2 t Lin)
    | L(e'), LSum(t1, t2), Lin -> check e' t1 Lin
    | R(e'), LSum(t1, t2), Lin -> check e' t2 Lin
    | L(e'), ISum(t1, t2), Int -> check e' t1 Int
    | R(e'), ISum(t1, t2), Int -> check e' t2 Int
    | Case (e', x1, e1, x2, e2), _ , Lin -> let* t1, t2 = infer e' Lin >>> plsLSum in
                                            let* ctx = get in
                                            let* ctx1 = withvar (fresh x1 t1) (check e1 t Lin) >> get in
                                            let* ctx2 = set ctx >> withvar (fresh x2 t2) (check e2 t Lin) >> get in
                                            same ctx1 ctx2
                                            (* if same ctx1 ctx2 then return () (*make same also monadic and make it error with a diff*)
                                                                else error (fstring "Different resulting contexts in linear case statement %s:\n%s\n%s" (printexpr e) (printctx ctx1) (printctx ctx2))                                        *)
    | Case (e', x1, e1, x2, e2), _ , Int -> let* t1, t2 = infer e' Int >>> plsISum in
                                            let* ctx = get in
                                            withvar (int x1 t1) (check e1 t Int) >> set ctx >> (*is this necessary?*)
                                            withvar (int x2 t2) (check e2 t Int)
    | LetF (x, e1, e2), _, Lin -> let* t' = infer e1 Lin >>> plsF in
                                  withvar (int x t') (check e2 t Lin)
    | EG(e'), G(t'), Int -> nolin (check e' t' Lin)
    | EEvt(e'), Evt(t'), Lin -> check e' t' Lin
    | LetEvt(x, e1, e2), Evt(_), Lin -> let* t1 = infer e1 Lin >>> plsEvt in
                                             nolin (withvar (fresh x t1) (check e2 t Lin))
    | Let(x, e1, e2), _, ent -> let* t' = infer e1 ent in 
                                let s = (match ent with
                                        | Lin -> fresh x t'
                                        | Int -> int x t'
                                        | Ind -> failwith "TODO: error not allowed") in
                                withvar s (check e2 t ent)
    | LetUnit(e1, e2), _, Lin -> check e1 LUnit Lin >> check e2 t Lin
    | LetFix(f, t', x, e1, e2), _, Lin -> let* a, b = plsLoli t' in 
                                          withonly [(fresh f t'); (fresh x a)] (check e1 b Lin) >> withvar (fresh f t') (check e2 t Lin)
    | LetFix(f, t', x, e1, e2), _, Int -> let* a, b = plsArrow t' in 
                                          withonly [(int f t'); (int x a)] (check e1 b Int) >> withvar (int f t') (check e2 t Int)
    | Select(x1, x2, e1, e2, e1', e2'), Evt(t'), Lin -> let* t1 = infer e1 Lin >>> plsEvt in
                                                        let* t2 = infer e2 Lin >>> plsEvt in
                                                        nolin ( let* ctx = get in
                                                                let* ctx1 = withvars ([fresh x1 t1; fresh x2 (Evt(t2))]) (check e1' t Lin) >> get in
                                                                let* ctx2 = set ctx >> withvars ([fresh x1 (Evt(t1)); fresh x2 t2]) (check e2' t Lin) >> get in
                                                                same ctx1 ctx2)
                                                                (* if same ctx1 ctx2 then return ()
                                                                                else error (fstring "Different resulting contexts in select statement %s" (printexpr e)))                                                         *)
    | EAt(e')(*might want to add time to expr but not necessary*), At(t', i), Lin -> check (Indx i) (IndxT TTime) Ind >> delay i (check e' t' Lin)
    | LambdaIndx(i, e'), Univ(ti, it, t'), Lin  when i=ti-> withvar (int i (IndxT it)) (check e' t' Lin) (*if diff, gen new name*)
    | LetAt(x, e1, e2), _, Lin -> let* t', tau = infer e1 Lin >>> plsAt in
                                  withvar (delayed x t' tau) (check e2 t Lin)
    | Pack(i, e'), Exist(ti, it, t'), Lin -> check (Indx i) (IndxT it) Ind >> check e' (sub ti i t') Lin
    | LetPack(x1, x2, e1, e2), _, Lin -> let* x, it, t' = infer e1 Lin >>> plsExist in
                                         if not (x = x1) then error (fstring "Index name mismatch %s and %s in unpacking of %s" x x1 (printexpr e1)) else
                                         withvars [int x1 (IndxT it); fresh x2 t'] (check e2 t Lin)
    | Extern(f, t, s, e'), t', ent -> withvar (ext f t) (check e' t' ent)
    | _, _, _ -> let* t' = infer e ent ~attempt:t in
                 if t=t' then return ()
                         else error (fstring "Can't type check %s with %s in a %s context" (printexpr e) (printtype t) (printent ent))
and infer ?attempt (e: expr) (ent: ent) : typ t = print_endline (fstring "Infering %s in %s" (printexpr e) (printent ent)); let* res = 
    (match e, ent with 
    | Var x, _ -> let* s = lookup_update x in (
                      match s.used with
                      | Ext -> return s.typ
                      | Fresh when ent=Lin -> return s.typ
                      | Inf when ent=Int -> return s.typ
                      | Used when ent=Lin -> error (fstring "Multiple usages of variable %s in linear context" x)
                      | Inf -> error (fstring "Improper usage of intuitionistic variable %s in linear context" x)
                      | _ -> error (fstring "Improper usage of linear variable %s in intuitionistic context" x)
                  )
    | EUnit, Int -> return IUnit
    | EUnit, Lin -> return LUnit
    | Proj1(e'), Int -> let* t1, t2 = infer e' Int >>> plsProd in return t1
    | Proj2(e'), Int -> let* t1, t2 = infer e' Int >>> plsProd in return t2
    | Annot (e', t), _ -> check e' t ent >> return t
    | App (e1, e2), Int -> let* t1, t2 = infer e1 ent >>> plsArrow in
                           check e2 t1 ent >> return t2
    (* | App (e', Indx(s)), Lin -> let* i, it, t' = infer e' Lin >>> plsUniv in
                                check (Indx s) (IndxT it) Ind >> return (sub i s t') *)
    | App (e1, Var(x)), Lin -> let* t = infer e1 Lin in
                           (match t with
                           | Loli (t1, t2) -> check (Var x) t1 Lin >> return t2
                           | Univ (i, it, t') -> check (Indx(IVar(x))) (IndxT it) Ind >> return (sub i (IVar(x)) t')
                           | _ -> error (unexpectedform "α⊸β or ∀i.α" t))
    | App (e1, e2), Lin -> let* t1, t2 = infer e1 Lin >>> plsLoli in
    check e2 t1 Lin >> return t2
    | Run(e'), Lin -> nolin (infer e' Int >>> plsG >>> return)
    | EF(e'), Lin -> nolin ( let* t' = infer e' Int in return (F t'))
    (* | AppIndx(e', s), Lin -> let* i, it, t' = infer e' Lin >>> plsUniv in
                             check (Indx s) (IndxT it) Ind >> return (sub i s t') *)
    | Extern(f, t, s, e'), ent -> withvar (ext f t) (infer e' ent)
    | Out(e'), Lin -> let* t' = infer e' Lin >>> plsEvt in
                      return (Exist("n", TTime, At(t', IVar("n"))))
    | Into(e'), Lin -> let* n, it, t' = infer e' Lin >>> plsExist in
                       (match it with
                       | TId -> error "Into can only be used with Time existentials, used with Id"
                       | TTime -> let* t'', n' = plsAt t' in
                                  let* n'' = plsIndxVar n' in
                                  if n=n'' then return (Evt(t''))
                                  else error (fstring "Inner @ type must be index by the same variable as the existential, expected type of the form (∃n:Time. α@n), got %s" (printtype t')))
    | _ -> match attempt with
           | None   -> error (fstring "Can't infer type of %s" (printexpr e))
           | Some t -> error (fstring "Can't check %s against %s" (printexpr e) (printtype t)))
    in print_endline (fstring "Infered %s as %s" (printexpr e) (printtype res)); return res
