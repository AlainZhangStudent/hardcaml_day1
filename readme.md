# --- Day 1: Secret Entrance ---

## Approach
This project implements a hardware-based pointer tracker that monitors a circular buffer of 100 slots (0-99). The design is written in **Hardcaml**, an OCaml-based library for generating synthesizable RTL.

### Design Architecture
The core logic uses a **Synchronous Finite State Machine (FSM)** style implemented via the Hardcaml `Always` DSL.

1.  **Registers**:
    * `pointer` (7-bit): Tracks the current position (0-99).
    * `zero_count` (16-bit): Increments every time the pointer lands on index 0.
    * `steps_remaining` (8-bit): A down-counter that handles multi-step moves sequentially.
2.  **Sequential Execution**: To match the software reference I wrote in Python, the hardware processes one "move" per clock cycle. When an `enable` pulse is received, the `number` of steps is loaded into `steps_remaining`.
3.  **Look-Ahead Detection**: The zero-detection logic is placed within the same `Always` block as the pointer update. By checking the updated pointer value within the block, the hardware ensures that `zero_count` increments on the same clock edge that the pointer reaches zero, preventing off-by-one errors.

## How to Run
dune exec run_ptr

## How to run testbench
dune runtest

### Prerequisites
* OCaml 5.x
* opam (OCaml Package Manager)
* Hardcaml and Core libraries (`opam install hardcaml core ppx_hardcaml`)

### Building
```bash
dune build
