open Hardcaml
open Signal

module I = struct
  type 'a t = { 
    clk : 'a; 
    rst : 'a; 
    en : 'a; 
    direction : 'a; 
    number : 'a [@bits 8]; 
  } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = { 
    pointer : 'a [@bits 7]; 
    zero_count : 'a [@bits 16]; 
    busy : 'a; 
  } [@@deriving sexp_of, hardcaml]
end

let create (scope : Scope.t) (i : Signal.t I.t) =
  let open Signal in
  let spec = Reg_spec.create ~clock:i.clk ~reset:i.rst () in

  (* registers *)
  let pointer = Always.Variable.reg spec ~enable:vdd ~width:7 in
  let zero_count = Always.Variable.reg spec ~enable:vdd ~width:16 in
  let steps_remaining = Always.Variable.reg spec ~enable:vdd ~width:8 in

  (* 1. Calculate next_ptr combinational logic OUTSIDE compile for clarity *)
  let next_ptr = 
    mux2 (i.direction ==:. 1)
      (mux2 (pointer.value ==:. 99) (of_int ~width:7 0) (pointer.value +:. 1))
      (mux2 (pointer.value ==:. 0)  (of_int ~width:7 99) (pointer.value -:. 1))
  in

  Always.(compile [
    if_ i.rst [
      pointer <--. 50;
      zero_count <--. 0;
      steps_remaining <--. 0;
    ] [
      if_ (steps_remaining.value ==:. 0) [
        if_ i.en [
          steps_remaining <-- i.number;
        ] []
      ] [
        (* We group multiple assignments in a list [ ] to avoid the unit warning *)
        steps_remaining <-- steps_remaining.value -:. 1;
        
        pointer <-- next_ptr;

        if_ (next_ptr ==:. 0) [
          zero_count <-- zero_count.value +:. 1;
        ] [];
      ]
    ]
  ]);

  { O.pointer = pointer.value; 
    zero_count = zero_count.value; 
    busy = (steps_remaining.value <>:. 0) 
  }