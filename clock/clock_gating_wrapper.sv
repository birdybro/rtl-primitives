// =============================================================================
// Module: clock_gating_wrapper
// Description:
//   Safe clock gating wrapper using an ASIC-style level-sensitive latch to
//   capture the enable signal during the low phase of the clock, preventing
//   glitches on the gated clock output.
//
// Parameters:
//   None
//
// Ports:
//   clk        - Input clock
//   en         - Clock enable (functional)
//   te         - Test enable (scan/DFT bypass; forces clock on during test)
//   gated_clk  - Gated clock output
//
// Usage notes:
//   - ASIC: This implementation uses a latch. Ensure your synthesis tool
//     recognizes the clock-gating idiom and maps it to an integrated clock
//     gate (ICG) cell from your standard cell library.
//   - FPGA: Do NOT use this module. Instead, use a clock enable on the
//     destination flip-flop (always_ff @(posedge clk) if (en) ...).
//     Most FPGA tools will not correctly infer a gated clock from this style.
//   - te should be tied low in non-DFT flows.
//
// Timing/Behavior:
//   - The latch is transparent when clk=0, capturing (en | te).
//   - gated_clk = clk & latch_out; the latch output is stable before clk rises,
//     ensuring a glitch-free output clock.
//
// Example instantiation:
//   clock_gating_wrapper u_cg (
//     .clk       (clk),
//     .en        (module_enable),
//     .te        (scan_test_en),
//     .gated_clk (gated_clk)
//   );
// =============================================================================

module clock_gating_wrapper (
  input  logic clk,
  input  logic en,
  input  logic te,
  output logic gated_clk
);

  logic latch_out;

  // Level-sensitive latch: transparent when clk is low.
  // Synthesis tools map this to an integrated clock gate (ICG) cell.
  // pragma translate_off / on not needed; this is standard ICG inference.
  always_latch begin
    if (!clk) begin
      latch_out = en | te;
    end
  end

  assign gated_clk = clk & latch_out;

endmodule
