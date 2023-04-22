open Ast
open Utils

type usage = Used | Fresh | Inf | Ext | Typ
type flag = Use | Ignore

type state = {var: var; used: usage; typ: typ; ignore: flag; delay: flag list; at: indx}

let mkstate v u t i d a = {var=v; used=u; typ=t; ignore=i; delay=d; at=a}

let used v t :state= mkstate v Used t Use [Use] (Time 0)
let fresh v t = mkstate v Fresh t Use [Use] (Time 0)
let int v t = mkstate v Inf t Use [Use] (Time 0) (*includes indeces*)
let ext v t = mkstate v Ext t Use [Use] (Time 0)

let vartyp v t = mkstate v Typ t Use [Use] (Time 0)

let islins s = s.used = Fresh || s.used = Used
let islinu u = u=Fresh || u=Used

let delayed v t d = {(fresh v t) with at = d}

let ignore s = s.ignore = Ignore || List.exists (fun x -> x=Ignore) s.delay
let use s = s.ignore = Use && List.for_all (fun x -> x=Use) s.delay

let actualAt s = if List.length s.delay <= 1 then s.at else Time 0

type ctx = state list

let printusage u = match u with Fresh->"1"| Used->"0" | Inf->"∞" | Ext->"ex" | Typ ->"type"

let printstate s =
    let printinner =
        match s.used with
        | _ when s.at = Time 0 -> fstring "%s^%s: %s" (printvar s.var) (printusage s.used) (printtype s.typ)
        | Inf | Ext | Typ-> fstring "%s^%s: %s" (printvar s.var) (printusage s.used) (printtype s.typ)
        | Used | Fresh -> fstring "%s^%s: %s[%s]" (printvar s.var) (printusage s.used) (printtype s.typ) (printindx (actualAt s))
    in let i = printinner in
    match s.ignore, List.exists (fun x -> x=Ignore) s.delay with
    | Use, false -> i
    | Ignore, false -> fstring "#%s#" i
    | Use, true -> fstring "@%s@" i
    | Ignore, true -> fstring "#@%s@#" i

let printctx c =
    let rec loop c = 
        match c with
        | []    -> ""
        | [x]     -> printstate x
        | x::xs -> fstring "%s; %s" (printstate x) (loop xs)
    in fstring "Γ = [%s]" (loop c)

type errorinfo = string

type 'a result = Value of 'a | Error of errorinfo

type 'a t = ctx -> ('a * ctx) result

let return (x: 'a) : 'a t = fun (state: ctx) -> Value(x, state)

let error (x: errorinfo) : 'a t = fun (_: ctx) -> Error x

let bind (x: 'a t) (f: 'a -> 'b t) : 'b t = fun (state: ctx) ->
    match x state with
    | Value (y, s) -> f y s
    | Error e -> Error e
    
let (>>=) = bind

let (>>) f1 f2 = f1 >>= (fun () -> f2)

let (>>>) f1 f2 = f1 >>= (fun x -> f2 x)

let (let*) = bind

let get: ctx t = fun (ctx: ctx) -> Value(ctx, ctx)

let set: ctx -> unit t = fun (nctx: ctx) -> fun (ctx: ctx) -> Value ((), nctx)

let rec lookup: var -> state t = fun (x: var) -> fun (ctx: ctx) ->
    match ctx with
    | []                     -> Error (fstring "Variable %s not in context" (printvar x))
    | y :: ys when x = y.var && ignore y -> Error (fstring "Variable %s not available in context" (printvar x))
    | y :: ys when x = y.var -> Value (y, y :: ys)
    | y :: ys                -> (lookup x >>= (fun s -> fun ctx' -> Value(s, y :: ctx'))) ys

let rec lookup_update: var -> state t = fun (x: var) -> fun (ctx: ctx) ->
    match ctx with
    | []                     -> Error (fstring "Variable %s not in context" (printvar x))
    | y :: ys when x = y.var && ignore y -> Error (fstring "Variable %s not available in context" (printvar x))
    | y :: ys when x = y.var && not (islins y) -> Value (y, ctx)
    | y :: ys when x = y.var -> Value (y, {y with used=Used} :: ys)
    | y :: ys                -> (lookup_update x >>= (fun s -> fun ctx' -> Value(s, y :: ctx'))) ys

