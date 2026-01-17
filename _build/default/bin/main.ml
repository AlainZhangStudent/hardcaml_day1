open Core
open Hardcaml
open Hardcaml_lib

let run_simulation () =
  let module Sim = Cyclesim.With_interface (Logic.I) (Logic.O) in
  let sim = Sim.create (Logic.create (Scope.create ())) in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in

  inputs.rst := Bits.vdd;
  Cyclesim.cycle sim;
  inputs.rst := Bits.gnd;

  let file_path = "data.txt" in
  let lines = In_channel.read_lines file_path in
  
  List.iter lines ~f:(fun line ->
    let line = String.strip line in
    if String.is_empty line then ()
    else (
      let direction_char = line.[0] in
      let number_val = Int.of_string (String.slice line 1 0) in
      
      let dir_bits = if Char.equal direction_char 'R' then 1 else 0 in

      inputs.direction := Bits.of_int ~width:1 dir_bits;
      inputs.number := Bits.of_int ~width:8 number_val;
      
      inputs.en := Bits.vdd;
      Cyclesim.cycle sim;
      inputs.en := Bits.gnd;

      while Bits.to_int !(outputs.busy) <> 0 do
        Cyclesim.cycle sim
      done
    )
  );

  printf "Final Pointer: %d\n" (Bits.to_int !(outputs.pointer));
  printf "Zero Count: %d\n" (Bits.to_int !(outputs.zero_count))

let () = run_simulation ()