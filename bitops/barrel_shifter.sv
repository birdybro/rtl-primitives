// =============================================================================
// Module: barrel_shifter
// Description:
//   Multi-direction barrel shifter supporting logical left, logical right, and
//   arithmetic right shifts. The shift amount is applied in a single cycle
//   using a cascade of mux stages (one per shift-amount bit).
//
// Parameters:
//   WIDTH - Bit width of the data path (default: 8). Must be >= 2.
//
// Ports:
//   in        [WIDTH-1:0]          - Data to be shifted
//   shift_amt [$clog2(WIDTH)-1:0]  - Number of bit positions to shift (0..WIDTH-1)
//   dir                            - Shift direction: 0 = left, 1 = right
//   arith                          - Shift type:      0 = logical, 1 = arithmetic
//                                    (arithmetic only meaningful for right shift;
//                                     ignored for left shift)
//   out       [WIDTH-1:0]          - Shifted result
//
// Behavior:
//   Combinational. Implements a cascaded-mux barrel shifter:
//     - Left logical  : vacated LSBs filled with 0
//     - Right logical : vacated MSBs filled with 0
//     - Right arith   : vacated MSBs filled with the sign bit (in[WIDTH-1])
//
// Timing Assumptions:
//   Pure combinational. Critical path depth is O(log2 WIDTH) mux stages.
//
// Usage Notes:
//   - 'arith' has no effect when dir == 0 (left shift is always logical).
//   - Shift of 0 passes 'in' unchanged.
//
// Example Instantiation:
//   barrel_shifter #(
//     .WIDTH(32)
//   ) u_shift (
//     .in       (operand_a),
//     .shift_amt(shift_amount[4:0]),
//     .dir      (shift_right),
//     .arith    (arithmetic_mode),
//     .out      (shift_result)
//   );
// =============================================================================

module barrel_shifter #(
  parameter int WIDTH = 8
) (
  input  logic [WIDTH-1:0]         in,
  input  logic [$clog2(WIDTH)-1:0] shift_amt,
  input  logic                     dir,
  input  logic                     arith,
  output logic [WIDTH-1:0]         out
);

  localparam int STAGES = $clog2(WIDTH);

  // Intermediate stage results; stage[0] = input, stage[STAGES] = output
  logic [WIDTH-1:0] stage [0:STAGES];

  // Sign bit for arithmetic right shift fill; captured from original input.
  // For multi-stage right shifts, the MSB is preserved at every stage so
  // using stage[s][WIDTH-1] would be equivalent, but using 'in' directly
  // is clearer and avoids any sign-extension subtlety.
  logic sign_bit;
  assign sign_bit = arith & in[WIDTH-1];

  always_comb begin
    stage[0] = in;
    for (int s = 0; s < STAGES; s++) begin
      if (shift_amt[s]) begin
        if (!dir) begin
          // Left logical shift by 2^s positions
          stage[s+1] = stage[s] << (1 << s);
        end else begin
          // Right shift: logical fills zeros, arithmetic fills sign bit
          // Compute logical right-shift result then OR in fill bits
          begin
            automatic logic [WIDTH-1:0] lsr;
            automatic logic [WIDTH-1:0] fill_mask;
            automatic int               amt;
            amt       = 1 << s;
            lsr       = stage[s] >> amt;
            // Build a mask of 'amt' ones in the MSB positions
            fill_mask = ~(({WIDTH{1'b1}}) >> amt);
            stage[s+1] = lsr | (sign_bit ? fill_mask : {WIDTH{1'b0}});
          end
        end
      end else begin
        stage[s+1] = stage[s];
      end
    end
    out = stage[STAGES];
  end

endmodule
