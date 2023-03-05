(* Avoiding a GADT with modules *)

module Types :
sig
  type scalar
  type vector
  type data = private
    | Name of string
    | Record of (string * data) list
    | Array of (data * int)

  type 'a t = data
  val name : string -> scalar t
  val record : (string * _ t) list -> vector t
  val array : scalar t -> int -> scalar t
end =
struct
  type scalar
  type vector

  type data =
    | Name of string
    | Record of (string * data) list
    | Array of (data * int)

   type 'a t = data

   let name x = Name x
   let record elts = Record (elts)
   let array elt sz = Array (elt,sz)
end
