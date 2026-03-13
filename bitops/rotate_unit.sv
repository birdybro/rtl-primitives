// =============================================================================
// Module: rotate_unit
// Description:
//   Rotates the input vector left or right by a specified number of bit
//   positions. Bits that are shifted out of one end reappear at the other,
//   so no data is lost.
//
// Parameters:
//   WIDTH - Bit width of the data path (default: 8). Must be >= 2.
//
// Ports:
//   in      [WIDTH-1:0]          - Data to be rotated
//   rot_amt [$clog2(WIDTH)-1:0]  - Number of positions to rotate (0..WIDTH-1)
//   dir                          - Rotation direction: 0 = left, 1 = right
//   out     [WIDTH-1:0]          - Rotated result
//
// Behavior:
//   Combinational. Right rotation by N is converted to a left rotation by
//   (WIDTH - N), then applied with a cascaded-mux barrel approach for
//   O(log2 WIDTH) critical path depth.
//     out = (in << left_amt) | (in >> (WIDTH - left_amt))
//
// Timing Assumptions:
//   Pure combinational; output settles after input propagation delay.
//
// Usage Notes:
//   - rot_amt == 0 passes 'in' unchanged.
//   - Rotating left by N is equivalent to rotating right by (WIDTH - N).
//
// Example Instantiation:
//   rotate_unit #(
//     .WIDTH(32)
//   ) u_rot (
//     .in     (data_in),
//     .rot_amt(rotation[4:0]),
//     .dir    (rotate_right),
//     .out    (rotated_data)
//   );
// =============================================================================

module rotate_unit #(
  parameter int WIDTH = 8
) (
  input  logic [WIDTH-1:0]         in,
  input  logic [$clog2(WIDTH)-1:0] rot_amt,
  input  logic                     dir,
  output logic [WIDTH-1:0]         out
);

  localparam int             STAGES    = $clog2(WIDTH);
  // WIDTH_VAL has $clog2(WIDTH)+1 bits so it matches {1'b0, rot_amt} width,
  // eliminating type-width mismatches in the subtraction below.
  localparam [$clog2(WIDTH):0] WIDTH_VAL = WIDTH;

  // Convert right rotation to equivalent left rotation amount.
  // right by N  ==  left by (WIDTH - N)  for N in [1, WIDTH-1]
  logic [$clog2(WIDTH)-1:0] left_amt;

  always_comb begin
    if (dir && (rot_amt != '0)) begin
      left_amt = ($clog2(WIDTH))'(WIDTH_VAL - {1'b0, rot_amt});
    end else begin
      left_amt = rot_amt;
    end
  end

  // Cascaded-mux barrel rotation (left only, using converted amount).
  // At stage s, rotate left by 2^s if left_amt[s] is set.
  // Uses shift operators to avoid non-constant part-select indices.
  logic [WIDTH-1:0] stage [0:STAGES];

  always_comb begin
    stage[0] = in;
    for (int s = 0; s < STAGES; s++) begin
      if (left_amt[s]) begin
        automatic int amt = 1 << s;
        // Rotate left by amt: bits shifted out of MSB reappear at LSB
        stage[s+1] = (stage[s] << amt) | (stage[s] >> (WIDTH - amt));
      end else begin
        stage[s+1] = stage[s];
      end
    end
    out = stage[STAGES];
  end

endmodule
