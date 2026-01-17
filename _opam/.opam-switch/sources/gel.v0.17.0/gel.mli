open! Base

(** A shim to mark non-record fields global. "GEL" stands for "Global Even if inside a
    Local", but is kept short since we'll need this boilerplate a lot.

    For example, if you have a list:

    {[
      type t = string list
    ]}

    and want to make it local, but still keep the strings global, you can write:

    {[
      type t = string Gel.t list
    ]}

    and it will be so, but with some extra boilerplate when using it.

    This is for use with existing types that don't have the desired global_ annotation.
    If you find yourself reaching for this for a new type you are defining, you can avoid
    the boilerplate. For example:

    {[
      type t =
        { global_ foo : string
        ; bar : int
        }

      type t =
        | Foo of global_ string
        | Bar of { global_ foo : string; bar : int }
        | Baz of global_ string * int * global_ string
    ]}
*)
type 'a t = { g : 'a } [@@unboxed] [@@deriving bin_io, compare, equal, hash, sexp]

val create : 'a -> 'a t
val g : 'a t -> 'a
val map : 'a t -> f:('a -> 'b) -> 'b t
val globalize : _ -> 'a t -> 'a t

(** Removes a [Gel.t] from inside an option type with zero runtime cost. This is useful
    when some other function returns an [X.t Gel.t option], you know [X.t] is
    mode-crossing, and you want to drop the inner [Gel.t] without allocating another local
    option. *)
val drop_some : 'a t option -> 'a option

(** Like [drop_some], but for the [Ok _] branch of a result. *)
val drop_ok : ('a t, 'b) Result.t -> ('a, 'b) Result.t

(** Like [drop_some], but for the [Error _] branch of a result. *)
val drop_error : ('a, 'b t) Result.t -> ('a, 'b) Result.t

(** Treat an existing global option as a local while maintaining the knowledge that the
    data inside the option is global. Zero runtime cost.

    "Injects some gel between the option and its [Some _] case." *)
val inject_some : 'a option -> 'a t option

(** Like [inject_some], but for the [Ok _] case of a [result]. *)
val inject_ok : ('a, 'b) Result.t -> ('a t, 'b) Result.t

(** Like [inject_some], but for the [Error _] case of a [result]. *)
val inject_error : ('a, 'b) Result.t -> ('a, 'b t) Result.t

(** Like [inject_some], but for the contents of a [result]. *)
val inject_result : ('a, 'b) Result.t -> ('a t, 'b t) Result.t
