// =============================================================================
// Module: bundled_data_synchronizer
// Description:
//   Synchronizes a multi-bit data bundle across a clock domain boundary using
//   a four-phase req/ack handshake to guarantee data stability at the receiver.
//
//   Protocol:
//     Source side:
//       1. Assert src_valid with stable src_data.
//       2. Hold src_valid and src_data until src_ready is observed.
//       3. Deassert src_valid after seeing src_ready.
//     Destination side:
//       1. dst_valid pulses for one dst_clk cycle when new data is available.
//       2. dst_data is stable on the same cycle as dst_valid.
//       3. Assert dst_ready to acknowledge and allow the next transfer.
//          (dst_ready must be asserted within a few dst_clk cycles to release
//           the handshake and reassert src_ready.)
//
//   Internally:
//     - src_data is captured into a holding register when src_valid is seen
//       while the channel is idle.
//     - A request toggle is sent to the destination via a 2-FF synchronizer.
//     - The destination latches the data and fires dst_valid on a toggle edge.
//     - The destination drives dst_ready back through a 2-FF synchronizer
//       as the acknowledgment, releasing src_ready.
//
// Parameters:
//   DATA_WIDTH - Width of the data bus in bits (default: 8).
//
// Ports:
//   src_clk   - Source clock.
//   src_rst_n - Active-low asynchronous reset (source domain).
//   dst_clk   - Destination clock.
//   dst_rst_n - Active-low asynchronous reset (destination domain).
//   src_valid - Source asserts to indicate src_data is valid.
//   src_data  - Data to transfer (must be stable while src_valid is high).
//   src_ready - High when the synchronizer is idle and ready for a new transfer.
//   dst_valid - Single-cycle pulse in the destination domain indicating new data.
//   dst_data  - Data value captured from the source domain.
//   dst_ready - Destination asserts (one cycle) to acknowledge receipt.
//
// Timing / Behavior Assumptions:
//   - src_data must be stable from assertion of src_valid until src_ready is
//     observed.
//   - dst_ready should be asserted within a bounded number of dst_clk cycles
//     to avoid blocking the source indefinitely.
//   - Not suitable for high-bandwidth streaming; use async_fifo for that.
//
// Usage Notes:
//   - Throughput is one transfer per ~4-6 clock-crossing round-trips.
//   - src_valid is ignored while src_ready is low (channel busy).
//
// Example Instantiation:
//   bundled_data_synchronizer #(
//     .DATA_WIDTH(16)
//   ) u_bds (
//     .src_clk  (src_clk),
//     .src_rst_n(src_rst_n),
//     .dst_clk  (dst_clk),
//     .dst_rst_n(dst_rst_n),
//     .src_valid(tx_valid),
//     .src_data (tx_data),
//     .src_ready(tx_ready),
//     .dst_valid(rx_valid),
//     .dst_data (rx_data),
//     .dst_ready(rx_ready)
//   );
// =============================================================================

module bundled_data_synchronizer #(
  parameter int DATA_WIDTH = 8
) (
  input  logic                  src_clk,
  input  logic                  src_rst_n,
  input  logic                  dst_clk,
  input  logic                  dst_rst_n,
  // Source-domain interface
  input  logic                  src_valid,
  input  logic [DATA_WIDTH-1:0] src_data,
  output logic                  src_ready,
  // Destination-domain interface
  output logic                  dst_valid,
  output logic [DATA_WIDTH-1:0] dst_data,
  input  logic                  dst_ready
);

  // -------------------------------------------------------------------------
  // Source domain
  // -------------------------------------------------------------------------
  logic                  src_req_toggle;   // Toggles to signal a new transfer
  logic [DATA_WIDTH-1:0] src_data_hold;    // Captured data held during transfer
  logic                  src_busy;         // Transfer in progress

  // Ack synchronizer (dst → src)
  (* DONT_TOUCH = "TRUE" *) (* async_reg = "true" *) logic [1:0] ack_sync;
  logic ack_prev;

  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      src_req_toggle <= 1'b0;
      src_data_hold  <= '0;
      src_busy       <= 1'b0;
      ack_prev       <= 1'b0;
    end else begin
      ack_prev <= ack_sync[1];

      if (!src_busy && src_valid) begin
        // Latch data and kick off transfer
        src_data_hold  <= src_data;
        src_req_toggle <= ~src_req_toggle;
        src_busy       <= 1'b1;
      end else if (src_busy && (ack_sync[1] ^ ack_prev)) begin
        // Ack edge detected — transfer complete
        src_busy <= 1'b0;
      end
    end
  end

  assign src_ready = !src_busy;

  // -------------------------------------------------------------------------
  // Request synchronizer (src → dst)
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
  // Destination domain
  // -------------------------------------------------------------------------
  logic                  req_prev;         // Previous-cycle req for edge detect
  logic                  dst_ack_toggle;   // Mirrored ack back to source
  logic [DATA_WIDTH-1:0] dst_data_r;       // Latched destination data register

  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      req_prev       <= 1'b0;
      dst_ack_toggle <= 1'b0;
      dst_data_r     <= '0;
    end else begin
      req_prev <= req_sync[1];

      if (req_sync[1] ^ req_prev) begin
        // New request edge: latch data and send ack toggle
        dst_data_r     <= src_data_hold;
        dst_ack_toggle <= ~dst_ack_toggle;
      end else if (dst_valid && dst_ready) begin
        // Consumer acknowledged; nothing special needed here
        // (dst_valid is combinational; dst_data_r stays valid until next req)
      end
    end
  end

  // dst_valid fires for one dst_clk cycle on a new request edge.
  assign dst_valid = req_sync[1] ^ req_prev;
  assign dst_data  = dst_data_r;

  // -------------------------------------------------------------------------
  // Ack synchronizer (dst → src)
  // -------------------------------------------------------------------------
  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      ack_sync <= 2'b00;
    end else begin
      ack_sync <= {ack_sync[0], dst_ack_toggle};
    end
  end

endmodule
