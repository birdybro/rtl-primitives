// =============================================================================
// Module: reset_synchronizer
// Description:
//   Synchronizes an asynchronous reset to a clock domain using a multi-stage
//   flip-flop chain. The reset is asserted asynchronously (immediately on
//   async_rst_n going low) and deasserted synchronously (only after STAGES
//   clock cycles once async_rst_n is released). This prevents metastability
//   on reset deassertion while still ensuring fast response to reset assertion.
//
// Parameters:
//   STAGES    - Number of synchronizer flip-flop stages (default: 2, minimum: 2)
//   RESET_VAL - Unused structural parameter reserved for future polarity use;
//               reset chain uses active-low convention throughout
//
// Ports:
//   clk        - Clock input
//   async_rst_n - Asynchronous active-low reset input (may be glitchy / unclocked)
//   sync_rst_n  - Synchronized active-low reset output; asserts async, deasserts sync
//
// Timing/Behavior:
//   - async_rst_n LOW  => sync_rst_n driven LOW asynchronously (same cycle)
//   - async_rst_n HIGH => sync_rst_n released HIGH after STAGES clock cycles
//   - Assumes async_rst_n meets minimum pulse width > 1 clock period
//   - No combinatorial glitches on sync_rst_n output after synchronization
//
// Usage Notes:
//   - Place this module at the boundary of every clock domain that receives an
//     external or cross-domain asynchronous reset.
//   - Increase STAGES to 3 for clock frequencies above ~500 MHz or where MTBF
//     requirements are stringent.
//   - Do NOT use sync_rst_n as an asynchronous reset in downstream logic.
//
// Example Instantiation:
//   reset_synchronizer #(
//     .STAGES(2)
//   ) u_rst_sync (
//     .clk        (core_clk),
//     .async_rst_n(sys_rst_n),
//     .sync_rst_n (core_rst_n)
//   );
// =============================================================================

/* verilator lint_off UNUSEDPARAM */
module reset_synchronizer #(
    parameter int unsigned STAGES    = 2,
    parameter int unsigned RESET_VAL = 0  // reserved; active-low polarity assumed
)
/* verilator lint_on UNUSEDPARAM */ (
    input  logic clk,
    input  logic async_rst_n,
    output logic sync_rst_n
);

    // Synchronizer chain: all FFs reset to 0 (reset active) on async assertion
    logic [STAGES-1:0] sync_chain;

    always_ff @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            sync_chain <= '0;
        end else begin
            sync_chain <= {sync_chain[STAGES-2:0], 1'b1};
        end
    end

    assign sync_rst_n = sync_chain[STAGES-1];

endmodule
