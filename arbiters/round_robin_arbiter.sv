// =============================================================================
// Module: round_robin_arbiter
// Description:
//   Registered round-robin arbiter. Priority rotates after every grant so that
//   all requestors receive equal long-term service. Implements the classic
//   masked-priority approach:
//     1. Apply a mask derived from last_gnt to suppress recently served ports.
//     2. Run fixed-priority on (req & mask).
//     3. If the masked result is empty, fall back to plain fixed-priority on req.
//   The mask is a "higher-index suppress" mask: all bits at or below the
//   position of last_gnt are cleared, so the next candidate starts above it.
//
// Parameters:
//   NUM_REQS - Number of requestors (default 4)
//
// Ports:
//   clk              - Clock (input)
//   rst_n            - Active-low synchronous reset (input)
//   req [NUM_REQS-1:0] - Request vector (input)
//   gnt [NUM_REQS-1:0] - One-hot grant vector (output, registered)
//
// Behavior:
//   - gnt is updated every clock cycle.
//   - On reset: gnt <= 0, last_gnt <= 0 (no bias; first grant goes to req[0]).
//   - When req == 0: gnt <= 0.
//   - Fairness: no single requestor can be starved while others are active.
//
// Timing / Assumptions:
//   - gnt is a registered output; valid one cycle after req is asserted.
//   - req is sampled on the rising edge of clk.
//
// Usage Notes:
//   - Connect gnt directly to downstream logic; it is already registered.
//   - For combinational gnt, remove the output register and use gnt_next.
//
// Example Instantiation:
//   round_robin_arbiter #(
//     .NUM_REQS(4)
//   ) u_rra (
//     .clk   (clk),
//     .rst_n (rst_n),
//     .req   (req_bus),
//     .gnt   (gnt_bus)
//   );
// =============================================================================

module round_robin_arbiter #(
    parameter int NUM_REQS = 4
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic [NUM_REQS-1:0]  req,
    output logic [NUM_REQS-1:0]  gnt
);

    logic [NUM_REQS-1:0] last_gnt;
    logic [NUM_REQS-1:0] mask;
    logic [NUM_REQS-1:0] masked_req;
    logic [NUM_REQS-1:0] masked_gnt;
    logic [NUM_REQS-1:0] plain_gnt;
    logic [NUM_REQS-1:0] gnt_next;

    // ---------------------------------------------------------------------------
    // Build mask: suppress all indices <= position of last_gnt.
    // mask[i] = 1 when i is strictly above the last granted index.
    // If last_gnt == 0 (reset / no previous grant), all bits are unmasked.
    // ---------------------------------------------------------------------------
    always_comb begin
        mask = '0;
        for (int i = 0; i < NUM_REQS; i++) begin
            // Once we pass the last_gnt bit, open up higher indices.
            if (i > 0) begin
                mask[i] = mask[i-1] | last_gnt[i-1];
            end else begin
                mask[0] = 1'b0; // index 0 is never above anything
            end
        end
    end

    // ---------------------------------------------------------------------------
    // Fixed-priority helper (isolate lowest set bit)
    // ---------------------------------------------------------------------------
    always_comb begin
        masked_req = req & mask;
        masked_gnt = masked_req & (~masked_req + {{(NUM_REQS-1){1'b0}}, 1'b1});
        plain_gnt  = req        & (~req        + {{(NUM_REQS-1){1'b0}}, 1'b1});
        // Prefer masked grant; fall back to plain when no masked requests
        gnt_next   = (masked_req != '0) ? masked_gnt : plain_gnt;
    end

    // ---------------------------------------------------------------------------
    // Registered outputs
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            gnt      <= '0;
            last_gnt <= '0;
        end else begin
            gnt      <= gnt_next;
            if (gnt_next != '0) begin
                last_gnt <= gnt_next;
            end
        end
    end

endmodule
