# RTL Primitives — Documentation Overview

Open-source SystemVerilog building-block library for FPGA and ASIC designers.

## Directory Structure

| Directory | Description |
|-----------|-------------|
| `arbiters/` | Request-grant arbitration primitives |
| `bitops/` | Bit manipulation and counting primitives |
| `cdc/` | Clock-domain crossing primitives |
| `clock/` | Clock management primitives |
| `counters/` | Counter primitives |
| `encoding/` | Encoding and decoding primitives |
| `handshake/` | Ready/valid handshake flow-control primitives |
| `memory/` | Memory and buffer primitives |
| `pipeline/` | Pipeline-stage control primitives |
| `reset/` | Reset management primitives |
| `testbenches/` | Self-checking simulation testbenches |
| `examples/` | Complete design examples using multiple primitives |
| `docs/` | Reference documentation (this directory) |

## Quick Reference

### Arbiters
| Module | Description |
|--------|-------------|
| `fixed_priority_arbiter` | Lowest-index request always wins |
| `round_robin_arbiter` | Rotating fair grant among requestors |
| `fair_rotating_arbiter` | Fair round-robin with rotation |
| `masked_priority_arbiter` | Fixed priority with enable mask per requestor |
| `parking_arbiter` | Round-robin that holds (parks) last grant when idle |
| `tree_arbiter` | Tree-structured priority arbiter |
| `weighted_round_robin_arbiter` | Round-robin with per-requestor weight |

### Bit Operations
| Module | Description |
|--------|-------------|
| `barrel_shifter` | Logical and arithmetic left/right shift |
| `leading_zero_counter` | Count leading zeros from MSB |
| `trailing_zero_counter` | Count trailing zeros from LSB |
| `popcount` | Count the number of set bits |
| `priority_encoder` | Lowest-index set-bit to binary index |
| `onehot_encoder` | One-hot to binary (OR-reduction) |
| `onehot_decoder` | Binary index to one-hot |
| `rotate_unit` | Rotate left or right |
| `thermometer_encoder` | Binary count to unary (thermometer) code |

### Clock-Domain Crossing
| Module | Description |
|--------|-------------|
| `sync_2ff` | Two flip-flop synchronizer |
| `sync_3ff` | Three flip-flop synchronizer |
| `pulse_synchronizer` | Single-pulse transfer across clock domains |
| `req_ack_synchronizer` | Request-acknowledge handshake across clock domains |
| `toggle_synchronizer` | Level signal transfer using toggle encoding |
| `bundled_data_synchronizer` | Data + handshake transfer across clock domains |
| `gray_pointer_sync` | Synchronize a Gray-coded pointer |
| `async_fifo` | Asynchronous FIFO with gray-code pointers |

### Clock Management
| Module | Description |
|--------|-------------|
| `clock_divider` | Integer clock divider (enable output) |
| `clock_enable_generator` | Periodic single-cycle enable pulse |
| `clock_gating_wrapper` | ASIC latch-based clock gate with test enable |
| `glitch_free_clock_mux` | Glitch-free 2:1 clock multiplexer |
| `pulse_generator` | One-shot pulse of configurable width |
| `clock_activity_detector` | Detect whether a clock is toggling |

### Counters
| Module | Description |
|--------|-------------|
| `up_counter` | Loadable up counter with overflow |
| `down_counter` | Loadable down counter with underflow |
| `up_down_counter` | Loadable bidirectional counter |
| `gray_counter` | Gray-code counter |
| `saturating_counter` | Bidirectional saturating counter |
| `event_counter` | Count events with threshold compare |
| `watchdog_timer` | Timeout counter reset by kick |
| `programmable_interval_timer` | Repeating/one-shot interval timer |

### Encoding
| Module | Description |
|--------|-------------|
| `binary_decoder` | Binary index to one-hot with enable |
| `binary_encoder` | Binary index to one-hot (no enable) |
| `bitmask_generator` | Generate consecutive-bit mask from offset and length |
| `gray_encoder` | Binary to Gray code |
| `gray_decoder` | Gray code to binary |
| `onehot_encoder` | One-hot to binary index with valid |
| `priority_encoder` | First-set-bit to binary index with valid |

### Handshake / Flow Control
| Module | Description |
|--------|-------------|
| `skid_buffer` | 2-entry buffer absorbing backpressure |
| `ready_valid_stage` | Single registered ready/valid pipeline stage |
| `pipeline_register_slice` | Full/cut-through register slice |
| `elastic_buffer` | Deeper buffering for burstable streams |
| `backpressure_adapter` | Absorb bursts; assert overflow when full |
| `mailbox_fifo` | Single-entry mailbox with ready/valid |
| `credit_flow_controller` | Credit-based flow control |

### Memory
| Module | Description |
|--------|-------------|
| `simple_fifo` | Synchronous FIFO with count output |
| `circular_buffer` | Ring buffer (FIFO semantics, ring-pointer style) |
| `dual_port_ram` | True dual-port synchronous RAM |
| `register_file` | Multi-read-port register file with forwarding |
| `content_addressable_memory` | Fully-associative CAM |
| `line_buffer` | Streaming image line buffer |

### Pipeline
| Module | Description |
|--------|-------------|
| `pipeline_register` | Single registered stage with flush and valid |
| `delay_line` | Configurable-depth shift register with taps |
| `latency_balancer` | Align two paths of different latencies |
| `pipeline_bubble_injector` | Squash a beat and insert a NOP |
| `pipeline_fork` | Replicate one stream to multiple consumers |
| `pipeline_join` | Merge multiple streams into one |

### Reset Management
| Module | Description |
|--------|-------------|
| `power_on_reset` | Shift-register POR generator |
| `reset_synchronizer` | Async-assert / sync-deassert reset synchronizer |
| `reset_bridge` | Bridge a reset across clock domains |
| `reset_stretcher` | Extend reset to a minimum pulse width |
| `reset_pulse_generator` | Generate a synchronous reset pulse on request |
| `reset_controller` | Multi-domain sequenced reset controller |

## Conventions

- All modules use **active-low asynchronous reset** (`rst_n`) unless otherwise noted.
- Synchronous logic is `always_ff @(posedge clk or negedge rst_n)`.
- Parameters use `ALL_CAPS_SNAKE_CASE`.
- Port directions follow the pattern: inputs first, then outputs.
- Combinational modules do **not** include a clock port.

## Per-Category Documentation

- [arbiters.md](arbiters.md) — Arbiter design patterns and usage guide
- [cdc.md](cdc.md) — Clock-domain crossing guidelines
- [handshake.md](handshake.md) — Ready/valid handshake protocol reference
- [pipeline.md](pipeline.md) — Pipeline design patterns
- [memory.md](memory.md) — Memory primitive reference
- [counters.md](counters.md) — Counter and timer reference
- [reset.md](reset.md) — Reset management guide
- [clock.md](clock.md) — Clock management guide
- [encoding.md](encoding.md) — Encoding primitives reference
- [bitops.md](bitops.md) — Bit operation primitives reference
