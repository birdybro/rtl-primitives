// =============================================================================
// Module: sync_2ff
// Description:
//   Two-flop synchronizer for metastability protection when crossing a single-
//   bit signal from one clock domain to another. The (* async_reg = "true" *)
//   attribute directs synthesis and place-and-route tools to keep the flop pair
//   in close proximity and prevents logic optimization across the sync chain.
//
// Parameters:
//   RESET_VAL - Reset value applied to both flops (default: 1'b0).
//   STAGES    - Provided for interface consistency; fixed at 2 for this module.
//
// Ports:
//   clk   - Destination clock.
//   rst_n - Active-low asynchronous reset (destination domain).
//   d     - Single-bit input from the source clock domain.
//   q     - Synchronized single-bit output in the destination clock domain.
//
// Timing / Behavior Assumptions:
//   - The input signal 'd' must be stable for at least one full destination
//     clock period (i.e., it must be a steady level, not a glitch).
//   - For pulse inputs use pulse_synchronizer instead.
//   - MTBF is governed by destination clock frequency and the metastability
//     window of the target technology.  Use sync_3ff where higher MTBF is
//     required.
//
// Usage Notes:
//   - Do NOT drive 'd' from combinational logic; register it in the source
//     domain before connecting to this synchronizer.
//   - Only use for single-bit signals.  For multi-bit buses use a handshake
//     or FIFO-based CDC scheme.
//
// Example Instantiation:
//   sync_2ff #(
//     .RESET_VAL(1'b0)
//   ) u_sync_2ff (
//     .clk  (dst_clk),
//     .rst_n(dst_rst_n),
//     .d    (src_signal),
//     .q    (dst_signal)
//   );
// =============================================================================

module sync_2ff #(
  parameter bit  RESET_VAL = 1'b0,
  parameter int  STAGES    = 2       // Informational only; always 2 in this module
) (
  input  logic clk,
  input  logic rst_n,
  input  logic d,
  output logic q
);

  // Two-stage synchronizer chain.
  // (* DONT_TOUCH = "TRUE" *) prevents Vivado from absorbing these FFs into
  // surrounding logic.  (* async_reg = "true" *) additionally enables the
  // placer to co-locate them for minimal routing delay between stages.
  (* DONT_TOUCH = "TRUE" *) (* async_reg = "true" *) logic [1:0] sync_ff;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff <= {2{RESET_VAL}};
    end else begin
      sync_ff <= {sync_ff[0], d};
    end
  end

  assign q = sync_ff[1];

endmodule
