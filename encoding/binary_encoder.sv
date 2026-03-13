// =============================================================================
// Module: binary_encoder
// Description:
//   Decodes a binary index to a one-hot output vector.
//   onehot_out = 1 << bin_in
//
// Parameters:
//   IN_WIDTH  - Bit width of the binary input index (default: 3)
//   OUT_WIDTH - Bit width of the one-hot output (default: 8)
//              Should satisfy OUT_WIDTH >= 2**IN_WIDTH.
//
// Ports:
//   bin_in    [IN_WIDTH-1:0]  - Binary index input
//   onehot_out[OUT_WIDTH-1:0] - One-hot encoded output
//
// Behavior / Timing:
//   - Fully combinational.
//   - If bin_in selects a bit position >= OUT_WIDTH, onehot_out is '0 (shift
//     produces no asserted bit within the output width).
//
// Usage Notes:
//   - Typically used to decode control signals, select bus lines, or drive
//     write enables.
//   - Pair with onehot_encoder to round-trip binary <-> one-hot.
//
// Example Instantiation:
//   binary_encoder #(.IN_WIDTH(3), .OUT_WIDTH(8)) u_bin_enc (
//     .bin_in    (sel_idx),
//     .onehot_out(we_onehot)
//   );
// =============================================================================

module binary_encoder #(
  parameter int unsigned IN_WIDTH  = 3,
  parameter int unsigned OUT_WIDTH = 8
) (
  input  logic [IN_WIDTH-1:0]  bin_in,
  output logic [OUT_WIDTH-1:0] onehot_out
);

  always_comb begin
    onehot_out = OUT_WIDTH'(1'b1) << bin_in;
  end

endmodule