let rec rm l v =
    match l with
    | x :: xs when v=x -> xs
    | x :: xs          -> x :: (rm xs v)
    | []               -> raise (UnexpectedError __LOC__ )

let rec find l v = 
    match l with
    | x :: xs when v=x -> true
    | x :: xs          -> find xs v
    | []               -> false

let rec same (ctx1: ctx) (ctx2: ctx) : unit t = 
    match ctx1, ctx2 with
    | s :: ss, _ -> if find ctx2 s then same ss (rm ctx2 s)
                                   else error (fstring "Context mismatch at variable: %s; Only found in the first context" (printstate s))
    | [], []     -> return ()
    | [], s :: _      -> error (fstring "Context mismatch at variable: %s; Only found in the second context" (printstate s))

let allsame (ctxl: ctx list) :unit t =
    let* _ = (List.fold_left (fun ctxt ctx ->
        let* ctx' = ctxt in
        same ctx ctx' >> return ctx
    ) (return (List.hd ctxl)) ctxl)
    in return ()

let rec subIndx: var -> indx -> typ -> typ = fun x -> fun s -> fun t ->
    let subber = subIndx x s in
    match t with
    | Star -> Star
    | TVar x -> TVar x
    | AppType (x, y) -> AppType (subber x, subber y)
    | LUnit -> LUnit
    | Color -> Color
    | Num -> Num
    | String -> String
    | Char -> Char
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
    | Univ (i, y, z) when x=i -> t
    | Exist (i, y, z) when x=i -> t
    | Univ (x, y, z) -> Univ (x, y, subber z)
    | Exist (x, y, z) -> Exist (x, y, subber z)
    | Widget (IVar i) when x=i -> Widget s
    | Widget i -> Widget i
    | Prefix ((IVar i), t) when x=i -> Prefix (s, t)
    | Prefix (i, (IVar t)) when x=t -> Prefix (i, s)
    | Prefix (i, t) -> Prefix (i, t)

let rec subType x tto tfrom =
    let subber = subType x tto in
    match tfrom with
    | TVar y -> if x=y then tto else tfrom
    | Star | LUnit | Color | Num | String | Char | IUnit | IndxT _ | Widget _ | Prefix _ -> tfrom
    | AppType (x, y) -> AppType (subber x, subber y)
    | Loli (x, y) -> Loli (subber x, subber y)
    | Tensor (x, y) -> Tensor (subber x, subber y) 
    | LSum (x, y) -> LSum (subber x, subber y)
    | F x -> F (subber x)
    | Evt x -> Evt (subber x)
    | Arrow (x, y) -> Arrow (subber x, subber y)
    | Prod (x, y) -> Prod (subber x, subber y)
    | ISum (x, y) -> ISum (subber x, subber y)
    | G x -> G (subber x)
    | At(t, n) -> At (subber t, n)
    | Univ (i, it, t) -> if i=x then tfrom else Univ(i, it, subber t)
    | Exist (i, it, t) -> if i=x then tfrom else Exist(i, it, subber t)

let rec getNormal t =
    match t with
    | TVar x -> let* s = lookup x in
                (match s.used with
                | Typ -> 
                    (match s.typ with
                    | Star -> return (TVar x)
                    | _ ->  getNormal s.typ)
                | _  -> error "123")
    | AppType (Univ(i, TType, t1), t2) -> 
        getNormal (subType i t2 t1)
    | AppType (t1, t2) ->
        let* t1' = getNormal t1 in
        let* t2' = getNormal t2 in
        getNormal (AppType(t1', t2'))
    | _ -> return t