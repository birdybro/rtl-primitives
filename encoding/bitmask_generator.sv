// =============================================================================
// Module: bitmask_generator
// Description:
//   Generates a bitmask of `len` consecutive 1-bits starting at bit position
//   `offset` within a WIDTH-wide output word.
//   mask = ((1 << len) - 1) << offset, clipped to WIDTH bits.
//
// Parameters:
//   WIDTH - Bit width of the generated mask (default: 8)
//
// Ports:
//   offset [$clog2(WIDTH)-1:0]   - Starting bit position of the mask (LSB)
//   len    [$clog2(WIDTH+1)-1:0] - Number of consecutive ones to set
//   mask   [WIDTH-1:0]           - Generated bitmask output
//
// Behavior / Timing:
//   - Fully combinational.
//   - If len == 0, mask is all-zeros.
//   - If offset + len > WIDTH, bits beyond MSB are silently truncated.
//
// Usage Notes:
//   - Useful for byte-enable generation, field extraction, or dynamic masking.
//   - len uses $clog2(WIDTH+1) bits to allow encoding values 0..WIDTH.
//
// Example Instantiation:
//   bitmask_generator #(.WIDTH(8)) u_bmgen (
//     .offset(field_start),
//     .len   (field_len),
//     .mask  (write_mask)
//   );
// =============================================================================

module bitmask_generator #(
  parameter int unsigned WIDTH = 8
) (
  input  logic [$clog2(WIDTH)-1:0]   offset,
  input  logic [$clog2(WIDTH+1)-1:0] len,
  output logic [WIDTH-1:0]           mask
);

  // Use a wider intermediate to avoid overflow before shifting.
  localparam int unsigned WIDE = WIDTH + WIDTH;

  always_comb begin
    logic [WIDE-1:0] ones;
    logic [WIDE-1:0] shifted;
    ones    = (len == '0) ? '0 : ((WIDE'(1'b1) << len) - 1'b1);
    shifted = ones << offset;
    mask    = shifted[WIDTH-1:0];
  end

endmodule
