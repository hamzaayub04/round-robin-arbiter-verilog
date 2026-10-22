# Round-Robin Arbiter with Fixed-Time Slice Allocation

A 4-way **Round-Robin Arbiter** written in **Verilog HDL** and simulated in **ModelSim**. It grants a shared resource (bus, memory, etc.) to four requesters in cyclic order, with a configurable **time slice** that limits how long each requester can hold the grant. Grants are **one-hot**, and no requester is starved.

---

## Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Block Diagram](#block-diagram)
- [Interface](#interface)
- [How It Works](#how-it-works)
- [Getting Started](#getting-started)
- [Testbench and Results](#testbench-and-results)
- [Possible Extensions](#possible-extensions)
- [References](#references)

---

## Features

- 4 request lines (`req[3:0]`) and 4 one-hot grant lines (`grant[3:0]`)
- Fair, cyclic scheduling: `req[0] → req[1] → req[2] → req[3] → req[0] → …`
- Inactive requesters are skipped
- Configurable time slice through the `TIME_SLICE` parameter
- Immediate hand-over when the current requester releases its request
- Grant drops to `0000` when no one is requesting
- Active-low asynchronous reset

---

## Project Structure

```
round-robin-arbiter/
├── images/
│   ├── ModelSim simulation waveform.png
│   └── Round-robin arbiter block diagram.png
├── .gitignore
├── rr_arbiter.v        # Arbiter design
├── tb_rr_arbiter.v     # Testbench
└── README.md
```

---

## Block Diagram

![Round-robin arbiter block diagram](images/Round-robin%20arbiter%20block%20diagram.png)

---

## Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `req` | input | 4 | Request lines, `req[i]` is requester *i* |
| `grant` | output | 4 | One-hot grant, `grant[i] = 1` means requester *i* has access |

| Parameter | Default | Description |
|-----------|---------|-------------|
| `TIME_SLICE` | 16 | Number of clock cycles allotted per grant |

Instantiation example:

```verilog
rr_arbiter #(.TIME_SLICE(8)) arbiter (
    .clk(clk),
    .rst_n(rst_n),
    .req(req),
    .grant(grant)
);
```

---

## How It Works

The design has two parts:

**Combinational logic** scans the request lines starting from `current_idx + 1`, wrapping around, and finds the next active requester (`next_found`, `next_idx`).

**Sequential logic** updates the grant and the slice counter (`slice_cnt`) on each clock edge:

1. **Idle:** if there is no grant and a request arrives, the next requester after the last one served gets the grant and the counter starts.
2. **Holding:** while the granted requester keeps its request high, `slice_cnt` counts up.
3. **Slice expired:** when the counter reaches the limit, the grant moves to the next active requester. If nobody else is requesting, the current requester keeps the grant and the counter restarts.
4. **Early release:** if the granted requester drops its request, the grant moves on immediately, or goes to `0000` if nobody else is requesting.

> **Note on slice length:** the counter starts at 1 when a grant is given and the slice ends when it reaches `TIME_SLICE - 1`, so each grant lasts `TIME_SLICE - 1` clock cycles in practice (4 cycles for `TIME_SLICE = 5`). This comes from reading the code; confirm it against your waveform if you need exact timing.

---

## Getting Started

### Requirements

- ModelSim / Questa, or any Verilog simulator (e.g. Icarus Verilog + GTKWave)

### Run in ModelSim

```tcl
vlib work
vlog rr_arbiter.v tb_rr_arbiter.v
vsim work.tb_rr_arbiter
add wave -r /tb_rr_arbiter/*
run -all
```

### Run with Icarus Verilog

```bash
iverilog -o sim rr_arbiter.v tb_rr_arbiter.v
vvp sim
gtkwave rr_arbiter_tb.vcd
```

---

## Testbench and Results

`tb_rr_arbiter.v` uses a 10 ns clock and `TIME_SLICE = 5`, and applies these cases:

| # | Stimulus | Expected behavior |
|---|----------|-------------------|
| 1 | Only `req[0]` | `grant[0]` stays high |
| 2 | All requests (`1111`) | Grants rotate `0001 → 0010 → 0100 → 1000 → 0001 …` |
| 3 | Only `req[2]` and `req[3]` (`1100`) | Grant alternates between those two only |
| 4 | No requests | `grant = 0000` |
| 5 | Burst pattern: `0010`, then `0110`, then `1001` | Grant follows the active requests without starvation |

![ModelSim simulation waveform](images/ModelSim%20simulation%20waveform.png)

The testbench also prints `req` and `grant` every clock cycle and writes a waveform file, `rr_arbiter_tb.vcd`.

---

## Possible Extensions

- Parameterize the number of requesters
- Weighted round-robin with a different time slice per requester
- Add a `busy`/`valid` handshake for bus integration
- FPGA implementation and timing analysis

---

## References

1. M. Morris Mano, *Digital Design*, Pearson Education.
2. David Harris & Sarah Harris, *Digital Design and Computer Architecture*.
3. Tom-Urkin, "Round Robin Arbiter Implementation in SystemVerilog," GitHub, 2023.
4. FreeCores Project, "Round-Robin Arbiter Repository," GitHub.
5. K. Skadron, "Fair Queueing and Arbitration Techniques in On-Chip Networks," IEEE Transactions on VLSI Systems, 2019.
6. J. Hennessy & D. Patterson, *Computer Architecture: A Quantitative Approach*, Morgan Kaufmann.

---

## Author

*Your name here*: add your name, university, and contact/LinkedIn.

## License

Add a license of your choice (e.g. MIT) or remove this section.
