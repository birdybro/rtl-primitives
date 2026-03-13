// =============================================================================
// Module: reset_bridge
// Description:
//   Safely bridges an active-low reset from a source clock domain into a
//   destination clock domain. Uses the same async-assert / sync-deassert
//   two-stage synchronizer principle as reset_synchronizer: the reset is
//   asserted immediately in the destination domain and deasserted only after
//   STAGES stable clock cycles of the destination clock, preventing
//   metastability on reset release from reaching downstream logic.
//
// Parameters:
//   STAGES - Number of synchronizer flip-flop stages in the destination domain
//            (default: 2, minimum: 2)
//
// Ports:
//   src_clk   - Source clock (used only for documentation; reset is async-asserted)
//   src_rst_n - Active-low reset input from source clock domain
//   dst_clk   - Destination clock input
//   dst_rst_n - Active-low synchronized reset output in destination clock domain
//
// Timing/Behavior:
//   - src_rst_n LOW  => dst_rst_n asserts LOW asynchronously (within one gate delay)
//   - src_rst_n HIGH => dst_rst_n releases HIGH after STAGES dst_clk cycles
//   - src_clk is not used in logic; it is present as a documentation port to
//     make domain crossing intent explicit in netlists and schematics
//   - Assumes src_rst_n meets minimum pulse width > 1 dst_clk period
//
// Usage Notes:
//   - Use whenever a reset must cross from one clock domain to another.
//   - For multiple destinations, instantiate one reset_bridge per domain.
//   - STAGES >= 3 is recommended for dst_clk frequencies above ~500 MHz.
//   - Do NOT use dst_rst_n to drive logic in the src_clk domain.
//
// Example Instantiation:
//   reset_bridge #(
//     .STAGES(2)
//   ) u_rst_bridge (
//     .src_clk  (clk_a),
//     .src_rst_n(rst_n_a),
//     .dst_clk  (clk_b),
//     .dst_rst_n(rst_n_b)
//   );
// =============================================================================

module reset_bridge #(
    parameter int unsigned STAGES = 2
) (
    input  logic src_clk,   // source domain clock (documentation / lint only)
    input  logic src_rst_n,
    input  logic dst_clk,
    output logic dst_rst_n
);

    // Suppress unused-port warnings for src_clk; it is intentionally not driven
    // into logic — its purpose is to document the source clock domain.
    (* keep *) logic unused_src_clk;
    assign unused_src_clk = src_clk;

    // Synchronizer chain: async assert, sync deassert in dst_clk domain
    logic [STAGES-1:0] sync_chain;

    always_ff @(posedge dst_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            sync_chain <= '0;
        end else begin
            sync_chain <= {sync_chain[STAGES-2:0], 1'b1};
        end
    end

    assign dst_rst_n = sync_chain[STAGES-1];

endmodule
