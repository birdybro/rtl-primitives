// =============================================================================
// Module: toggle_synchronizer
// Description:
//   Synchronizes a multi-bit level or toggle signal from a source clock domain
//   to a destination clock domain using a 2-FF synchronizer chain per bit.
//
//   This is a raw structural synchronizer — it does NOT include any handshake
//   or data-valid protocol.  It is the caller's responsibility to ensure that
//   src_data is stable long enough to be reliably captured in the destination
//   domain (minimum: ~3 destination clock cycles of stability per Nyquist
//   rule for multi-bit buses).
//
//   For multi-bit buses wider than 1 bit, all bits must be driven from the
//   SAME source-domain flip-flop update (i.e., all bits must change in the
//   same src_clk edge, or Gray-code-encoded), otherwise bit skew can produce
//   a transient invalid combination in the destination domain.
//
// Parameters:
//   WIDTH - Number of bits to synchronize (default: 1).
//
// Ports:
//   src_clk   - Source clock (used only to register src_data if needed by
//               the instantiating design; the synchronizer itself is driven
//               by dst_clk).
//   src_rst_n - Active-low asynchronous reset (source domain).
//   dst_clk   - Destination clock.
//   dst_rst_n - Active-low asynchronous reset (destination domain).
//   src_data  - Input data bus from the source clock domain.
//   dst_data  - Synchronized output data bus in the destination clock domain.
//
// Timing / Behavior Assumptions:
//   - src_data bits must be stable for at least 3 dst_clk cycles.
//   - Multi-bit buses must only change one bit at a time (e.g., Gray code)
//     to guarantee correct sampling.
//   - Latency: 2 dst_clk cycles.
//
// Usage Notes:
//   - For single-cycle pulse transfer use pulse_synchronizer.
//   - For arbitrary multi-bit data use bundled_data_synchronizer or async_fifo.
//   - src_clk and src_rst_n are included for interface uniformity; internally
//     only dst_clk / dst_rst_n drive the synchronizer flops.
//
// Example Instantiation:
//   toggle_synchronizer #(
//     .WIDTH(4)
//   ) u_tog_sync (
//     .src_clk  (src_clk),
//     .src_rst_n(src_rst_n),
//     .dst_clk  (dst_clk),
//     .dst_rst_n(dst_rst_n),
//     .src_data (src_gray_bus),
//     .dst_data (dst_gray_bus)
//   );
// =============================================================================

module toggle_synchronizer #(
  parameter int WIDTH = 1
) (
  input  logic             src_clk,    // Source clock (informational / unused internally)
  input  logic             src_rst_n,  // Source reset (informational / unused internally)
  input  logic             dst_clk,
  input  logic             dst_rst_n,
  input  logic [WIDTH-1:0] src_data,
  output logic [WIDTH-1:0] dst_data
);

  // Suppress unused-port warnings; these ports exist for interface uniformity.
  logic unused_src;
  assign unused_src = src_clk & src_rst_n;

  // Two-stage synchronizer chain, WIDTH bits wide.
  // Separate declarations ensure synthesis tools apply async_reg per stage.
  (* DONT_TOUCH = "TRUE" *) (* async_reg = "true" *) logic [WIDTH-1:0] stage1;
  (* DONT_TOUCH = "TRUE" *) (* async_reg = "true" *) logic [WIDTH-1:0] stage2;

  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      stage1 <= '0;
      stage2 <= '0;
    end else begin
      stage1 <= src_data;
      stage2 <= stage1;
    end
  end

  assign dst_data = stage2;

endmodule
