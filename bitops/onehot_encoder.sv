// =============================================================================
// Module: onehot_encoder
// Description:
//   Encodes a one-hot input vector to a binary index using OR reduction.
//   Each output bit is the OR of all input bits whose position has that
//   output bit set in its binary representation.
//
// Parameters:
//   WIDTH     - Bit width of the one-hot input (default: 8). Must be >= 2.
//   OUT_WIDTH - Bit width of the binary output (default: $clog2(WIDTH)).
//               Must satisfy 2^OUT_WIDTH >= WIDTH.
//
// Ports:
//   in  [WIDTH-1:0]     - One-hot encoded input
//   out [OUT_WIDTH-1:0] - Binary index of the asserted input bit
//
// Behavior:
//   Combinational OR-reduction. For each output bit k, 'out[k]' is the OR
//   of all in[i] where bit k of i is set. Undefined (X) behaviour if 'in'
//   is not strictly one-hot; this module does not validate the input.
//
// Timing Assumptions:
//   Pure combinational; output settles after input propagation delay.
//
// Usage Notes:
//   - If the input may not be one-hot, use priority_encoder instead and
//     check the 'valid' output.
//   - OUT_WIDTH defaults to $clog2(WIDTH) but can be overridden if a wider
//     output bus is required.
//
// Example Instantiation:
//   onehot_encoder #(
//     .WIDTH    (16),
//     .OUT_WIDTH(4)
//   ) u_oh_enc (
//     .in (onehot_bus),
//     .out(binary_idx)
//   );
// =============================================================================

module onehot_encoder #(
  parameter int WIDTH     = 8,
  parameter int OUT_WIDTH = $clog2(WIDTH)
) (
  input  logic [WIDTH-1:0]     in,
  output logic [OUT_WIDTH-1:0] out
);

  always_comb begin
    out = '0;
    for (int i = 0; i < WIDTH; i++) begin
      // OR each input bit into the output bits that correspond to its index
      for (int k = 0; k < OUT_WIDTH; k++) begin
        if (i[k]) out[k] = out[k] | in[i];
      end
    end
  end

endmodule
