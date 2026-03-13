// =============================================================================
// Module: trailing_zero_counter
// Description:
//   Counts the number of consecutive zero bits starting from the least-
//   significant bit (LSB) of the input vector. If all bits are zero,
//   'all_zero' is asserted and 'count' equals WIDTH.
//
// Parameters:
//   WIDTH - Bit width of the input vector (default: 8). Must be >= 1.
//
// Ports:
//   in       [WIDTH-1:0]              - Input vector
//   count    [$clog2(WIDTH+1)-1:0]    - Number of trailing zeros (0..WIDTH)
//   all_zero                          - Asserted when in == '0
//
// Behavior:
//   Combinational. Scans from bit [0] upward and increments count until a
//   '1' is encountered. 'count' equals WIDTH when all bits are zero.
//
// Timing Assumptions:
//   Pure combinational; output settles after input propagation delay.
//
// Usage Notes:
//   - Useful for determining alignment of addresses or finding the lowest set
//     bit position.
//   - 'count' width is $clog2(WIDTH+1) to represent the value WIDTH
//     (all-zeros case).
//
// Example Instantiation:
//   trailing_zero_counter #(
//     .WIDTH(32)
//   ) u_tzc (
//     .in      (data_bus),
//     .count   (tz_count),
//     .all_zero(data_zero)
//   );
// =============================================================================

module trailing_zero_counter #(
  parameter int WIDTH = 8
) (
  input  logic [WIDTH-1:0]            in,
  output logic [$clog2(WIDTH+1)-1:0]  count,
  output logic                        all_zero
);

  always_comb begin
    count    = $clog2(WIDTH+1)'(WIDTH);
    all_zero = ~|in;
    // Walk from LSB upward; once a '1' is seen, latch the count. A found
    // flag avoids non-synthesisable 'break' statements.
    begin
      logic found;
      found = 1'b0;
      for (int i = 0; i < WIDTH; i++) begin
        if (!found && in[i]) begin
          count = ($clog2(WIDTH+1))'(unsigned'(i));
          found = 1'b1;
        end
      end
    end
  end

endmodule
