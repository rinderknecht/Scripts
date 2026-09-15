type 'a plambda =
| Var of 'a
| Lam of ('a -> 'a plambda)
| App of  'a plambda * 'a plambda

type lambda = {
  up: 'a . 'a plambda
}

let identity : lambda =
  { up =
      Lam (fun x -> Var x)
  }

