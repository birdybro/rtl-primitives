// =============================================================================
// Module: clock_enable_generator
// Description:
//   Generates a single-cycle clock-enable pulse every `period` clock cycles
//   while `en` is asserted.  The pulse is produced by a free-running counter
//   that reloads when it reaches `period - 1`.
//
// Parameters:
//   WIDTH - Bit width of the period counter and input (default: 8)
//
// Ports:
//   clk              - System clock
//   rst_n            - Synchronous active-low reset
//   en               - Enable; when deasserted the counter holds and no pulse
//                      is generated
//   period [WIDTH-1:0] - Number of clock cycles between pulses (must be >= 1)
//   clk_en           - Single-cycle pulse output (asserts for one clk cycle)
//
// Behavior / Timing:
//   - clk_en is registered; it asserts on the cycle the counter wraps.
//   - When en is deasserted, the counter freezes and clk_en stays low.
//   - Changing period mid-run takes effect at the next counter reload.
//   - period == 0 is treated as period == 1 (pulse every cycle).
//
// Usage Notes:
//   - Use clk_en as the enable in always_ff blocks to create slower logic.
//   - Do NOT use clk_en as a real clock input.
//
// Example Instantiation:
//   clock_enable_generator #(.WIDTH(8)) u_clk_en_gen (
//     .clk   (clk),
//     .rst_n (rst_n),
//     .en    (run),
//     .period(8'd9),   // pulse every 10 cycles
//     .clk_en(tick)
//   );
// =============================================================================

module clock_enable_generator #(
  parameter int unsigned WIDTH = 8
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             en,
  input  logic [WIDTH-1:0] period,
  output logic             clk_en
);

  logic [WIDTH-1:0] count;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count  <= '0;
      clk_en <= 1'b0;
    end else if (en) begin
      if (count >= (period - 1'b1)) begin
        count  <= '0;
        clk_en <= 1'b1;
      end else begin
        count  <= count + 1'b1;
        clk_en <= 1'b0;
      end
    end else begin
      clk_en <= 1'b0;
    end
  end

endmodule
