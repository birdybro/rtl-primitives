// =============================================================================
// Module: onehot_decoder
// Description:
//   Decodes a binary input value to a one-hot output vector, asserting
//   exactly one output bit corresponding to the binary value of the input.
//
// Parameters:
//   IN_WIDTH  - Bit width of the binary input  (default: 3).
//   OUT_WIDTH - Bit width of the one-hot output (default: 8).
//               Should equal 2^IN_WIDTH for a complete decode.
//               Extra output bits (index >= 2^IN_WIDTH) are always 0.
//
// Ports:
//   in  [IN_WIDTH-1:0]   - Binary index to decode
//   out [OUT_WIDTH-1:0]  - One-hot output; out[in] == 1, all others 0
//
// Behavior:
//   Combinational. Only output bit index equal to 'in' is asserted.
//   If 'in' encodes a value >= OUT_WIDTH, all outputs are 0.
//
// Timing Assumptions:
//   Pure combinational; output settles after input propagation delay.
//
// Usage Notes:
//   - Typically OUT_WIDTH == 2^IN_WIDTH; mismatches are valid but the upper
//     output bits beyond 2^IN_WIDTH are always 0.
//   - For partial decodes (e.g. driving an 8-wide mux from a 4-bit address),
//     set OUT_WIDTH < 2^IN_WIDTH and treat unrepresented addresses as 0.
//
// Example Instantiation:
//   onehot_decoder #(
//     .IN_WIDTH (3),
//     .OUT_WIDTH(8)
//   ) u_oh_dec (
//     .in (sel_idx),
//     .out(onehot_sel)
//   );
// =============================================================================

module onehot_decoder #(
  parameter int IN_WIDTH  = 3,
  parameter int OUT_WIDTH = 8
) (
  input  logic [IN_WIDTH-1:0]   in,
  output logic [OUT_WIDTH-1:0]  out
);

  always_comb begin
    out = '0;
    if (int'(in) < OUT_WIDTH) begin
      out[in] = 1'b1;
    end
  end

endmodule
