# Clock-Domain Crossing (CDC) Primitives

## Overview

CDC primitives safely transfer signals between asynchronous clock domains.
Incorrect CDC handling is one of the most common sources of hard-to-reproduce
silicon bugs. Follow these guidelines whenever crossing a clock boundary.

## Golden Rules

1. **Never sample an unsynchronized signal from another clock domain.**
2. **Use a 2- or 3-FF synchronizer for single-bit signals.**
3. **Use Gray-coded pointers for multi-bit counters (e.g., FIFO pointers).**
4. **Never combinatorially decode signals that cross a clock boundary.**
5. **Reset must be released synchronously in every clock domain.**

## Module Reference

### `sync_2ff` — Two Flip-Flop Synchronizer

The simplest CDC primitive. Passes a single-bit signal through two back-to-back
flip-flops in the destination domain to reduce metastability probability.

```
Parameters:
  RESET_VAL (bit)  — reset value for both FFs (default: 0)
  STAGES    (int)  — informational only; always 2 in this module

Ports:
  clk     — destination clock
  rst_n   — active-low reset
  d       — single-bit input from the source domain
  q       — synchronized output
```

**Use when:** The input signal changes at most once per destination clock period
and is stable for at least the setup time of the first FF.

**Do NOT use for:** Pulse signals (use `pulse_synchronizer`) or multi-bit buses
(use multiple synchronizers or Gray-coded pointers).

---

### `sync_3ff` — Three Flip-Flop Synchronizer

Identical to `sync_2ff` but with an extra stage for higher-speed designs or
more stringent MTBF requirements.

**Use when:** Clock frequency > ~500 MHz or the MTBF requirement cannot be met
with only two stages.

---

### `pulse_synchronizer` — Single-Pulse Synchronizer

Converts a single-cycle pulse in the source domain to a single-cycle pulse in
the destination domain using a toggle-based handshake. Does not require the two
clocks to have any frequency relationship.

```
Ports:
  src_clk    — source clock
  src_rst_n  — source reset
  dst_clk    — destination clock
  dst_rst_n  — destination reset
  src_pulse  — 1-cycle input pulse (source domain)
  dst_pulse  — 1-cycle output pulse (destination domain)
```

**Latency:** ≥ 3 destination clock cycles after the source pulse.

**Throughput:** One pulse per ≥ 3 destination + 2 source cycles.

---

### `req_ack_synchronizer` — Request-Acknowledge Handshake

Two-way handshake for safe single-event transfers. The source asserts `src_req`
and holds it until `src_ack` returns. The destination receives `dst_pulse` when
the request is registered.

```
Ports:
  src_clk    — source clock
  src_rst_n  — source reset
  dst_clk    — destination clock
  dst_rst_n  — destination reset
  src_req    — request (source domain, level-sensitive, hold until ack)
  src_ack    — acknowledge (source domain, returned after dst registers req)
  dst_pulse  — one-cycle pulse in destination domain
```

**Use when:** You need guaranteed delivery with back-pressure capability.

---

### `toggle_synchronizer` — Level Signal Synchronizer

Synchronizes a multi-bit quasi-static data word using a toggle encoding.
Data is treated as stable; the source asserts a separate toggle each time
data changes.

**Use for:** Slow-changing configuration registers, status words.

---

### `bundled_data_synchronizer` — Bundled Data Transfer

Transfers a data word + valid/ready handshake across a clock boundary using a
four-phase req/ack protocol internally.

**Use for:** Infrequent data transfers where handshake latency is acceptable.

---

### `gray_pointer_sync` — Gray-Coded Pointer Synchronizer

Synchronizes a Gray-coded address pointer (as used in async FIFOs) through a
2-FF synchronizer. Gray code guarantees at most one bit changes between
consecutive pointer values, making metastability resolution safe.

```
Parameters:
  ADDR_WIDTH — pointer bit width (pointer is ADDR_WIDTH+1 bits wide)
Ports:
  gray_ptr_in  — Gray-coded pointer input
  gray_ptr_out — Synchronized Gray-coded pointer output
  clk, rst_n   — destination domain clock and reset
```

---

### `async_fifo` — Asynchronous FIFO

Full asynchronous FIFO using Gray-coded read/write pointers synchronized
through 2-FF synchronizers.

```
Parameters:
  DATA_WIDTH (int) — data word width (default 8)
  ADDR_WIDTH (int) — address width; depth = 2^ADDR_WIDTH (default 4)

Write side:  wr_clk, wr_rst_n, wr_en, wr_data, wr_full
Read side:   rd_clk, rd_rst_n, rd_en, rd_data, rd_empty
```

## CDC Checklist

- [ ] Every signal crossing a clock boundary goes through a synchronizer.
- [ ] Multi-bit data uses Gray code or a handshake protocol.
- [ ] Reset is synchronized in every destination domain.
- [ ] Timing constraints annotate all CDC paths as false paths or max-delay.
- [ ] `async_fifo` pointer widths are `ADDR_WIDTH+1` to support the extra MSB.

## Example: Async FIFO

```systemverilog
async_fifo #(
  .DATA_WIDTH(8),
  .ADDR_WIDTH(4)
) u_fifo (
  .wr_clk  (wr_clk),
  .wr_rst_n(wr_rst_n),
  .wr_en   (wr_en),
  .wr_data (wr_data),
  .wr_full (wr_full),
  .rd_clk  (rd_clk),
  .rd_rst_n(rd_rst_n),
  .rd_en   (rd_en),
  .rd_data (rd_data),
  .rd_empty(rd_empty)
);
```
