// =============================================================================
// Module: priority_encoder
// Description:
//   Priority encoder that converts a multi-bit request vector to the binary
//   index of the lowest-numbered (LSB-first) active request bit.
//   The `valid` output asserts when any request is present.
//
// Parameters:
//   WIDTH - Number of request input bits (default: 8).
//           Binary output width is $clog2(WIDTH).
//
// Ports:
//   req   [WIDTH-1:0]        - Request input vector (any number of bits may
//                               be asserted simultaneously)
//   enc   [$clog2(WIDTH)-1:0] - Binary index of the highest-priority (lowest
//                               index) asserted bit
//   valid                    - Asserts when at least one req bit is set
//
// Behavior / Timing:
//   - Fully combinational; uses a for-loop scanned from MSB to LSB so that
//     the last iteration (i=0) wins, giving lowest-index priority.
//   - Output is stable immediately after inputs settle.
//
// Usage Notes:
//   - Useful for arbitration, interrupt controllers, and ready/grant logic.
//   - Pair with binary_encoder to reconstruct the original one-hot grant.
//
// Example Instantiation:
//   priority_encoder #(.WIDTH(8)) u_pri_enc (
//     .req  (request_bus),
//     .enc  (grant_index),
//     .valid(any_request)
//   );
// =============================================================================

module priority_encoder #(
  parameter int unsigned WIDTH = 8
) (
  input  logic [WIDTH-1:0]          req,
  output logic [$clog2(WIDTH)-1:0]  enc,
  output logic                      valid
);

  always_comb begin
    enc   = '0;
    valid = |req;
    // Scan from MSB to LSB; lowest index overwrites last, giving LSB priority.
    for (int i = WIDTH-1; i >= 0; i--) begin
      if (req[i]) begin
        enc = $clog2(WIDTH)'(unsigned'(i));
      end
    end
  end

endmodule
