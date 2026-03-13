// =============================================================================
// Module: masked_priority_arbiter
// Description:
//   Combinational fixed-priority arbiter with an external mask input. The mask
//   allows software or hardware to temporarily disable specific requestors
//   (e.g., for bandwidth shaping or error isolation).
//
//   Priority resolution:
//     1. Compute masked_req = req & mask.
//     2. If masked_req != 0: gnt = fixed_priority(masked_req).
//     3. Else (all enabled requests are masked):
//            gnt = fixed_priority(req)  -- fallback, mask is ignored.
//
//   The fallback ensures the arbiter never produces gnt==0 while req!=0,
//   which prevents deadlock in systems that require at least one grant.
//
// Parameters:
//   NUM_REQS - Number of requestors (default 4)
//
// Ports:
//   req  [NUM_REQS-1:0] - Request vector (input)
//   mask [NUM_REQS-1:0] - Enable mask; 1=requestor eligible, 0=disabled (input)
//   gnt  [NUM_REQS-1:0] - One-hot grant vector (output)
//
// Behavior:
//   - Purely combinational; no clock or reset.
//   - If req == 0, gnt == 0 regardless of mask.
//   - If mask == 0 (all disabled), falls back to unmasked fixed priority.
//
// Timing / Assumptions:
//   - Output settles within one combinational delay of req or mask changing.
//   - For glitch-free gnt, register the output externally.
//
// Usage Notes:
//   - Set mask bits to '1 to enable all requestors (equivalent to
//     fixed_priority_arbiter).
//   - Can be used in pipeline stages where certain sources should be
//     temporarily excluded (e.g., quality-of-service throttling).
//
// Example Instantiation:
//   masked_priority_arbiter #(
//     .NUM_REQS(4)
//   ) u_mpa (
//     .req  (req_bus),
//     .mask (mask_reg),
//     .gnt  (gnt_bus)
//   );
// =============================================================================

module masked_priority_arbiter #(
    parameter int NUM_REQS = 4
) (
    input  logic [NUM_REQS-1:0] req,
    input  logic [NUM_REQS-1:0] mask,
    output logic [NUM_REQS-1:0] gnt
);

    logic [NUM_REQS-1:0] masked_req;
    logic [NUM_REQS-1:0] masked_gnt;
    logic [NUM_REQS-1:0] plain_gnt;

    always_comb begin
        masked_req = req & mask;

        // Fixed-priority on masked requests (isolate lowest set bit)
        masked_gnt = masked_req & (~masked_req + {{(NUM_REQS-1){1'b0}}, 1'b1});

        // Fixed-priority on all requests (fallback)
        plain_gnt  = req & (~req + {{(NUM_REQS-1){1'b0}}, 1'b1});

        // Use masked result when any masked request exists; otherwise fall back
        gnt = (masked_req != '0) ? masked_gnt : plain_gnt;
    end

endmodule
