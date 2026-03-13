// =============================================================================
// Module: parking_arbiter
// Description:
//   Parking (sticky) arbiter for bus-style arbitration. Once a requestor is
//   granted the bus, the arbiter "parks" the grant there: the same grantee
//   retains ownership for as long as its request remains asserted. Only when
//   the current owner releases its request does the arbiter re-arbitrate among
//   the remaining pending requestors using fixed priority.
//
//   This behaviour is useful for burst-oriented bus masters (e.g., AHB, APB
//   arbitration) where splitting a transaction mid-burst is undesirable.
//
//   Algorithm per clock cycle:
//     1. If current gnt & req != 0 (owner still active): hold gnt unchanged.
//     2. Else: gnt_next = fixed_priority(req).
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
//   - On reset: gnt <= 0.
//   - While (gnt & req) != 0: gnt is held (owner keeps bus).
//   - When owner drops request (gnt & req == 0): re-arbitrate via fixed priority.
//   - If req == 0 after re-arbitration: gnt <= 0.
//
// Timing / Assumptions:
//   - gnt is registered; new grant takes effect the cycle after the previous
//     owner releases its request.
//   - req is sampled on the rising edge of clk.
//
// Usage Notes:
//   - This arbiter can cause starvation if a high-priority requestor holds
//     req indefinitely. Pair with a watchdog timeout if starvation is a concern.
//   - The fixed-priority fallback can be replaced with round_robin logic by
//     substituting the gnt_next computation with a rotating priority scheme.
//
// Example Instantiation:
//   parking_arbiter #(
//     .NUM_REQS(4)
//   ) u_park (
//     .clk   (clk),
//     .rst_n (rst_n),
//     .req   (req_bus),
//     .gnt   (gnt_bus)
//   );
// =============================================================================

module parking_arbiter #(
    parameter int NUM_REQS = 4
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic [NUM_REQS-1:0]  req,
    output logic [NUM_REQS-1:0]  gnt
);

    logic [NUM_REQS-1:0] gnt_next;
    logic                owner_active; // Current grantee still asserting request

    // ---------------------------------------------------------------------------
    // Combinational next-grant logic
    // ---------------------------------------------------------------------------
    always_comb begin
        owner_active = |(gnt & req);

        if (owner_active) begin
            // Park: current owner keeps the grant
            gnt_next = gnt;
        end else begin
            // Re-arbitrate: fixed-priority (isolate lowest set bit)
            gnt_next = req & (~req + {{(NUM_REQS-1){1'b0}}, 1'b1});
        end
    end

    // ---------------------------------------------------------------------------
    // Registered output
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            gnt <= '0;
        end else begin
            gnt <= gnt_next;
        end
    end

endmodule
