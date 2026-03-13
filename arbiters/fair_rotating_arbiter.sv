// =============================================================================
// Module: fair_rotating_arbiter
// Description:
//   Fair rotating arbiter. Maintains a one-hot rotation pointer (ptr) that
//   identifies the highest-priority requestor for the current cycle. After
//   every grant, ptr advances to the position just past the granted index,
//   ensuring that every active requestor receives service in strict rotating
//   order regardless of when it asserts its request.
//
//   Differs from round_robin_arbiter in that:
//   - ptr advances every cycle a grant is issued (not only when the masked
//     bank is exhausted).
//   - No credit counting; each requestor gets exactly one slot per rotation.
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
//   - On reset: gnt <= 0, ptr <= 1 (points to index 0).
//   - Each cycle a grant is issued, ptr rotates left by the number of
//     positions equal to the index of the granted requestor plus one.
//   - When no requests are pending, gnt <= 0 and ptr holds its value.
//
// Timing / Assumptions:
//   - gnt is registered; valid one cycle after req is sampled.
//   - req is sampled on the rising edge of clk.
//
// Usage Notes:
//   - Suitable for latency-sensitive arbitration where every pending requestor
//     must be served in order (e.g., round-robin network switches).
//   - For weighted service, use weighted_round_robin_arbiter instead.
//
// Example Instantiation:
//   fair_rotating_arbiter #(
//     .NUM_REQS(4)
//   ) u_fra (
//     .clk   (clk),
//     .rst_n (rst_n),
//     .req   (req_bus),
//     .gnt   (gnt_bus)
//   );
// =============================================================================

module fair_rotating_arbiter #(
    parameter int NUM_REQS = 4
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic [NUM_REQS-1:0]  req,
    output logic [NUM_REQS-1:0]  gnt
);

    logic [NUM_REQS-1:0] ptr;         // One-hot priority pointer
    logic [NUM_REQS-1:0] mask;        // Open bits at and above ptr
    logic [NUM_REQS-1:0] masked_req;
    logic [NUM_REQS-1:0] masked_gnt;
    logic [NUM_REQS-1:0] plain_gnt;
    logic [NUM_REQS-1:0] gnt_next;
    logic [NUM_REQS-1:0] ptr_next;

    // ---------------------------------------------------------------------------
    // Mask: bits at and above ptr position are eligible
    // mask[i] = 1 when index i >= position of the set bit in ptr
    // ---------------------------------------------------------------------------
    always_comb begin
        mask = '0;
        for (int i = 0; i < NUM_REQS; i++) begin
            if (i == 0)
                mask[0] = ptr[0];
            else
                mask[i] = mask[i-1] | ptr[i-1];
        end
        mask = mask | ptr; // Include ptr's own position
    end

    // ---------------------------------------------------------------------------
    // Grant selection: masked fixed-priority, fallback to plain fixed-priority
    // ---------------------------------------------------------------------------
    always_comb begin
        masked_req = req & mask;
        masked_gnt = masked_req & (~masked_req + {{(NUM_REQS-1){1'b0}}, 1'b1});
        plain_gnt  = req        & (~req        + {{(NUM_REQS-1){1'b0}}, 1'b1});
        gnt_next   = (masked_req != '0) ? masked_gnt : plain_gnt;
    end

    // ---------------------------------------------------------------------------
    // Next pointer: rotate to just past the granted index (one-hot left shift,
    // wrapping). If no grant, keep ptr unchanged.
    // ---------------------------------------------------------------------------
    always_comb begin
        // Barrel-rotate ptr_next = gnt_next rotated left by 1
        ptr_next = {gnt_next[NUM_REQS-2:0], gnt_next[NUM_REQS-1]};
    end

    // ---------------------------------------------------------------------------
    // Registered outputs
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            gnt <= '0;
            ptr <= {{(NUM_REQS-1){1'b0}}, 1'b1}; // Points to index 0
        end else begin
            gnt <= gnt_next;
            if (gnt_next != '0) begin
                ptr <= ptr_next;
            end
        end
    end

endmodule
