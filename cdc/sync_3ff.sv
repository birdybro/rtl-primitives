// =============================================================================
// Module: sync_3ff
// Description:
//   Three-flop synchronizer for metastability protection.  Identical in
//   structure to sync_2ff but adds a third capture flop, which significantly
//   increases the MTBF by giving a metastable event an additional clock period
//   in which to resolve before being sampled downstream.
//
//   Use this variant when:
//     - The destination clock frequency is very high.
//     - The application requires an extremely low probability of metastability
//       propagation (e.g., safety-critical or high-reliability designs).
//
// Parameters:
//   RESET_VAL - Reset value applied to all three flops (default: 1'b0).
//   STAGES    - Provided for interface consistency; fixed at 3 for this module.
//
// Ports:
//   clk   - Destination clock.
//   rst_n - Active-low asynchronous reset (destination domain).
//   d     - Single-bit input from the source clock domain.
//   q     - Synchronized single-bit output in the destination clock domain.
//
// Timing / Behavior Assumptions:
//   - Same constraints as sync_2ff; 'd' must be a stable registered signal.
//   - Adds one extra cycle of latency compared to sync_2ff.
//   - For pulse inputs use pulse_synchronizer instead.
//
// Usage Notes:
//   - Drop-in replacement for sync_2ff where higher MTBF is required.
//   - Only suitable for single-bit signals.
//
// Example Instantiation:
//   sync_3ff #(
//     .RESET_VAL(1'b0)
//   ) u_sync_3ff (
//     .clk  (dst_clk),
//     .rst_n(dst_rst_n),
//     .d    (src_signal),
//     .q    (dst_signal)
//   );
// =============================================================================

module sync_3ff #(
  parameter bit  RESET_VAL = 1'b0,
  parameter int  STAGES    = 3       // Informational only; always 3 in this module
) (
  input  logic clk,
  input  logic rst_n,
  input  logic d,
  output logic q
);

  // Three-stage synchronizer chain.
  (* DONT_TOUCH = "TRUE" *) (* async_reg = "true" *) logic [2:0] sync_ff;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff <= {3{RESET_VAL}};
    end else begin
      sync_ff <= {sync_ff[1:0], d};
    end
  end

  assign q = sync_ff[2];

endmodule
