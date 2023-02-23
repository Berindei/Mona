open Ast
open Ctx
open Utils

let unexpectedform s1 s2 = fstring "Expected something with the type of the form %s, got %s" s1 (printtype s2)

let plsProd: typ -> (typ*typ) t = fun t ->
  match t with
  | Prod (t1, t2) -> return (t1, t2)
  | _ -> error (unexpectedform "α*β" t)

let plsTensor: typ -> (typ*typ) t = fun t ->
  match t with
  | Tensor (t1, t2) -> return (t1, t2)
  | _ -> error (unexpectedform "α⊗β" t)

let plsArrow: typ -> (typ*typ) t = fun t ->
  match t with
  | Arrow (t1, t2) -> return (t1, t2)
  | _ -> error (unexpectedform "α→β" t)

let plsLoli: typ -> (typ*typ) t = fun t ->
  match t with
  | Loli (t1, t2) -> return (t1, t2)
  | _ -> error (unexpectedform "α⊸β" t)

let plsLSum: typ -> (typ*typ) t = fun t ->
  match t with
  | LSum (t1, t2) -> return (t1, t2)
  | _ -> error (unexpectedform "α⊕β" t)

let plsISum: typ -> (typ*typ) t = fun t ->
  match t with
  | ISum (t1, t2) -> return (t1, t2)
  | _ -> error (unexpectedform "α+β" t)

let plsF: typ -> typ t = fun t ->
  match t with
  | F(t) -> return t
  | _ -> error (unexpectedform "F(α)" t)

let plsG: typ -> typ t = fun t ->
  match t with
  | G(t) -> return t
  | _ -> error (unexpectedform "G(α)" t)

let plsEvt t = 
  match t with
  | Evt(t) -> return t
  | _ -> error (unexpectedform "♢(α)" t)

let plsAt t =
  match t with
  | At(t, tau) -> return (t, tau)
  | _ -> error (unexpectedform "α@τ" t)

let plsUniv t =
  match t with
  | Univ(x, it, t) -> return (x, it, t)
  | _ -> error (unexpectedform "∀i:σ.α" t)

let plsExist t =
  match t with
  | Exist(x, it, t) -> return (x, it, t)
  | _ -> error (unexpectedform "∃i:σ.α" t)

let plsIndxVar i = 
  match i with
  | IVar x -> return x
  | _ -> error (fstring "Expected an index variable, got %s" (printindx i))
