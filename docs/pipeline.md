# Pipeline Primitives

## Overview

Pipeline primitives control data flow, timing alignment, and hazard handling
in synchronous pipelines.

## Module Reference

### `pipeline_register` — Pipeline Register

Single registered stage with enable (`en`), flush (`flush`), and valid
propagation.

```
Parameters: DATA_WIDTH (int)
Ports:
  clk, rst_n, en, flush
  din, dout          — data in/out
  valid_in, valid_out — valid propagation
```

**Flush** clears `valid_out` and sets `dout` to zero without clearing the
register enable — used to inject pipeline bubbles on control hazards.

---

### `delay_line` — Delay Line

Configurable-depth shift register. Provides both a registered output (`dout`)
and a tap array (`tap_out`) exposing every intermediate stage.

```
Parameters: DATA_WIDTH (int), DEPTH (int)
Ports: clk, rst_n, en, din, dout, tap_out[DEPTH:0][DATA_WIDTH-1:0]
```

`tap_out[0]` = `din`, `tap_out[DEPTH]` = `dout` (= same as `dout`).

---

### `latency_balancer` — Latency Balancer

Aligns two parallel pipeline paths with different inherent latencies. Path A
(the shorter one) is padded with `LATENCY_B - LATENCY_A` extra delay stages.

```
Parameters: DATA_WIDTH (int), LATENCY_A (int), LATENCY_B (int ≥ LATENCY_A)
Ports: clk, rst_n, en, din_a, din_b, dout_a, dout_b
```

After `LATENCY_B` clock cycles of continuous enable, `dout_a` and `dout_b`
carry time-aligned data.

---

### `pipeline_bubble_injector` — Bubble Injector

Squashes a pipeline beat by deasserting `out_valid` and driving `NOP_VALUE`
on `out_data`. Combinational, zero-latency.

```
Parameters: DATA_WIDTH (int), NOP_VALUE (logic[DATA_WIDTH-1:0])
Ports: clk, rst_n (unused), in_valid, in_data, inject_bubble, out_valid, out_data
```

**Use for:** Hazard stall insertion. When `inject_bubble` is asserted, the
upstream stage should also be stalled so the squashed beat can be replayed.

---

### `pipeline_fork` — Pipeline Fork

Replicates one input stream to `NUM_OUTPUTS` downstream consumers. Accepts
from upstream only when all consumers have accepted (or already accepted in
previous cycles via a completion mask).

```
Parameters: DATA_WIDTH (int), NUM_OUTPUTS (int)
Ports:
  clk, rst_n
  in_valid, in_ready, in_data
  out_valid[NUM_OUTPUTS-1:0], out_ready[NUM_OUTPUTS-1:0]
  out_data[NUM_OUTPUTS-1:0][DATA_WIDTH-1:0]
```

---

### `pipeline_join` — Pipeline Join

Merges `NUM_INPUTS` input streams into one output. Fires only when all inputs
are simultaneously valid. Purely combinational.

```
Parameters: DATA_WIDTH (int), NUM_INPUTS (int)
Ports:
  clk, rst_n (unused)
  in_valid[NUM_INPUTS-1:0], in_ready[NUM_INPUTS-1:0]
  in_data[NUM_INPUTS-1:0][DATA_WIDTH-1:0]
  out_valid, out_ready
  out_data[NUM_INPUTS-1:0][DATA_WIDTH-1:0]
```

## Pipeline Design Patterns

### Pattern 1: Multi-Stage with Bubble Insertion

```systemverilog
// Compute stage
pipeline_register #(.DATA_WIDTH(32)) u_stage1 (
  .clk(clk), .rst_n(rst_n),
  .en(pipe_en), .flush(hazard),
  .din(compute_out), .dout(stage1_data),
  .valid_in(compute_valid), .valid_out(stage1_valid)
);

// Bubble injector
pipeline_bubble_injector #(.DATA_WIDTH(32)) u_bubble (
  .clk(clk), .rst_n(rst_n),
  .in_valid(stage1_valid), .in_data(stage1_data),
  .inject_bubble(load_use_hazard),
  .out_valid(stage2_valid), .out_data(stage2_data)
);
```

### Pattern 2: Latency-Balanced Parallel Paths

```systemverilog
// Path A has 2 pipeline stages; Path B has 4
latency_balancer #(
  .DATA_WIDTH(8),
  .LATENCY_A (2),
  .LATENCY_B (4)
) u_bal (
  .clk   (clk),
  .rst_n (rst_n),
  .en    (en),
  .din_a (path_a_data),
  .din_b (path_b_data),
  .dout_a(bal_a),
  .dout_b(bal_b)
);
```

### Pattern 3: Fork-Join

```systemverilog
// Fork to 2 consumers
pipeline_fork #(.DATA_WIDTH(8), .NUM_OUTPUTS(2)) u_fork (
  .clk      (clk), .rst_n(rst_n),
  .in_valid (src_valid), .in_ready(src_ready), .in_data(src_data),
  .out_valid(fork_valid), .out_ready(fork_ready), .out_data(fork_data)
);

// ... consumers process fork_data independently ...

// Join 2 streams
pipeline_join #(.DATA_WIDTH(8), .NUM_INPUTS(2)) u_join (
  .clk      (clk), .rst_n(rst_n),
  .in_valid (join_valid), .in_ready(join_ready), .in_data(join_data),
  .out_valid(merged_valid), .out_ready(merged_ready), .out_data(merged_data)
);
```
