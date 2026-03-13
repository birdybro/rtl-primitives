// =============================================================================
// Module: req_ack_synchronizer
// Description:
//   Four-phase (req/ack) handshake synchronizer for safe clock domain crossing
//   of a single event with full acknowledgment.
//
//   Four-phase handshake sequence:
//     Phase 1 – Request:    src_req asserted  → req level synchronized to dst
//     Phase 2 – Acknowledge: dst_pulse fires   → ack level synchronized to src
//     Phase 3 – De-request: src_req deasserted → deasserted req synced to dst
//     Phase 4 – De-ack:     dst de-ack synced  → ack deasserted at source
//
//   The full round-trip ensures no pulse is lost and provides flow-control
//   (src_ack pulses once per accepted request).
//
// Parameters:
//   None.
//
// Ports:
//   src_clk   - Source clock.
//   src_rst_n - Active-low asynchronous reset (source domain).
//   dst_clk   - Destination clock.
//   dst_rst_n - Active-low asynchronous reset (destination domain).
//   src_req   - Request pulse (single-cycle) from the source domain.
//               Must be de-asserted until src_ack is received.
//   src_ack   - Acknowledgment pulse back to the source domain, one src_clk
//               cycle wide, fired after dst_pulse is generated.
//   dst_pulse - Single-cycle output pulse in the destination clock domain.
//
// Timing / Behavior Assumptions:
//   - src_req must be de-asserted (or held low) until src_ack is observed.
//   - The round-trip latency is approximately 4 synchronizer stages (each
//     ~2 dst or src cycles), so throughput is limited accordingly.
//   - Both domains must be active during a transfer.
//
// Usage Notes:
//   - Suitable for low-frequency events where worst-case latency is acceptable.
//   - For higher-bandwidth transfers use async_fifo.
//
// Example Instantiation:
//   req_ack_synchronizer u_req_ack (
//     .src_clk  (src_clk),
//     .src_rst_n(src_rst_n),
//     .dst_clk  (dst_clk),
//     .dst_rst_n(dst_rst_n),
//     .src_req  (send_event),
//     .src_ack  (event_accepted),
//     .dst_pulse(dst_event)
//   );
// =============================================================================

module req_ack_synchronizer (
  input  logic src_clk,
  input  logic src_rst_n,
  input  logic dst_clk,
  input  logic dst_rst_n,
  input  logic src_req,
  output logic src_ack,
  output logic dst_pulse
);

  // -------------------------------------------------------------------------
  // Source domain: request toggle register
  // Converts the incoming request pulse into a level that persists until the
  // handshake completes.
  // -------------------------------------------------------------------------
  logic src_req_toggle;   // Toggles on each new request
  logic src_ack_prev;     // Previous cycle's synchronized ack (for edge detect)

  // -------------------------------------------------------------------------
  // Destination domain: req synchronizer (src → dst)
  // -------------------------------------------------------------------------
  (* DONT_TOUCH = "TRUE" *) (* async_reg = "true" *) logic [1:0] req_sync;

  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      req_sync <= 2'b00;
    end else begin
      req_sync <= {req_sync[0], src_req_toggle};
    end
  end

  // -------------------------------------------------------------------------
  // Destination domain: ack toggle register + dst_pulse generation
  // Mirrors the request toggle back to the source as an acknowledgment.
  // -------------------------------------------------------------------------
  logic dst_ack_toggle;   // Follows req_sync[1] (latched on edge detect)
  logic dst_req_prev;     // Previous-cycle req_sync[1] for edge detect

  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      dst_req_prev   <= 1'b0;
      dst_ack_toggle <= 1'b0;
    end else begin
      dst_req_prev <= req_sync[1];
      // On every detected toggle (XOR transition) generate a pulse and mirror
      // the level back to the source.
      if (req_sync[1] ^ dst_req_prev) begin
        dst_ack_toggle <= ~dst_ack_toggle;
      end
    end
  end

  // dst_pulse fires for one dst_clk cycle when a new request edge is detected.
  assign dst_pulse = req_sync[1] ^ dst_req_prev;

  // -------------------------------------------------------------------------
  // Source domain: ack synchronizer (dst → src)
  // -------------------------------------------------------------------------
  (* DONT_TOUCH = "TRUE" *) (* async_reg = "true" *) logic [1:0] ack_sync;

  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      ack_sync <= 2'b00;
    end else begin
      ack_sync <= {ack_sync[0], dst_ack_toggle};
    end
  end

  // -------------------------------------------------------------------------
  // Source domain: request toggle + ack edge detection
  // -------------------------------------------------------------------------
  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      src_req_toggle <= 1'b0;
      src_ack_prev   <= 1'b0;
    end else begin
      // Toggle on new request
      if (src_req) begin
        src_req_toggle <= ~src_req_toggle;
      end
      src_ack_prev <= ack_sync[1];
    end
  end

  // src_ack fires for one src_clk cycle when the synchronized ack toggles.
  assign src_ack = ack_sync[1] ^ src_ack_prev;

endmodule
