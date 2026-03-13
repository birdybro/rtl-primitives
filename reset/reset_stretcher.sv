// =============================================================================
// Module: reset_stretcher
// Description:
//   Stretches an active-low reset input to guarantee a minimum assertion period
//   of STRETCH_CYCLES clock cycles. Once rst_n is deasserted (goes high), the
//   output stretched_rst_n remains low for STRETCH_CYCLES more cycles before
//   being released. If rst_n reasserts during the stretch window the counter
//   restarts, ensuring the full minimum hold is always satisfied.
//
// Parameters:
//   STRETCH_CYCLES - Minimum number of clock cycles reset is held asserted
//                    after the input rst_n deasserts (default: 16)
//
// Ports:
//   clk            - Clock input
//   rst_n          - Active-low reset input (may be shorter than required)
//   stretched_rst_n - Active-low reset output held for at least STRETCH_CYCLES
//
// Timing/Behavior:
//   - stretched_rst_n asserts (LOW) immediately when rst_n goes LOW
//   - stretched_rst_n deasserts (HIGH) exactly STRETCH_CYCLES clock cycles
//     after rst_n goes HIGH (or after counter expires, whichever is later)
//   - If rst_n reasserts before counter expires, counter reloads to STRETCH_CYCLES
//   - Counter width is automatically sized to hold STRETCH_CYCLES value
//
// Usage Notes:
//   - Use after a power-on-reset source or any reset whose minimum pulse width
//     cannot be guaranteed to meet downstream requirements.
//   - Can be chained after reset_synchronizer for a synchronized stretched reset.
//   - STRETCH_CYCLES must be >= 1.
//
// Example Instantiation:
//   reset_stretcher #(
//     .STRETCH_CYCLES(32)
//   ) u_rst_stretch (
//     .clk            (clk),
//     .rst_n          (raw_rst_n),
//     .stretched_rst_n(clean_rst_n)
//   );
// =============================================================================

module reset_stretcher #(
    parameter int unsigned STRETCH_CYCLES = 16
) (
    input  logic clk,
    input  logic rst_n,
    output logic stretched_rst_n
);

    localparam int unsigned CNT_W = $clog2(STRETCH_CYCLES + 1);

    logic [CNT_W-1:0] count;
    logic             counting;

    // counting is high while the stretch window is active (counter > 0)
    assign counting = (count != '0);

    // stretched_rst_n is low when input reset is asserted OR counter still running
    assign stretched_rst_n = rst_n & ~counting;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= CNT_W'(STRETCH_CYCLES);
        end else begin
            if (counting) begin
                count <= count - 1'b1;
            end
        end
    end

endmodule
