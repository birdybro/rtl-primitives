// =============================================================================
// Module: glitch_free_clock_mux
// Description:
//   Glitch-free 2:1 clock multiplexer using the classic dual-synchronizer
//   with feedback technique. Ensures no glitch appears on clk_out during
//   clock switching.
//
// Parameters:
//   None
//
// Ports:
//   clk0    - Clock input 0
//   clk1    - Clock input 1
//   sel     - Select: 0 = clk0, 1 = clk1
//   rst_n   - Active-low asynchronous reset (in neither clock domain; resets both)
//   clk_out - Glitch-free muxed clock output
//
// Usage notes:
//   - sel must be quasi-static (change only when both clocks are stable).
//   - Both clocks must be running during a switch for the handshake to complete.
//   - The output clock will momentarily stop for up to 2 cycles of each domain
//     while the handshake completes — this is expected and safe.
//   - rst_n is used asynchronously to bring both synchronizers to a known state.
//
// Timing/Behavior:
//   - sel is synchronized into clk0 domain gated by !sel_clk1_synced feedback.
//   - !sel is synchronized into clk1 domain gated by !sel_clk0_synced feedback.
//   - gated_clk0 = clk0 & sel_clk0_synced (inverted logic: active when sel=0)
//   - gated_clk1 = clk1 & sel_clk1_synced (active when sel=1)
//   - clk_out = gated_clk0 | gated_clk1
//
// Example instantiation:
//   glitch_free_clock_mux u_clk_mux (
//     .clk0    (clk0),
//     .clk1    (clk1),
//     .sel     (use_clk1),
//     .rst_n   (rst_n),
//     .clk_out (sys_clk)
//   );
// =============================================================================

module glitch_free_clock_mux (
  input  logic clk0,
  input  logic clk1,
  input  logic sel,
  input  logic rst_n,
  output logic clk_out
);

  // clk0 domain: synchronize deselect of clk0 (~sel), gated by !sel_clk1_synced
  logic sel_clk0_d1, sel_clk0_synced;

  // clk1 domain: synchronize select of clk1 (sel), gated by !sel_clk0_synced
  logic sel_clk1_d1, sel_clk1_synced;

  // clk0 domain synchronizer — accepts sel=0 only when clk1 has been deselected
  always_ff @(posedge clk0 or negedge rst_n) begin
    if (!rst_n) begin
      sel_clk0_d1    <= 1'b0;
      sel_clk0_synced <= 1'b0;
    end else begin
      sel_clk0_d1    <= (~sel) & (~sel_clk1_synced);
      sel_clk0_synced <= sel_clk0_d1;
    end
  end

  // clk1 domain synchronizer — accepts sel=1 only when clk0 has been deselected
  always_ff @(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
      sel_clk1_d1    <= 1'b0;
      sel_clk1_synced <= 1'b0;
    end else begin
      sel_clk1_d1    <= sel & (~sel_clk0_synced);
      sel_clk1_synced <= sel_clk1_d1;
    end
  end

  logic gated_clk0, gated_clk1;

  // Gate each clock with its domain-local synchronized select
  // sel_clk0_synced=1 means "clk0 is NOT selected" so we invert
  assign gated_clk0 = clk0 & (~sel_clk0_synced);
  assign gated_clk1 = clk1 & sel_clk1_synced;

  assign clk_out = gated_clk0 | gated_clk1;

endmodule
