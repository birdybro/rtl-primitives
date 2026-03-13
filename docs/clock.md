# Clock Management Primitives

## Overview

Clock management primitives generate clock enables, detect clock activity,
gate clocks safely, and multiplex clock sources without glitches.

> **FPGA Note:** Do not use `clock_gating_wrapper` or `glitch_free_clock_mux`
> on FPGAs. Use clock-enable inputs on flip-flops instead. The other modules
> (`clock_divider`, `clock_enable_generator`, `pulse_generator`,
> `clock_activity_detector`) are safe for FPGA use.

## Module Reference

### `clock_divider` — Clock Divider

Divides the input clock by an integer factor `DIV_BY`, producing a
single-cycle active-high enable pulse at the divided rate.

```
Parameters:
  WIDTH  (int unsigned) — counter width
  DIV_BY (int unsigned) — division ratio

Ports: clk, rst_n, en, div_clk_en (output enable)
```

Output is a clock **enable**, not a gated clock — always feed it to flip-flop
CE inputs.

---

### `clock_enable_generator` — Clock Enable Generator

Generates a single-cycle enable pulse every `period` clock cycles while `en`
is asserted. The period is runtime-programmable.

```
Parameters: WIDTH (int unsigned, default 8)
Ports: clk, rst_n, en, period [WIDTH-1:0], clk_en
```

---

### `pulse_generator` — Pulse Generator

Generates a one-shot active-high pulse of configurable width on detection of
a rising edge on `trigger`.

```
Parameters: WIDTH (int unsigned, default 8)
Ports: clk, rst_n, trigger, pulse_width [WIDTH-1:0], pulse_out
```

A new trigger while a pulse is active is ignored.
`pulse_width=0` produces no pulse.

---

### `clock_gating_wrapper` — Clock Gate (ASIC only)

Safe ASIC clock gate using a level-sensitive latch to capture the enable
during the low phase of the clock, preventing glitches.

```
Ports: clk, en, te (test enable / scan bypass), gated_clk
```

Synthesis tools map this to an Integrated Clock Gate (ICG) cell.

---

### `glitch_free_clock_mux` — Glitch-Free Clock Mux (ASIC)

2:1 clock multiplexer that never produces glitches during switching.
Uses dual-synchronizer with feedback handshake.

```
Ports: clk0, clk1, sel, rst_n, clk_out
```

`sel=0` → clk0, `sel=1` → clk1. Both clocks must be running during a switch.

---

### `clock_activity_detector` — Clock Activity Detector

Detects whether a monitored clock is toggling within a sliding window of
reference clock cycles.

```
Parameters: WINDOW_CYCLES (int unsigned, default 16)
Ports: ref_clk, rst_n, mon_clk, active
```

`active` deasserts if `mon_clk` stops toggling for more than WINDOW_CYCLES
reference clock cycles.

## Usage Examples

### Slow Domain Enable (FPGA-safe)

```systemverilog
// Generate 10 MHz enable from 100 MHz clock
clock_divider #(
  .WIDTH (8),
  .DIV_BY(10)
) u_div (
  .clk       (clk_100),
  .rst_n     (rst_n),
  .en        (1'b1),
  .div_clk_en(slow_en)
);

always_ff @(posedge clk_100) begin
  if (slow_en) begin
    // runs at 10 MHz effective rate
  end
end
```

### Programmable Baud Rate

```systemverilog
clock_enable_generator #(.WIDTH(16)) u_baud (
  .clk   (clk),
  .rst_n (rst_n),
  .en    (uart_en),
  .period(baud_period), // set at runtime
  .clk_en(baud_tick)
);
```

### Monitor External Clock

```systemverilog
clock_activity_detector #(.WINDOW_CYCLES(32)) u_mon (
  .ref_clk(sys_clk),
  .rst_n  (rst_n),
  .mon_clk(ext_clk),
  .active (ext_clk_ok)
);
```
