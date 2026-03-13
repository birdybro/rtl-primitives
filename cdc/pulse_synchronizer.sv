// =============================================================================
// Module: pulse_synchronizer
// Description:
//   Synchronizes a single-cycle pulse from a source clock domain to a
//   destination clock domain using the toggle-detect method.
//
//   Operation:
//     1. A rising edge on src_pulse toggles an internal flip-flop (toggle_ff)
//        in the source domain.
//     2. The toggled level is synchronized to the destination domain through a
//        2-FF synchronizer.
//     3. An edge detector on the synchronized signal produces a single-cycle
//        pulse (dst_pulse) in the destination domain.
//
//   This method is safe when the source pulse rate is low enough that
//   consecutive pulses are separated by more than the synchronizer latency
//   (~2-3 destination clock cycles + round-trip if acknowledgment is used).
//
// Parameters:
//   None.
//
// Ports:
//   src_clk   - Source clock.
//   src_rst_n - Active-low asynchronous reset (source domain).
//   dst_clk   - Destination clock.
//   dst_rst_n - Active-low asynchronous reset (destination domain).
//   src_pulse - Single-cycle pulse input in the source clock domain.
//   dst_pulse - Single-cycle pulse output in the destination clock domain.
//
// Timing / Behavior Assumptions:
//   - src_pulse must be exactly one src_clk cycle wide.
//   - Back-to-back pulses on src_pulse are NOT supported; the caller must
//     ensure at least (2 * dst_clk period + 1 src_clk period) between pulses,
//     or use req_ack_synchronizer for fully acknowledged transfers.
//   - Latency: 2-3 dst_clk cycles after the src toggle is captured.
//
// Usage Notes:
//   - For multi-bit data transfers use bundled_data_synchronizer or async_fifo.
//   - For acknowledged single-shot events use req_ack_synchronizer.
//
// Example Instantiation:
//   pulse_synchronizer u_pulse_sync (
//     .src_clk  (src_clk),
//     .src_rst_n(src_rst_n),
//     .dst_clk  (dst_clk),
//     .dst_rst_n(dst_rst_n),
//     .src_pulse(src_event),
//     .dst_pulse(dst_event)
//   );
// =============================================================================

module pulse_synchronizer (
  input  logic src_clk,
  input  logic src_rst_n,
  input  logic dst_clk,
  input  logic dst_rst_n,
  input  logic src_pulse,
  output logic dst_pulse
);

  // -------------------------------------------------------------------------
  // Source domain: toggle flip-flop
  // Each pulse on src_pulse flips toggle_ff, converting the pulse into a
  // level change that persists until the next pulse.
  // -------------------------------------------------------------------------
  logic toggle_ff;

  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      toggle_ff <= 1'b0;
    end else if (src_pulse) begin
      toggle_ff <= ~toggle_ff;
    end
  end

  // -------------------------------------------------------------------------
  // Destination domain: 2-FF synchronizer
  // -------------------------------------------------------------------------
  (* DONT_TOUCH = "TRUE" *) (* async_reg = "true" *) logic [1:0] sync_ff;

  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      sync_ff <= 2'b00;
    end else begin
      sync_ff <= {sync_ff[0], toggle_ff};
    end
  end

  // -------------------------------------------------------------------------
  // Destination domain: edge detector
  // An XOR between the two synchronized stages detects any toggle transition
  // and produces a single-cycle pulse.
  // -------------------------------------------------------------------------
  logic sync_prev;

  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      sync_prev <= 1'b0;
    end else begin
      sync_prev <= sync_ff[1];
    end
  end

  assign dst_pulse = sync_ff[1] ^ sync_prev;

endmodule
