// =============================================================================
// Module: clock_divider
// Description:
//   Divides the input clock by an integer factor DIV_BY and outputs a
//   synchronous clock enable pulse (div_clk_en). The output is NOT a real
//   clock signal — it is a single-cycle strobe that should gate logic inside
//   an always_ff block clocked by the original clk.
//
// Parameters:
//   WIDTH   - Bit-width of the internal counter (default 8)
//   DIV_BY  - Division factor; output pulses every DIV_BY input cycles (default 4)
//
// Ports:
//   clk        - Input clock
//   rst_n      - Active-low synchronous reset
//   en         - Clock enable; when low the counter is frozen and no pulse is emitted
//   div_clk_en - Output clock-enable strobe, one cycle wide, every DIV_BY cycles
//
// Usage notes:
//   - Use div_clk_en as a gate inside an always_ff block, not as a clock input.
//   - DIV_BY must be >= 2 and must fit within WIDTH bits (DIV_BY <= 2**WIDTH).
//   - The first pulse occurs DIV_BY cycles after reset de-assertion (assuming en=1).
//
// Timing/Behavior:
//   - div_clk_en is asserted for exactly one clk cycle when the counter reaches
//     DIV_BY-1, then the counter wraps back to 0.
//   - Synchronous reset drives the counter to 0 and deasserts div_clk_en.
//
// Example instantiation:
//   clock_divider #(
//     .WIDTH  (8),
//     .DIV_BY (4)
//   ) u_clk_div (
//     .clk        (clk),
//     .rst_n      (rst_n),
//     .en         (1'b1),
//     .div_clk_en (div_clk_en)
//   );
//
//   always_ff @(posedge clk) begin
//     if (div_clk_en) begin
//       // logic running at clk/DIV_BY rate
//     end
//   end
// =============================================================================

module clock_divider #(
  parameter int unsigned WIDTH  = 8,
  parameter int unsigned DIV_BY = 4
) (
  input  logic clk,
  input  logic rst_n,
  input  logic en,
  output logic div_clk_en
);

  logic [WIDTH-1:0] count;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count      <= '0;
      div_clk_en <= 1'b0;
    end else if (en) begin
      if (count == WIDTH'(DIV_BY - 1)) begin
        count      <= '0;
        div_clk_en <= 1'b1;
      end else begin
        count      <= count + 1'b1;
        div_clk_en <= 1'b0;
      end
    end else begin
      div_clk_en <= 1'b0;
    end
  end

endmodule
