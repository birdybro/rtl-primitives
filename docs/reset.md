# Reset Management Primitives

## Overview

Correct reset implementation prevents undefined power-up behaviour and
metastability on reset release. All primitives in this library use
**active-low** reset polarity and the **asynchronous-assert /
synchronous-deassert** idiom.

## Async-Assert / Sync-Deassert Pattern

```
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    // reset state
  end else begin
    // normal operation
  end
end
```

- **Assertion** is asynchronous (immediate response to rst_n going low).
- **Deassertion** is synchronous (rst_n must be stable for STAGES clock
  cycles before logic exits reset).

## Module Reference

### `power_on_reset` — Power-On Reset Generator

Uses a shift register with asynchronous preset to generate a guaranteed
power-on reset pulse. Does not require an external reset input.

```
Parameters: DEPTH (int) — minimum reset assertion cycles (default 16)
Ports: clk, por_rst_n (output)
```

**Typical use:** Feed `por_rst_n` into `reset_synchronizer` in every clock
domain.

---

### `reset_synchronizer` — Reset Synchronizer

Synchronizes an asynchronous active-low reset to a clock domain. Assert
asynchronously, deassert synchronously after STAGES cycles.

```
Parameters: STAGES (int ≥ 2, default 2)
Ports: clk, async_rst_n (input), sync_rst_n (output)
```

---

### `reset_bridge` — Reset Domain Bridge

Safe reset crossing between two clock domains. Equivalent to a
`reset_synchronizer` but with an explicit `src_clk` documentation port.

```
Parameters: STAGES (int ≥ 2, default 2)
Ports: src_clk (doc only), src_rst_n, dst_clk, dst_rst_n
```

---

### `reset_stretcher` — Reset Stretcher

Guarantees a minimum reset pulse width. If the input resets for fewer than
STRETCH_CYCLES cycles, the output holds for the full stretch period.

```
Parameters: STRETCH_CYCLES (int, default 16)
Ports: clk, rst_n (input), stretched_rst_n (output)
```

---

### `reset_pulse_generator` — Reset Pulse Generator

Detects the rising edge of a synchronous reset-request signal and generates
an active-high pulse of exactly PULSE_WIDTH clock cycles.

```
Parameters: PULSE_WIDTH (int, default 4)
Ports: clk, rst_n, rst_req (input), rst_pulse (output)
```

---

### `reset_controller` — Multi-Domain Reset Controller

Manages sequenced reset deassertion across multiple clock domains. After a
POR or per-domain request, domains are released in order:
domain 0 first, then domain 1 one STRETCH_CYCLES later, etc.

```
Parameters:
  NUM_DOMAINS    (int, default 4)
  STRETCH_CYCLES (int, default 16)
Ports:
  clk, rst_n
  por_req                       — resets all domains
  rst_req [NUM_DOMAINS-1:0]     — per-domain reset request
  rst_n_out [NUM_DOMAINS-1:0]   — per-domain reset output
```

## Reset Network Design

### Recommended Topology

```
[Power Supply] ──► power_on_reset ──► reset_synchronizer (domain 0)
                                  └──► reset_synchronizer (domain 1)
                                  └──► ...

[SW Reset Button] ──► reset_stretcher ──► reset_bridge ──► domain N
```

### Typical Integration

```systemverilog
// 1. Generate POR
power_on_reset #(.DEPTH(32)) u_por (
  .clk      (fast_clk),
  .por_rst_n(por_rst_n_raw)
);

// 2. Synchronize to each domain
reset_synchronizer #(.STAGES(2)) u_sync_core (
  .clk        (core_clk),
  .async_rst_n(por_rst_n_raw),
  .sync_rst_n (core_rst_n)
);

reset_synchronizer #(.STAGES(2)) u_sync_peri (
  .clk        (peri_clk),
  .async_rst_n(por_rst_n_raw),
  .sync_rst_n (peri_rst_n)
);

// 3. Bridge a soft reset into another domain
reset_bridge #(.STAGES(2)) u_sw_rst_bridge (
  .src_clk  (apb_clk),
  .src_rst_n(sw_rst_n),
  .dst_clk  (dsp_clk),
  .dst_rst_n(dsp_rst_n)
);
```

## Common Mistakes

| Mistake | Correct Practice |
|---------|-----------------|
| Using `if (rst_n == 0)` edge-list | Use `negedge rst_n` in sensitivity list |
| Driving async reset from combinational logic | Register reset through synchronizer first |
| Missing reset on CDC flip-flop | All synchronizer FFs must have reset |
| Releasing reset simultaneously in all domains | Use `reset_controller` for staggered release |
