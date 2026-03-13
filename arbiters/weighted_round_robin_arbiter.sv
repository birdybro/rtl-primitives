// =============================================================================
// Module: weighted_round_robin_arbiter
// Description:
//   Weighted round-robin arbiter. Each requestor i has a programmable weight
//   weight[i]. The arbiter grants requestor i up to weight[i] consecutive
//   cycles before advancing to the next requestor in round-robin order.
//   A credit counter tracks how many more grants the current winner may receive.
//
//   Algorithm per clock cycle:
//     1. Determine current priority pointer (ptr).
//     2. Among active requests (req), pick the one at or above ptr using
//        masked fixed-priority; fall back to plain fixed-priority.
//     3. If the selected grantee still has credit (credit_cnt > 1), decrement
//        counter and stay on the same grantee next cycle.
//     4. When credit is exhausted (credit_cnt == 1), advance ptr past the
//        current grantee and reload credit for the next winner.
//
// Parameters:
//   NUM_REQS     - Number of requestors (default 4)
//   WEIGHT_WIDTH - Bit width of each weight field (default 4, max weight 15)
//
// Ports:
//   clk                                    - Clock (input)
//   rst_n                                  - Active-low synchronous reset (input)
//   req    [NUM_REQS-1:0]                  - Request vector (input)
//   weight [NUM_REQS-1:0][WEIGHT_WIDTH-1:0]- Per-requestor weight (input)
//                                            weight[i]==0 treated as weight 1
//   gnt    [NUM_REQS-1:0]                  - One-hot grant vector (output, registered)
//
// Behavior:
//   - A weight of 0 is treated as 1 (minimum one grant per rotation).
//   - Weights are sampled when a new arbitration round begins for each port.
//   - If req == 0, gnt == 0 and state is preserved.
//
// Timing / Assumptions:
//   - gnt is registered; valid one cycle after req.
//   - weight inputs should be stable; changing weight mid-burst may cause the
//     current burst to use the old weight value.
//
// Usage Notes:
//   - Set WEIGHT_WIDTH to accommodate your maximum desired weight.
//   - All requestors with weight[i] = 1 behave identically to plain round-robin.
//
// Example Instantiation:
//   weighted_round_robin_arbiter #(
//     .NUM_REQS    (4),
//     .WEIGHT_WIDTH(4)
//   ) u_wrra (
//     .clk    (clk),
//     .rst_n  (rst_n),
//     .req    (req_bus),
//     .weight (weight_bus),
//     .gnt    (gnt_bus)
//   );
// =============================================================================

module weighted_round_robin_arbiter #(
    parameter int NUM_REQS     = 4,
    parameter int WEIGHT_WIDTH = 4
) (
    input  logic                                    clk,
    input  logic                                    rst_n,
    input  logic [NUM_REQS-1:0]                     req,
    input  logic [NUM_REQS-1:0][WEIGHT_WIDTH-1:0]   weight,
    output logic [NUM_REQS-1:0]                     gnt
);

    logic [NUM_REQS-1:0]     mask;
    logic [NUM_REQS-1:0]     masked_req;
    logic [NUM_REQS-1:0]     masked_gnt;
    logic [NUM_REQS-1:0]     plain_gnt;
    logic [NUM_REQS-1:0]     gnt_next;
    logic [NUM_REQS-1:0]     ptr;          // One-hot rotation pointer
    logic [WEIGHT_WIDTH-1:0] credit_cnt;   // Remaining grants for current winner
    logic [WEIGHT_WIDTH-1:0] eff_weight;   // Effective weight of next winner

    // Index of the bit set in gnt_next (used to read weight)
    logic [$clog2(NUM_REQS)-1:0] gnt_idx;

    // ---------------------------------------------------------------------------
    // Mask: open bits at or above ptr (same as round_robin_arbiter but using ptr)
    // ---------------------------------------------------------------------------
    always_comb begin
        mask = '0;
        for (int i = 0; i < NUM_REQS; i++) begin
            if (i == 0)
                mask[0] = ptr[0];          // req[0] eligible when ptr==req[0]
            else
                mask[i] = mask[i-1] | ptr[i-1];
        end
        // Also include ptr position itself
        mask = mask | ptr;
    end

    // ---------------------------------------------------------------------------
    // Fixed-priority selection (isolate lowest set bit)
    // ---------------------------------------------------------------------------
    always_comb begin
        masked_req = req & mask;
        masked_gnt = masked_req & (~masked_req + {{(NUM_REQS-1){1'b0}}, 1'b1});
        plain_gnt  = req        & (~req        + {{(NUM_REQS-1){1'b0}}, 1'b1});
        gnt_next   = (masked_req != '0) ? masked_gnt : plain_gnt;
    end

    // Encode gnt_next to an index for weight lookup
    always_comb begin
        gnt_idx = '0;
        for (int i = 0; i < NUM_REQS; i++) begin
            if (gnt_next[i]) gnt_idx = $clog2(NUM_REQS)'(i);
        end
    end

    // Effective weight: treat 0 as 1
    always_comb begin
        eff_weight = (weight[gnt_idx] == '0) ? {{(WEIGHT_WIDTH-1){1'b0}}, 1'b1}
                                              : weight[gnt_idx];
    end

    // ---------------------------------------------------------------------------
    // Registered state: ptr, credit_cnt, gnt
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            gnt        <= '0;
            ptr        <= {{(NUM_REQS-1){1'b0}}, 1'b1}; // Start at index 0
            credit_cnt <= '0;
        end else begin
            if (req == '0) begin
                // No requests; hold state, clear grant
                gnt <= '0;
            end else begin
                gnt <= gnt_next;

                if (gnt_next == gnt && gnt != '0) begin
                    // Same winner continues; burn a credit
                    if (credit_cnt > {{(WEIGHT_WIDTH-1){1'b0}}, 1'b1}) begin
                        credit_cnt <= credit_cnt - 1'b1;
                    end else begin
                        // Credit exhausted; rotate ptr past the departing winner
                        ptr        <= {gnt[NUM_REQS-2:0], gnt[NUM_REQS-1]};
                        credit_cnt <= '0; // Will be reloaded when next winner is selected
                    end
                end else if (gnt_next != '0) begin
                    // New winner selected; load its weight
                    credit_cnt <= eff_weight - 1'b1;
                end
            end
        end
    end

endmodule
