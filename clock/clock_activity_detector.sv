// =============================================================================
// Module: clock_activity_detector
// Description:
//   Detects whether a monitored clock (mon_clk) is toggling within a sliding
//   window of reference clock (ref_clk) cycles. The output 'active' is
//   asserted when at least one toggle has been detected in the last
//   WINDOW_CYCLES ref_clk cycles.
//
// Parameters:
//   WINDOW_CYCLES - Number of ref_clk cycles in the detection window (default 16)
//
// Ports:
//   ref_clk  - Reference clock (detection runs in this domain)
//   rst_n    - Active-low synchronous reset (in ref_clk domain)
//   mon_clk  - Monitored clock input
//   active   - Output: 1 if mon_clk toggled within the last WINDOW_CYCLES ref_clk cycles
//
// Usage notes:
//   - mon_clk and ref_clk are asynchronous to each other.
//   - A 2-FF synchronizer is used to safely transfer the toggle flag.
//   - WINDOW_CYCLES should be large enough relative to the expected mon_clk
//     frequency to guarantee at least one toggle per window when active.
//   - rst_n resets all ref_clk-domain logic; the toggle FF in the mon_clk
//     domain is reset asynchronously by rst_n as well.
//
// Timing/Behavior:
//   - A toggle flip-flop in the mon_clk domain flips on every mon_clk edge.
//   - The toggle signal is synchronized into ref_clk domain via 2-FF synchronizer.
//   - Every WINDOW_CYCLES ref_clk cycles, the current synchronized value is
//     compared to the previous snapshot; a difference means mon_clk was active.
//
// Example instantiation:
//   clock_activity_detector #(.WINDOW_CYCLES(16)) u_act_det (
//     .ref_clk (ref_clk),
//     .rst_n   (rst_n),
//     .mon_clk (mon_clk),
//     .active  (mon_clk_active)
//   );
// =============================================================================

module clock_activity_detector #(
  parameter int unsigned WINDOW_CYCLES = 16
) (
  input  logic ref_clk,
  input  logic rst_n,
  input  logic mon_clk,
  output logic active
);

  // -------------------------------------------------------------------------
  // Toggle FF in mon_clk domain
  // -------------------------------------------------------------------------
  logic toggle_ff;

  always_ff @(posedge mon_clk or negedge rst_n) begin
    if (!rst_n)
      toggle_ff <= 1'b0;
    else
      toggle_ff <= ~toggle_ff;
  end

  // -------------------------------------------------------------------------
  // 2-FF synchronizer into ref_clk domain
  // -------------------------------------------------------------------------
  logic sync_d1, sync_d2;

  always_ff @(posedge ref_clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_d1 <= 1'b0;
      sync_d2 <= 1'b0;
    end else begin
      sync_d1 <= toggle_ff;
      sync_d2 <= sync_d1;
    end
  end

  // -------------------------------------------------------------------------
  // Window counter and activity detection (ref_clk domain)
  // -------------------------------------------------------------------------
  localparam int unsigned CTR_W = $clog2(WINDOW_CYCLES + 1);

  logic [CTR_W-1:0] window_ctr;
  logic             snapshot;
  logic             window_done;

  always_comb begin
    window_done = (window_ctr == CTR_W'(WINDOW_CYCLES - 1));
  end

  always_ff @(posedge ref_clk or negedge rst_n) begin
    if (!rst_n) begin
      window_ctr <= '0;
      snapshot   <= 1'b0;
      active     <= 1'b0;
    end else begin
      if (window_done) begin
        window_ctr <= '0;
        snapshot   <= sync_d2;
        active     <= (sync_d2 != snapshot);
      end else begin
        window_ctr <= window_ctr + 1'b1;
      end
    end
  end

endmodule
