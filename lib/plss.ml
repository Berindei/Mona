open Ast
open Ctx
open Utils

let unexpectedform s1 s2 = fstring "Expected something with the type of the form %s, got %s" s1 (printtype s2)

let plsProd: typ * expr -> (typ*typ*expr) t = fun (t, e) ->
  match t with
  | Prod (t1, t2) -> return (t1, t2, e)
  | _ -> error (unexpectedform "α*β" t)

let plsTensor: typ*expr -> (typ*typ*expr) t = fun (t, e) ->
  match t with
  | Tensor (t1, t2) -> return (t1, t2, e)
  | _ -> error (unexpectedform "α⊗β" t)

let plsArrow: typ*expr -> (typ*typ*expr) t = fun (t, e) ->
  match t with
  | Arrow (t1, t2) -> return (t1, t2, e)
  | _ -> error (unexpectedform "α→β" t)

let plsLoli: typ*expr -> (typ*typ*expr) t = fun (t, e) ->
  match t with
  | Loli (t1, t2) -> return (t1, t2, e)
  | _ -> error (unexpectedform "α⊸β" t)

let plsLSum: typ*expr -> (typ*typ*expr) t = fun (t, e) ->
  match t with
  | LSum (t1, t2) -> return (t1, t2, e)
  | _ -> error (unexpectedform "α⊕β" t)

let plsISum: typ*expr -> (typ*typ*expr) t = fun (t, e) ->
  match t with
  | ISum (t1, t2) -> return (t1, t2, e)
  | _ -> error (unexpectedform "α+β" t)

let plsF: typ*expr -> (typ*expr) t = fun (t, e) ->
  match t with
  | F(t) -> return (t, e)
  | _ -> error (unexpectedform "F(α)" t)

let plsG: typ*expr -> (typ*expr) t = fun (t, e) ->
  match t with
  | G(t) -> return (t, e)
  | _ -> error (unexpectedform "G(α)" t)

let plsEvt (t, e) = 
  match t with
  | Evt(t) -> return (t, e)
  | _ -> error (unexpectedform "♢(α)" t)

let plsAt (t, e) =
  match t with
  | At(t, tau) -> return (t, tau, e)
  | _ -> error (unexpectedform "α@τ" t)

let plsUniv (t, e) =
  match t with
  | Univ(x, it, t) -> return (x, it, t, e)
  | _ -> error (unexpectedform "∀i:σ.α" t)

let plsExist (t, e) =
  match t with
  | Exist(x, it, t) -> return (x, it, t, e)
  | _ -> error (unexpectedform "∃i:σ.α" t)

let plsIndxVar i = 
  match i with
  | IVar x -> return x
  | _ -> error (fstring "Expected an index variable, got %s" (printindx i))
