// =============================================================================
// Module: binary_decoder
// Description:
//   Decodes a binary index to a thermometer / one-hot output bus, gated by an
//   enable signal.  When en is asserted, out = 1 << in; when deasserted, out
//   is all-zeros.
//
// Parameters:
//   IN_WIDTH  - Bit width of the binary input index (default: 3)
//   OUT_WIDTH - Bit width of the decoded output bus (default: 8)
//
// Ports:
//   en  - Active-high enable; when low, output is forced to '0
//   in  [IN_WIDTH-1:0]  - Binary index to decode
//   out [OUT_WIDTH-1:0] - Decoded one-hot output (or '0 when disabled)
//
// Behavior / Timing:
//   - Fully combinational.
//   - out = en ? (OUT_WIDTH'(1) << in) : '0
//
// Usage Notes:
//   - Suitable for address decode, chip-select generation, or write-enable
//     fanout.
//   - If in >= OUT_WIDTH, the shift result is zero (no bit within range).
//
// Example Instantiation:
//   binary_decoder #(.IN_WIDTH(3), .OUT_WIDTH(8)) u_bin_dec (
//     .en (decode_en),
//     .in (addr_idx),
//     .out(cs_n_bar)
//   );
// =============================================================================

module binary_decoder #(
  parameter int unsigned IN_WIDTH  = 3,
  parameter int unsigned OUT_WIDTH = 8
) (
  input  logic                  en,
  input  logic [IN_WIDTH-1:0]   in,
  output logic [OUT_WIDTH-1:0]  out
);

  always_comb begin
    out = en ? (OUT_WIDTH'(1'b1) << in) : '0;
  end

endmodule
