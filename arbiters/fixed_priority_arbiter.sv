// =============================================================================
// Module: fixed_priority_arbiter
// Description:
//   Purely combinational fixed-priority arbiter. Among all asserted request
//   lines, the lowest-index requestor wins. Uses the "isolate lowest set bit"
//   identity:  gnt = req & (~req + 1)  which is equivalent to req & (-req)
//   in two's-complement arithmetic.
//
// Parameters:
//   NUM_REQS - Number of requestors (default 4)
//
// Ports:
//   req [NUM_REQS-1:0] - One-hot or encoded request vector (input)
//   gnt [NUM_REQS-1:0] - One-hot grant vector; at most one bit asserted (output)
//
// Behavior:
//   - Purely combinational; no clock or reset required.
//   - gnt is one-hot: only the lowest-indexed asserted req bit is granted.
//   - If req == 0, gnt == 0.
//
// Timing / Assumptions:
//   - Output changes within one combinational delay of req.
//   - Downstream registers should sample gnt on the appropriate clock edge.
//
// Usage Notes:
//   - Instantiate directly in combinational paths or feed outputs into
//     registered stages as needed.
//   - NUM_REQS may be any positive integer.
//
// Example Instantiation:
//   fixed_priority_arbiter #(
//     .NUM_REQS(8)
//   ) u_fpa (
//     .req (req_bus),
//     .gnt (gnt_bus)
//   );
// =============================================================================

module fixed_priority_arbiter #(
    parameter int NUM_REQS = 4
) (
    input  logic [NUM_REQS-1:0] req,  // Request vector
    output logic [NUM_REQS-1:0] gnt   // One-hot grant vector
);

    // Isolate lowest set bit: gnt = req & (~req + 1)
    // The cast to unsigned ensures the arithmetic is well-defined in synthesis.
    always_comb begin
        gnt = req & (~req + {{(NUM_REQS-1){1'b0}}, 1'b1});
    end

endmodule
