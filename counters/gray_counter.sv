// =============================================================================
// Module: gray_counter
// Description:
//   Synchronous Gray code counter. The module maintains an internal binary
//   counter and converts it to Gray code each cycle. Because Gray code changes
//   only one bit per step, it is particularly suitable for CDC (clock-domain
//   crossing) scenarios such as asynchronous FIFO pointer comparison.
//
// Parameters:
//   WIDTH  - Counter bit width (default: 4). Both binary and Gray outputs are
//            WIDTH bits wide. Count range: [0, 2^WIDTH - 1].
//
// Ports:
//   clk        - Clock input (rising edge triggered)
//   rst_n      - Active-low synchronous reset; resets both outputs to 0
//   en         - Enable: counter advances only when en=1
//   count_gray - Gray-coded counter value [WIDTH-1:0]
//   count_bin  - Binary counter value [WIDTH-1:0] (convenience output)
//
// Timing/Behavior:
//   - All state changes occur on the rising edge of clk
//   - rst_n is synchronous and active low
//   - The binary counter increments by 1 each enabled clock cycle and wraps
//     naturally from (2^WIDTH - 1) back to 0
//   - Gray code is derived combinationally from the registered binary value:
//       gray[i] = bin[i] ^ bin[i+1]  for i < WIDTH-1
//       gray[WIDTH-1] = bin[WIDTH-1]
//   - count_gray is registered to avoid glitches on the output
//
// Usage Notes:
//   - For CDC pointer usage, register count_gray in the source domain before
//     sampling it in the destination domain
//   - WIDTH should match the address width of the associated FIFO or buffer
//   - count_bin is provided as a convenience for same-domain logic
//
// Example Instantiation:
//   gray_counter #(
//     .WIDTH(4)
//   ) u_gray_counter (
//     .clk        (clk),
//     .rst_n      (rst_n),
//     .en         (count_en),
//     .count_gray (gray_ptr[3:0]),
//     .count_bin  (bin_ptr[3:0])
//   );
// =============================================================================

module gray_counter #(
  parameter int unsigned WIDTH = 4
) (
  input  logic              clk,
  input  logic              rst_n,
  input  logic              en,
  output logic [WIDTH-1:0]  count_gray,
  output logic [WIDTH-1:0]  count_bin
);

  logic [WIDTH-1:0] bin_next;
  logic [WIDTH-1:0] gray_next;

  // Binary-to-Gray conversion (combinational)
  always_comb begin
    bin_next  = en ? (count_bin + 1'b1) : count_bin;
    // XOR each bit with the next-higher bit; MSB passes through unchanged
    gray_next = bin_next ^ (bin_next >> 1);
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count_bin  <= '0;
      count_gray <= '0;
    end else begin
      count_bin  <= bin_next;
      count_gray <= gray_next;
    end
  end

endmodule
