// =============================================================================
// Module: gray_pointer_sync
// Description:
//   Two-flop synchronizer specialized for ADDR_WIDTH+1 bit Gray-code pointers
//   used in asynchronous FIFOs.  Because Gray-code values change only one bit
//   per increment, even if metastability resolves to the old or new value the
//   result is always a valid pointer (either the current or the previous value).
//
//   This module is instantiated twice inside async_fifo:
//     - Once to synchronize the write pointer into the read domain.
//     - Once to synchronize the read pointer into the write domain.
//
// Parameters:
//   ADDR_WIDTH - FIFO address width.  The pointer bus is ADDR_WIDTH+1 bits
//                wide (the extra MSB is used for full/empty disambiguation).
//                Default: 4 (giving a 5-bit Gray-code pointer bus).
//
// Ports:
//   clk          - Destination clock.
//   rst_n        - Active-low asynchronous reset (destination domain).
//   gray_ptr_in  - Gray-code pointer input from the opposite clock domain
//                  (ADDR_WIDTH+1 bits wide).
//   gray_ptr_out - Synchronized Gray-code pointer in the local clock domain
//                  (ADDR_WIDTH+1 bits wide).
//
// Timing / Behavior Assumptions:
//   - gray_ptr_in must only change by one bit per clock cycle of the SOURCE
//     domain (guaranteed by Gray-code counter increment).
//   - The DONT_TOUCH / async_reg attributes ensure the two capture flops are
//     placed adjacent to each other by the P&R tool.
//   - Latency: 2 destination clock cycles.
//
// Usage Notes:
//   - Always use with Gray-code encoded pointers; do NOT connect binary
//     counters directly as multi-bit metastability is not protected.
//
// Example Instantiation:
//   gray_pointer_sync #(
//     .ADDR_WIDTH(4)
//   ) u_wptr_sync (
//     .clk         (rd_clk),
//     .rst_n       (rd_rst_n),
//     .gray_ptr_in (wr_ptr_gray),
//     .gray_ptr_out(wr_ptr_gray_sync)
//   );
// =============================================================================

module gray_pointer_sync #(
  parameter int ADDR_WIDTH = 4
) (
  input  logic [ADDR_WIDTH:0] gray_ptr_in,
  output logic [ADDR_WIDTH:0] gray_ptr_out,
  input  logic                clk,
  input  logic                rst_n
);

  // Two-stage synchronizer for the (ADDR_WIDTH+1)-bit Gray-code pointer bus.
  (* DONT_TOUCH = "TRUE" *) (* async_reg = "true" *)
  logic [ADDR_WIDTH:0] sync_stage1;
  (* DONT_TOUCH = "TRUE" *) (* async_reg = "true" *)
  logic [ADDR_WIDTH:0] sync_stage2;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_stage1 <= '0;
      sync_stage2 <= '0;
    end else begin
      sync_stage1 <= gray_ptr_in;
      sync_stage2 <= sync_stage1;
    end
  end

  assign gray_ptr_out = sync_stage2;

endmodule
