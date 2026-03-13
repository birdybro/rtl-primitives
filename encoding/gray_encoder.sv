// =============================================================================
// Module: gray_encoder
// Description:
//   Converts a binary-encoded value to its Gray code equivalent using the
//   standard XOR reduction: gray = bin ^ (bin >> 1). This is purely
//   combinational — no clock or reset is required.
//
// Parameters:
//   WIDTH - Bit width of the input and output (default: 8)
//
// Ports:
//   bin_in  [WIDTH-1:0] - Binary input value
//   gray_out[WIDTH-1:0] - Gray code output
//
// Behavior / Timing:
//   - Fully combinational; output changes with input after propagation delay.
//   - Single-bit transitions between adjacent codes guarantee glitch-reduced
//     operation in CDC FIFOs when combined with gray_decoder.
//
// Usage Notes:
//   - Commonly used as the address pointer encoder in asynchronous FIFOs.
//   - Pair with gray_decoder to recover binary from Gray code.
//
// Example Instantiation:
//   gray_encoder #(.WIDTH(8)) u_gray_enc (
//     .bin_in  (wptr_bin),
//     .gray_out(wptr_gray)
//   );
// =============================================================================

module gray_encoder #(
  parameter int unsigned WIDTH = 8
) (
  input  logic [WIDTH-1:0] bin_in,
  output logic [WIDTH-1:0] gray_out
);

  always_comb begin
    gray_out = bin_in ^ (bin_in >> 1);
  end

endmodule
