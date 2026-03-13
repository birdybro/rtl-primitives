# Counter Primitives

## Overview

Counter primitives provide loadable, directional, and configurable counters
for general-purpose timing and event-counting applications.

## Module Reference

### `up_counter` — Up Counter

Loadable binary up-counter with overflow detection.

```
Parameters: WIDTH (int, default 8)
Ports: clk, rst_n, en, load, load_val [WIDTH-1:0], count [WIDTH-1:0], overflow
```

- `overflow` asserts for one cycle when the count wraps from MAX to 0.
- `load` takes priority over `en`.

---

### `down_counter` — Down Counter

Loadable binary down-counter with underflow detection.

```
Parameters: WIDTH (int, default 8)
Ports: clk, rst_n, en, load, load_val, count, underflow
```

- `underflow` asserts for one cycle when count wraps from 0 to MAX.

---

### `up_down_counter` — Bidirectional Counter

Loadable counter that counts up when `up_dn=1` and down when `up_dn=0`.

```
Parameters: WIDTH (int)
Ports: clk, rst_n, en, up_dn, load, load_val, count, overflow, underflow
```

---

### `gray_counter` — Gray Counter

Counter whose output changes only one bit per clock, making it safe to
synchronize across clock domains as a CDC pointer.

```
Parameters: WIDTH (int)
Ports: clk, rst_n, en, count_gray [WIDTH-1:0], count_bin [WIDTH-1:0]
```

---

### `saturating_counter` — Saturating Counter

Bidirectional counter that clamps at its maximum and minimum values instead
of wrapping.

```
Parameters: WIDTH (int)
Ports: clk, rst_n, en, up_dn, load, load_val, count, at_max, at_min
```

**Use for:** Branch prediction, congestion controls, leaky-bucket rate limiters.

---

### `event_counter` — Event Counter

Counts rising edges of `event_in`, compares against a programmable `threshold`,
and asserts `threshold_hit`. The `clr` input synchronously resets the count.

```
Parameters: WIDTH (int, default 16)
Ports: clk, rst_n, event_in, threshold, count, threshold_hit, clr
```

---

### `watchdog_timer` — Watchdog Timer

Counts up continuously; must be `kick`-ed before reaching `timeout_val` or
`timeout` fires. Reset (via `rst_n`) clears the timeout.

```
Parameters: TIMEOUT_WIDTH (int, default 16)
Ports: clk, rst_n, kick, timeout_val [TIMEOUT_WIDTH-1:0], timeout
```

---

### `programmable_interval_timer` — Programmable Interval Timer

Generates a periodic `tick` pulse every `period` clock cycles. In `one_shot`
mode the timer stops after the first tick.

```
Parameters: WIDTH (int, default 16)
Ports: clk, rst_n, en, period [WIDTH-1:0], one_shot, tick, count [WIDTH-1:0]
```

## Usage Examples

### Periodic Interrupt Timer

```systemverilog
// Generate tick every 1000 cycles
programmable_interval_timer #(.WIDTH(16)) u_pit (
  .clk     (clk),
  .rst_n   (rst_n),
  .en      (timer_en),
  .period  (16'd1000),
  .one_shot(1'b0),
  .tick    (timer_irq),
  .count   (/* unused */)
);
```

### Watchdog with Software Kick

```systemverilog
watchdog_timer #(.TIMEOUT_WIDTH(20)) u_wdt (
  .clk        (clk),
  .rst_n      (rst_n),
  .kick       (sw_kick),
  .timeout_val(20'd500_000), // 500 k cycles at 100 MHz = 5 ms
  .timeout    (wdt_timeout)
);
```

### Event Threshold Counter

```systemverilog
// Assert threshold_hit after 64 error events
event_counter #(.WIDTH(8)) u_err_cnt (
  .clk          (clk),
  .rst_n        (rst_n),
  .event_in     (rx_error),
  .threshold    (8'd64),
  .count        (err_count),
  .threshold_hit(error_limit),
  .clr          (clr_errors)
);
```
