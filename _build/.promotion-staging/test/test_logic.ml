open! Core
open Hardcaml
open Hardcaml_lib

let%expect_test "Hardware Logic Verification" =
  (* Setup Simulator *)
  let module Sim = Cyclesim.With_interface (Logic.I) (Logic.O) in
  let sim = Sim.create (Logic.create (Scope.create ())) in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in

  let step () = Cyclesim.cycle sim in

  let run_command dir num =
    inputs.direction := Bits.of_int ~width:1 dir;
    inputs.number := Bits.of_int ~width:8 num;
    inputs.en := Bits.vdd;
    step ();
    inputs.en := Bits.gnd;
    while Bits.to_int !(outputs.busy) <> 0 do
      step ()
    done;
    printf "Ptr: %3d | Zeros: %3d\n" 
      (Bits.to_int !(outputs.pointer)) 
      (Bits.to_int !(outputs.zero_count))
  in

  (* Initial State *)
  inputs.rst := Bits.vdd;
  step ();
  inputs.rst := Bits.gnd;
  printf "After Reset - Ptr: %d, Zeros: %d\n" 
    (Bits.to_int !(outputs.pointer)) (Bits.to_int !(outputs.zero_count));
  [%expect {| After Reset - Ptr: 50, Zeros: 0 |}];

  (* Test 1: Move Left to exactly 0 *)
  run_command 0 50; 
  [%expect {| Ptr:   0 | Zeros:   1 |}];

  (* Test 2: Wrap Left (0 -> 99) *)
  run_command 0 1;
  [%expect {| Ptr:  99 | Zeros:   1 |}];

  (* Test 3: Move Right to wrap (99 -> 0) *)
  run_command 1 2;
  [%expect {| Ptr:   1 | Zeros:   2 |}];

  (* Test 4: Large move *)
  run_command 0 20;
  [%expect {| Ptr:  81 | Zeros:   3 |}]