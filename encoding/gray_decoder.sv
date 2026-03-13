// =============================================================================
// Module: gray_decoder
// Description:
//   Converts a Gray-code-encoded value back to standard binary using a
//   cascaded XOR reduction. Each output bit is the XOR of all Gray code bits
//   from the MSB down to that bit position.
//
// Parameters:
//   WIDTH - Bit width of the input and output (default: 8)
//
// Ports:
//   gray_in [WIDTH-1:0] - Gray code input
//   bin_out [WIDTH-1:0] - Decoded binary output
//
// Behavior / Timing:
//   - Fully combinational; output stabilises after O(log2(WIDTH)) gate delays
//     due to the cascaded XOR chain.
//
// Usage Notes:
//   - Pair with gray_encoder for asynchronous FIFO pointer comparison.
//   - The MSB of bin_out equals the MSB of gray_in (no XOR contribution).
//
// Example Instantiation:
//   gray_decoder #(.WIDTH(8)) u_gray_dec (
//     .gray_in(rptr_gray_sync),
//     .bin_out(rptr_bin)
//   );
// =============================================================================

module gray_decoder #(
  parameter int unsigned WIDTH = 8
) (
  input  logic [WIDTH-1:0] gray_in,
  output logic [WIDTH-1:0] bin_out
);

  always_comb begin
    bin_out[WIDTH-1] = gray_in[WIDTH-1];
    for (int i = WIDTH-2; i >= 0; i--) begin
      bin_out[i] = bin_out[i+1] ^ gray_in[i];
    end
  end

endmodule
