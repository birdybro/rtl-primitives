// =============================================================================
// Module: thermometer_encoder
// Description:
//   Converts a binary count N to a thermometer (unary) code where the
//   N least-significant output bits are set and the remainder are zero.
//   For example, N=3 on an 8-bit output yields 8'b00000111.
//
// Parameters:
//   OUT_WIDTH - Bit width of the thermometer output (default: 8).
//               The binary input width is derived as $clog2(OUT_WIDTH+1)
//               to allow representing every count from 0 to OUT_WIDTH.
//
// Ports:
//   in  [$clog2(OUT_WIDTH+1)-1:0] - Binary count (0..OUT_WIDTH)
//   out [OUT_WIDTH-1:0]           - Thermometer-coded output
//
// Behavior:
//   Combinational. out[i] = 1 when i < in, else 0.
//   If 'in' > OUT_WIDTH (should not occur in normal use), all bits are set.
//
// Timing Assumptions:
//   Pure combinational; output settles after input propagation delay.
//
// Usage Notes:
//   - Thermometer codes are often used in DAC segmented current-steering
//     architectures and flash ADC comparator banks.
//   - The IN_WIDTH is set to $clog2(OUT_WIDTH+1) to cover all valid counts
//     including OUT_WIDTH (all ones).
//
// Example Instantiation:
//   thermometer_encoder #(
//     .OUT_WIDTH(8)
//   ) u_therm (
//     .in (binary_count),
//     .out(therm_out)
//   );
// =============================================================================

module thermometer_encoder #(
  parameter int OUT_WIDTH = 8
) (
  input  logic [$clog2(OUT_WIDTH+1)-1:0] in,
  output logic [OUT_WIDTH-1:0]           out
);

  always_comb begin
    for (int i = 0; i < OUT_WIDTH; i++) begin
      out[i] = (i < int'(in)) ? 1'b1 : 1'b0;
    end
  end

endmodule
