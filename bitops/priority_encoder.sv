// =============================================================================
// Module: priority_encoder
// Description:
//   Encodes the position of the lowest-index (highest-priority) set bit in the
//   input vector to a binary value. If no bit is set, 'valid' is deasserted
//   and 'out' is 0.
//
// Parameters:
//   WIDTH - Bit width of the input vector (default: 8). Must be >= 2.
//
// Ports:
//   in    [WIDTH-1:0]          - Input vector to encode
//   out   [$clog2(WIDTH)-1:0]  - Binary index of the lowest set bit
//   valid                      - Asserted when at least one input bit is set
//
// Behavior:
//   Combinational. Scans input from bit 0 upward and outputs the index of the
//   first (lowest-index) asserted bit. 'valid' is low when in == '0.
//
// Timing Assumptions:
//   Pure combinational; output settles after input propagation delay.
//
// Usage Notes:
//   - WIDTH must be a power of 2 for fully dense output encoding, but any
//     value >= 2 is supported.
//   - When valid == 0, the value of 'out' is 0 and should be ignored.
//
// Example Instantiation:
//   priority_encoder #(
//     .WIDTH(16)
//   ) u_penc (
//     .in   (request_vec),
//     .out  (grant_idx),
//     .valid(any_request)
//   );
// =============================================================================

module priority_encoder #(
  parameter int WIDTH = 8
) (
  input  logic [WIDTH-1:0]         in,
  output logic [$clog2(WIDTH)-1:0] out,
  output logic                     valid
);

  always_comb begin
    out   = '0;
    valid = |in;
    for (int i = WIDTH-1; i >= 0; i--) begin
      if (in[i]) out = ($clog2(WIDTH))'(unsigned'(i));
    end
  end

endmodule
