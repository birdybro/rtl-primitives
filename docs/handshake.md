# Handshake / Flow-Control Primitives

## Overview

All handshake primitives in this library use the **ready/valid** protocol:

- `valid` (output of producer): data on the bus is valid this cycle.
- `ready` (output of consumer): consumer can accept data this cycle.
- A transfer (handshake) occurs on any clock edge where **both** `valid`
  and `ready` are asserted simultaneously.

```
       Producer                Consumer
       ─────────               ─────────
       valid ──────────────►   valid
       data  ──────────────►   data
       ready ◄────────────── ready
```

A producer **must not** change `data` or deassert `valid` once `valid` is
asserted, until the handshake completes (i.e., `ready` is seen).

## Module Reference

### `skid_buffer` — Skid Buffer

Two-entry elastic buffer that allows a producer to issue one extra word after
`ready` is deasserted. This breaks the combinational `valid → ready` feedback
loop that can otherwise create long critical paths.

```
Parameters: DATA_WIDTH (int)
Ports: clk, rst_n, in_valid, in_ready, in_data, out_valid, out_ready, out_data
```

**Use as the default stage** between pipeline stages that have timing-critical
paths.

---

### `ready_valid_stage` — Ready/Valid Stage

Single registered pipeline stage with a full ready/valid handshake. Stores one
word and controls upstream backpressure.

```
Parameters: DATA_WIDTH (int)
Ports: clk, rst_n, in_valid, in_ready, in_data, out_valid, out_ready, out_data
```

---

### `pipeline_register_slice` — Pipeline Register Slice

Full/cut-through register slice. Provides a registered stage that decouples
upstream and downstream handshakes and supports 100% throughput.

```
Parameters: DATA_WIDTH (int)
Ports: clk, rst_n, up_valid, up_ready, up_data, dn_valid, dn_ready, dn_data
```

**Difference from `skid_buffer`:** Upstream uses `up_*` naming to emphasise
that this is a pipeline "cut" rather than a buffering element.

---

### `elastic_buffer` — Elastic Buffer

Deeper buffered ready/valid stage (configurable depth). Absorbs upstream
bursts without imposing backpressure until the buffer fills.

```
Parameters: DATA_WIDTH (int), DEPTH (int, power of two)
Ports: clk, rst_n, in_valid, in_ready, in_data, out_valid, out_ready, out_data
```

---

### `backpressure_adapter` — Backpressure Adapter

Accepts a streaming source (no `ready` input) and buffers data. Asserts
`src_overflow` when the internal buffer fills and data would be lost.

```
Parameters: DATA_WIDTH (int), BUFFER_DEPTH (int, power of two)
Ports:
  src_valid, src_data, src_overflow   — upstream (no ready)
  snk_valid, snk_ready, snk_data      — downstream
```

**Use when:** The upstream source cannot be stalled (e.g., sensor data, DMA
burst output).

---

### `mailbox_fifo` — Mailbox FIFO

Single-word FIFO with ready/valid on both sides. The writer cannot submit a
new word until the reader has consumed the current one, providing a
synchronisation point.

```
Parameters: DATA_WIDTH (int)
Ports: clk, rst_n, wr_valid, wr_ready, wr_data, rd_valid, rd_ready, rd_data
```

---

### `credit_flow_controller` — Credit Flow Controller

Credit-based flow control. The downstream agent returns credits; the upstream
agent may send one word per available credit.

```
Parameters: DATA_WIDTH (int), MAX_CREDITS (int)
Ports:
  credit_in              — credit return from downstream
  send_req, send_data    — upstream send request + data
  send_ack               — grant: word was accepted
  recv_valid, recv_data  — received word output
```

**Use when:** The round-trip latency of a ready/valid handshake is too large
and pre-allocation of buffer credits is preferable.

## Backpressure Design Patterns

### Pattern 1: Simple Pipeline with Skid Buffers

```systemverilog
skid_buffer #(.DATA_WIDTH(32)) u_stage0 (
  .clk(clk), .rst_n(rst_n),
  .in_valid(s0_valid), .in_ready(s0_ready), .in_data(s0_data),
  .out_valid(s1_valid), .out_ready(s1_ready), .out_data(s1_data)
);
skid_buffer #(.DATA_WIDTH(32)) u_stage1 (
  .clk(clk), .rst_n(rst_n),
  .in_valid(s1_valid), .in_ready(s1_ready), .in_data(s1_data),
  .out_valid(s2_valid), .out_ready(s2_ready), .out_data(s2_data)
);
```

### Pattern 2: Burst Absorption

```systemverilog
backpressure_adapter #(
  .DATA_WIDTH  (8),
  .BUFFER_DEPTH(16)
) u_burst_absorb (
  .clk         (clk),
  .rst_n       (rst_n),
  .src_valid   (sensor_valid),
  .src_data    (sensor_data),
  .src_overflow(data_lost),
  .snk_valid   (proc_valid),
  .snk_ready   (proc_ready),
  .snk_data    (proc_data)
);
```
