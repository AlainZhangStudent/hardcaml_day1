open! Base

type 'a t = { g : 'a } [@@unboxed]

(* We want to ensure the derived operations are exactly the same as for the inner type, so
   we define them directly. *)

let[@inline] create g = { g }
let[@inline] g { g } = g
let[@inline] map { g } ~f = { g = f g }
let[@inline] compare compare_g { g = a } { g = b } = compare_g a b
let[@inline] hash_fold_t hash_fold_g hash_state { g } = hash_fold_g hash_state g
let[@inline] sexp_of_t sexp_of_g { g } = sexp_of_g g
let[@inline] t_of_sexp g_of_sexp sexp = { g = g_of_sexp sexp }
let[@inline] globalize _ { g } = { g }
let[@inline] equal equal_g { g = a } { g = b } = equal_g a b

(* Proof that [drop_some] can be safely implemented in normal ocaml. But this
   implementation allocates a second option locally. *)
let _drop_some_proof : 'a t option -> 'a option =
  fun x ->
  match x with
  | None -> None
  | Some { g } -> Some g
;;

(* This version of [drop_some] does not. *)
external drop_some : 'a t option -> 'a option = "%identity"

(* A similar argument applies to [drop_ok] and [drop_error]. *)
external drop_ok : ('a t, 'b) Result.t -> ('a, 'b) Result.t = "%identity"
external drop_error : ('a, 'b t) Result.t -> ('a, 'b) Result.t = "%identity"

(* Proof that [inject_some] can be safely implemented in normal ocaml. But this
   implementation allocates a second option locally. *)
let _inject_some : 'a option -> 'a t option =
  fun x ->
  match x with
  | None -> None
  | Some y -> Some { g = y }
;;

external inject_some : 'a option -> 'a t option = "%identity"
external inject_ok : ('a, 'b) Result.t -> ('a t, 'b) Result.t = "%identity"
external inject_error : ('a, 'b) Result.t -> ('a, 'b t) Result.t = "%identity"
external inject_result : ('a, 'b) Result.t -> ('a t, 'b t) Result.t = "%identity"

(* We specifically use the "legacy" [Make_binable1_without_uuid] function, because it
   _doesn't_ change the bin_io shape, which is what we want here. *)
include
  Bin_prot.Utils.Make_binable1_without_uuid [@alert "-legacy"] [@inlined hint] (struct
  module Binable = struct
    type 'a t = 'a [@@deriving bin_io]
  end

  type nonrec 'a t = 'a t

  let[@inline] of_binable g = { g }
  let[@inline] to_binable { g } = g
end)
