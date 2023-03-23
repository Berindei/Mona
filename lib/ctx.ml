open Ast
open Utils

type usage = Used | Fresh | Inf | Ext
type flag = Use | Ignore

type state = {var: var; used: usage; typ: typ; ignore: flag; delay: flag list; at: indx}

let mkstate v u t i d a = {var=v; used=u; typ=t; ignore=i; delay=d; at=a}

let used v t :state= mkstate v Used t Use [Use] (Time 0)
let fresh v t = mkstate v Fresh t Use [Use] (Time 0)
let int v t = mkstate v Inf t Use [Use] (Time 0) (*includes indeces*)
let ext v t = mkstate v Ext t Use [Use] (Time 0)

let islins s = s.used = Fresh || s.used = Used
let islinu u = u=Fresh || u=Used

let delayed v t d = {(fresh v t) with at = d}

let ignore s = s.ignore = Ignore || List.exists (fun x -> x=Ignore) s.delay
let use s = s.ignore = Use && List.for_all (fun x -> x=Use) s.delay

let actualAt s = if List.length s.delay <= 1 then s.at else Time 0

type ctx = state list

let printusage u = match u with Fresh->"1"| Used->"0" | Inf->"∞" | Ext->"ex"

let printstate s =
    let printinner =
        match s.used with
        | _ when s.at = Time 0 -> fstring "%s^%s: %s" s.var (printusage s.used) (printtype s.typ)
        | Inf | Ext -> fstring "%s^%s: %s" s.var (printusage s.used) (printtype s.typ)
        | Used | Fresh -> fstring "%s^%s: %s[%s]" s.var (printusage s.used) (printtype s.typ) (printindx (actualAt s))
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
    | []                     -> Error (fstring "Variable %s not in context" x)
    | y :: ys when x = y.var && ignore y -> Error (fstring "Variable %s not available in this context" x)
    | y :: ys when x = y.var -> Value (y, y :: ys)
    | y :: ys                -> (lookup x >>= (fun s -> fun ctx' -> Value(s, y :: ctx'))) ys

let rec lookup_update: var -> state t = fun (x: var) -> fun (ctx: ctx) ->
    match ctx with
    | []                     -> Error (fstring "Variable %s not in context" x)
    | y :: ys when x = y.var && ignore y -> Error (fstring "Variable %s not available in this context" x)
    | y :: ys when x = y.var && not (islins y) -> Value (y, ctx)
    | y :: ys when x = y.var -> Value (y, {y with used=Used} :: ys)
    | y :: ys                -> (lookup_update x >>= (fun s -> fun ctx' -> Value(s, y :: ctx'))) ys

let rec rm l v =
    match l with
    | x :: xs when v=x -> xs
    | x :: xs          -> x :: (rm xs v)
    | []               -> raise UnexpectedError

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