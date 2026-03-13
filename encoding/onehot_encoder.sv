// =============================================================================
// Module: onehot_encoder
// Description:
//   Encodes a one-hot input vector to a binary index. The output `bin_out`
//   reflects the position of the asserted bit in `onehot_in`. The `valid`
//   output asserts when exactly one input bit is set.
//
// Parameters:
//   WIDTH - Number of one-hot input bits (default: 8).
//           Binary output width is $clog2(WIDTH).
//
// Ports:
//   onehot_in [WIDTH-1:0]        - One-hot encoded input
//   bin_out   [$clog2(WIDTH)-1:0] - Binary index of the asserted bit
//   valid                        - Asserts when any bit in onehot_in is set
//
// Behavior / Timing:
//   - Fully combinational.
//   - If more than one bit is set, bin_out is the OR-reduction of all active
//     indices (undefined / don't-care for a true encoder), and valid is still
//     asserted because at least one bit is set.
//   - valid is low only when onehot_in == '0.
//
// Usage Notes:
//   - For safe operation ensure that onehot_in is genuinely one-hot.
//   - Pair with binary_encoder to recover the one-hot signal.
//
// Example Instantiation:
//   onehot_encoder #(.WIDTH(8)) u_oh_enc (
//     .onehot_in(grant_oh),
//     .bin_out  (grant_idx),
//     .valid    (grant_valid)
//   );
// =============================================================================

module onehot_encoder #(
  parameter int unsigned WIDTH = 8
) (
  input  logic [WIDTH-1:0]          onehot_in,
  output logic [$clog2(WIDTH)-1:0]  bin_out,
  output logic                      valid
);

  always_comb begin
    bin_out = '0;
    for (int i = 0; i < WIDTH; i++) begin
      if (onehot_in[i]) begin
        bin_out = bin_out | $clog2(WIDTH)'(unsigned'(i));
      end
    end
    valid = |onehot_in;
  end

endmodule
