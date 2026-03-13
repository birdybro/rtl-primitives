# RTL Primitives — Examples

Practical design examples that demonstrate how to combine multiple primitives
from this library to build real hardware subsystems.

## Examples

| File | Description | Key Primitives Used |
|------|-------------|---------------------|
| [`multi_channel_dma_controller.sv`](multi_channel_dma_controller.sv) | 4-channel DMA with weighted arbitration and per-channel FIFOs | `weighted_round_robin_arbiter`, `simple_fifo`, `event_counter`, `priority_encoder` |
| [`cdc_data_transfer.sv`](cdc_data_transfer.sv) | Safe clock-domain crossing of a streaming data bus | `async_fifo`, `reset_synchronizer` |
| [`multi_domain_system.sv`](multi_domain_system.sv) | Multi-clock system skeleton with POR, CDC FIFO, arbiter, and output buffering | `power_on_reset`, `reset_controller`, `reset_synchronizer`, `async_fifo`, `round_robin_arbiter`, `clock_activity_detector`, `skid_buffer` |
| [`image_edge_detector.sv`](image_edge_detector.sv) | Streaming image edge-detection pipeline (Sobel Gx) | `line_buffer`, `pipeline_register`, `pipeline_bubble_injector`, `leading_zero_counter` |
| [`uart_tx.sv`](uart_tx.sv) | 8N1 UART transmitter with backpressure-tolerant byte input | `clock_enable_generator`, `skid_buffer` |

## How to Use an Example

Each example is a standalone synthesisable SystemVerilog module. To use one:

1. Copy the example file into your project.
2. Ensure all referenced RTL primitives (listed in the table above) are also
   included in your build or filelist.
3. Adjust the `parameter` values at the top of the module as needed.
4. Instantiate the module in your top-level design.

## Notes

- Examples are illustrative. They omit full error handling, formal properties,
  and integration bus bridges for clarity.
- All examples target both ASIC and FPGA flows unless explicitly noted.
- The `clock_gating_wrapper` and `glitch_free_clock_mux` clock primitives are
  ASIC-only; the examples above do not use them.
