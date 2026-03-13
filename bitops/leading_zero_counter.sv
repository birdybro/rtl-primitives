// =============================================================================
// Module: leading_zero_counter
// Description:
//   Counts the number of consecutive zero bits starting from the most-
//   significant bit (MSB) of the input vector. If all bits are zero,
//   'all_zero' is asserted and 'count' equals WIDTH.
//
// Parameters:
//   WIDTH - Bit width of the input vector (default: 8). Must be >= 1.
//
// Ports:
//   in       [WIDTH-1:0]              - Input vector
//   count    [$clog2(WIDTH+1)-1:0]    - Number of leading zeros (0..WIDTH)
//   all_zero                          - Asserted when in == '0
//
// Behavior:
//   Combinational. Scans from bit [WIDTH-1] downward and increments count
//   until a '1' is encountered. 'count' saturates at WIDTH when all_zero.
//
// Timing Assumptions:
//   Pure combinational; output settles after input propagation delay.
//
// Usage Notes:
//   - Useful for normalisation in floating-point pre-processing and
//     leading-zero anticipation in ALUs.
//   - 'count' width is $clog2(WIDTH+1) to represent the value WIDTH
//     (all-zeros case).
//
// Example Instantiation:
//   leading_zero_counter #(
//     .WIDTH(32)
//   ) u_lzc (
//     .in      (mantissa),
//     .count   (lz_count),
//     .all_zero(mantissa_zero)
//   );
// =============================================================================

module leading_zero_counter #(
  parameter int WIDTH = 8
) (
  input  logic [WIDTH-1:0]            in,
  output logic [$clog2(WIDTH+1)-1:0]  count,
  output logic                        all_zero
);

  always_comb begin
    count    = $clog2(WIDTH+1)'(WIDTH);
    all_zero = ~|in;
    // Walk from MSB downward; once a '1' is seen, latch the count and stop
    // updating. A found flag avoids non-synthesisable 'break' statements.
    begin
      logic found;
      found = 1'b0;
      for (int i = WIDTH-1; i >= 0; i--) begin
        if (!found && in[i]) begin
          count = ($clog2(WIDTH+1))'(unsigned'(WIDTH - 1 - i));
          found = 1'b1;
        end
      end
    end
  end

endmodule
