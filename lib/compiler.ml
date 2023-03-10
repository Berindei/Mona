open Ast
open Utils

type extBind = var * string

type 'a t = extBind list -> ('a * extBind list)

let return (a: 'a): 'a t = fun bl -> (a, bl)

let bind x f = fun bl -> let a, bl' = x bl in f a bl'

let (let*) = bind

let add b = fun bl -> ((), b::bl)

let get s = fun bl -> (List.assoc_opt s bl, bl)

let rec union l1 l2 = 
  match l1 with
  | [] -> l2
  | x::xs -> if List.mem x l2 then union xs l2 else union xs (x::l2)

let (@) = union

let printfvs l = List.fold_left (^) "" (List.map (fun (x, at) -> fstring "%s:%s|" x (printindx at)) l) 

let rec fv e =
  match e with
  | EUnit -> []
  | LetUnit(e1, e2) -> (fv e1) @ (fv e2)
  | Var x -> failwith "AAAAAAAAAAAAAAA"
  | TypedVar(x, t, at) -> [(x, at)]
  | Lambda(x, e1) -> fv e1
  | App(e1, e2) -> (fv e1) @ (fv e2)
  | Pair(e1, e2) -> (fv e1) @ (fv e2)
  | Unpair(x1, x2, e1, e2) -> (fv e1) @ (fv e2)
  | Annot(e1, t) -> fv e1
  | L(e1) -> fv e1
  | R(e1) -> fv e1
  | Case(e1, x1, e2, x2, e3) -> (fv e1) @ (fv e2) @ (fv e3)
  | Proj1(e1) -> fv e1
  | Proj2(e1) -> fv e1
  | EF(e1) -> fv e1
  | EG(e1) -> fv e1
  | LetF(x, e1, e2) -> (fv e1) @ (fv e2)
  | Run(e1) -> fv e1
  | EEvt(e1) -> fv e1
  | LetEvt(x, e1, e2) -> (fv e1) @ (fv e2)
  | Select(x, y, e1, e2, e3, e4) -> (fv e1) @ (fv e2) @ (fv e3) @ (fv e4)
  | EAt(e1) -> fv e1
  | LetAt(x, e1, e2) -> (fv e1) @ (fv e2)
  | LambdaIndx(x, e1) -> fv e1
  | AppIndx(e1, _) -> (fv e1)
  | Pack(_, e2) -> (fv e2)
  | LetPack(x, i, e1, e2) -> (fv e1) @ (fv e2)
  | Let(x, e1, e2) -> (fv e1) @ (fv e2)
  | LetFix(f, t, x, e1, e2) -> (fv e1) @ (fv e2)
  | Extern(x, t, s, e1) -> fv e1
  | Out(e1) -> fv e1
  | Into(e1) -> fv e1
  | Indx(_) -> []

let rec constrchain l b = 
  match l with
  | []    -> fstring "chan.put(%s)" b
  | x::xs -> fstring "%s(%s=>{%s})" x x (constrchain xs b)

let rec compile e : string t=
  match e with
  | EUnit -> return "null"
  | LetUnit(e1, e2) -> compile (Let("kill", e1, e2))
  | Var x -> let* j = get x in
             (match j with
             | Some js -> return (fstring "(function(){return (%s)})()" js)
             | None    -> return x)
  | Lambda(x, m) -> let* m' = compile m in
                    return (fstring "function(%s){return (%s)}" x m')
  | App(m, n) -> let* m' = compile m in
                 let* n' = compile n in
                 return (fstring "(%s)(%s)" m' n')
  | Pair(e1, e2) -> let* e1' = compile e1 in
                    let* e2' = compile e2 in
                    return (fstring "[%s, %s]" e1' e2')
  | Unpair(x1, x2, e1, e2) -> let* e1' = compile e1 in
                              let* e2' = compile e2 in
                              return (fstring (
"(function() {
  var pair = %s;
  return (function(%s, %s){
      return(%s)
  })(pair[0], pair[1])
})()") e1' x1 x2 e2')
  | Annot(e1, t) -> compile e1
  | L(e1) -> let* e1' = compile e1 in
             return (fstring "{value: %s, tag:\"L\"}" e1')
  | R(e1) -> let* e1' = compile e1 in
             return (fstring "{value: %s, tag:\"R\"}" e1')
  | Case(e1, x1, e2, x2, e3) -> let* e1' = compile e1 in let* e2' = compile e2 in let* e3' = compile e3 in
                                return (fstring
"(function(){
  var sum = (%s);
  var f1 = function (%s) {return (%s)};
  var f2 = function (%s) {return (%s)};
  if(sum.tag==\"L\") return f1(sum.value);
  else return f2(sum.value);
})()" e1' x1 e2' x2 e3')
  | Proj1(e1) -> let* e1' = compile e1 in return (e1' ^ "[0]")
  | Proj2(e1) -> let* e1' = compile e1 in return (e1' ^ "[1]")
  | EF(e1) -> compile e1
  | EG(e1) -> let* e1' = compile e1 in 
              return (fstring "function(unit){return (%s)}" e1')
  | LetF(x, e1, e2) -> compile (Let(x, e1, e2))
  | Run(e1) -> let* e1'= compile e1 in
               return (fstring "(%s)(null)" e1')
  | EEvt(e1) -> let* e1'= compile e1 in
                return (fstring "(function(){
  var chan = new Channel();
  chan.put(%s);
  return curriedget(chan);
})()" e1')
  | LetEvt(x, e1, e2) -> let* e1' = compile e1 in 
                         let* e2' = compile e2 in
                         return (fstring "(function(){
  var chan = new Channel();
  var g = (%s);
  var f = (%s => (%s));
  g( x => f(x)(y => chan.put(y)) );
  return curriedget(chan);
})()" e1' x e2')
  | Select(x, y, e1, e2, e3, e4) -> let* e1' = compile e1 in
                                    let* e2' = compile e2 in
                                    let* e3' = compile e3 in 
                                    let* e4' = compile e4 in
                                    return (fstring "(function (){
  var chan = new Channel();
  var finchan = new Channel();
  var g1 = %s;
  var g2 = %s;
  var f1 = %s => (%s);
  var f2 = %s => (%s);
  var first = true;
  g1( a=> {if(first){
    first = false;
    var newchan = new Channel();
    chan.get(newchan.put);
    f1(a)(newchan.get)(x => finchan.put(x))
  } else chan.put(a)})
  g2( b=> {if(first){
    first = false;
    var newchan = new Channel();
    chan.get(newchan.put);
    f2(b)(newchan.get)(x => finchan.put(x))
  } else chan.put(b)})
  return curriedget(finchan);
})()" e1' e2' x e3' y e4') (*might need to use some atomic locks*)
   (*cum credeam, nevoie de context to some degree*)
  | EAt(e1) -> let chain = List.map (fun (x, at) -> x) (List.filter (fun (x, at) -> not(at=(Time 0))) (fv e1)) in
               print_endline (printfvs (fv e1));
               let* e1' = compile e1 in
               let str = constrchain chain e1' in
               return (fstring "(function(){
                var chan = new Channel();
                %s;
                return curriedget(chan);
              })()" str )
  | LetAt(x, e1, e2) -> compile (Let(x, e1, e2))
  | LambdaIndx(x, e1) -> let* e1' = compile e1 in
                         return (fstring "function (unit){return (%s)}" e1')
  | AppIndx(e1, e2) -> let* e1' = compile e1 in
                       return (fstring "(%s)(null)" e1')
  | Pack(e1, e2) -> let* e2' = compile e2 in
                    return (fstring "(function (){return (%s)})()" e2')
  | LetPack(i, x, e1, e2) -> compile (Let(i, EUnit, (Let(x, e1, e2))))
  | Let(x, e1, e2) -> compile (App(Lambda(x, e2), e1))
  | LetFix(f, t, x, e1, e2) -> let* e1' = compile e1 in
                               let* e2' = compile e2 in
                               return (fstring "(function (%s){return (%s)})(function %s(%s){return (%s);})" f e2' f x e1' )
  | Extern(x, t, s, e') -> let* () = add (x, s) in compile e'
  | Out e' -> compile e'
  | Into e' -> compile e'
  | Indx(IVar x) -> return x 
  | Indx _ -> failwith "This shouldn't happen"
  | TypedVar(x, _, at) -> compile (Var x)

let generate e f = let out = open_out f in
               let js, _ = compile e [] in print_endline js;
               output_string out (fstring "function main(){return (\n\n%s\n\n)};" js);
               close_out out