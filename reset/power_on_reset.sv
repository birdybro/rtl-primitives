// =============================================================================
// Module: power_on_reset
// Description:
//   Generates a guaranteed power-on reset (POR) pulse using a shift register
//   with an asynchronous all-ones preset. A single "release" flip-flop (no
//   async reset/preset) powers up to 0 on ASIC/FPGA; its LOW state asynchronously
//   presets the shift register to all-ones (reset active). On the first rising
//   clock edge the release FF goes HIGH, releasing the preset. Subsequent clock
//   edges shift zeros in from the MSB. Once all DEPTH bits are zero, por_rst_n
//   deasserts HIGH, ending the power-on reset period.
//
// Parameters:
//   DEPTH - Number of shift-register stages = minimum POR assertion cycles
//           counted from the first rising clock edge (default: 16)
//
// Ports:
//   clk       - Clock input
//   por_rst_n - Active-low power-on reset output
//               LOW for at least DEPTH cycles after first clk edge, then HIGH
//
// Timing/Behavior:
//   - At power-up: release_ff = 0, shift_reg asynchronously preset to all-ones,
//     por_rst_n = LOW
//   - Cycle 1 (first posedge clk): release_ff latches 1 (preset released),
//     shift_reg = DEPTH'(all-ones), por_rst_n still LOW
//   - Cycles 2..DEPTH+1: shift_reg shifts 0 from MSB each cycle
//   - Cycle DEPTH+1: shift_reg = 0, por_rst_n deasserts HIGH permanently
//   - Assumes FFs without explicit reset/preset power up to logic 0 (standard
//     ASIC behavior; also the default on most FPGA families)
//
// Usage Notes:
//   - Feed por_rst_n into reset_synchronizer in each clock domain.
//   - DEPTH should exceed the worst-case PLL lock time in clock cycles.
//   - The module has no external reset input by design (it IS the reset source).
//   - Simulation: the synthesis translate_off initial block ensures the
//     release_ff starts at 0 in simulation to match power-up hardware state.
//
// Example Instantiation:
//   power_on_reset #(
//     .DEPTH(32)
//   ) u_por (
//     .clk      (clk),
//     .por_rst_n(por_rst_n)
//   );
// =============================================================================

module power_on_reset #(
    parameter int unsigned DEPTH = 16
) (
    input  logic clk,
    output logic por_rst_n
);

    logic [DEPTH-1:0] shift_reg;

    // release_ff powers up to 0; its LOW level asynchronously presets shift_reg.
    // It has no async reset so synthesis maps it to a plain FF with power-up = 0.
    logic release_ff;

    // Simulation-only initialisation to match ASIC power-up state.
    // synthesis translate_off
    initial release_ff = 1'b0;
    // synthesis translate_on

    // On the first posedge clk, release_ff latches 1 and holds there forever.
    always_ff @(posedge clk) begin
        release_ff <= 1'b1;
    end

    // shift_reg: async preset to all-ones while release_ff = 0;
    // shifts a 0 in from the MSB each cycle once release_ff = 1.
    // synthesis tools map "negedge release_ff / if (!release_ff)" to the FF
    // asynchronous preset pin, which is asserted during power-up.
    always_ff @(posedge clk or negedge release_ff) begin
        if (!release_ff) begin
            shift_reg <= '1;
        end else begin
            shift_reg <= {1'b0, shift_reg[DEPTH-1:1]};
        end
    end

    // por_rst_n is LOW while any bit of the shift register is 1
    assign por_rst_n = ~(|shift_reg);

endmodule
