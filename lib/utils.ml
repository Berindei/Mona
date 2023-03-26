exception Unimplemented
exception UnexpectedError

let fstring = Printf.sprintf
let filtermap l f p = List.map (fun x -> if p x then f x else x) l
