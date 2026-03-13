// =============================================================================
// Module: reset_controller
// Description:
//   Manages reset sequencing for multiple clock domains. On a power-on request
//   (por_req) or any per-domain reset request (rst_req[i]), issues a stretched
//   active-low reset to the affected domains. After the stretch period the
//   domains are deasserted sequentially: domain 0 releases first, then domain 1
//   STRETCH_CYCLES later, domain 2 another STRETCH_CYCLES later, and so on.
//   This ordered release ensures dependent subsystems come out of reset in a
//   controlled, safe sequence.
//
//   por_req asserts reset to ALL domains simultaneously. Individual rst_req[i]
//   bits affect only domain i. Both sources are ORed per domain.
//
// Parameters:
//   NUM_DOMAINS   - Number of independently controlled reset domains (default: 4)
//   STRETCH_CYCLES - Minimum reset assertion duration in clock cycles AND the
//                   inter-domain deassert stagger delay (default: 16)
//
// Ports:
//   clk          - Clock input (all domains share this controller clock)
//   rst_n        - Active-low asynchronous reset for the controller itself
//   por_req      - Active-high power-on reset request; resets all domains
//   rst_req      - Per-domain active-high reset request [NUM_DOMAINS-1:0]
//   rst_n_out    - Per-domain active-low reset outputs [NUM_DOMAINS-1:0]
//
// Timing/Behavior:
//   - por_req or rst_req[i] HIGH: corresponding domain reset(s) assert LOW
//     on the next clock edge and remain LOW for at least STRETCH_CYCLES cycles
//   - After the stretch period, domain 0 deasserts first; domain i deasserts
//     i * STRETCH_CYCLES cycles after domain 0
//   - A new request during stretch restarts that domain's counter
//   - por_req triggers all domains in parallel (same staggered release order)
//   - All counters and outputs reset to deasserted when rst_n is LOW
//
// Usage Notes:
//   - This module operates entirely in the single clk domain; downstream domains
//     should pass rst_n_out through a reset_synchronizer or reset_bridge.
//   - STRETCH_CYCLES * NUM_DOMAINS gives the total sequencing window after por_req.
//   - Counter width is automatically sized for STRETCH_CYCLES * NUM_DOMAINS.
//
// Example Instantiation:
//   reset_controller #(
//     .NUM_DOMAINS  (4),
//     .STRETCH_CYCLES(32)
//   ) u_rst_ctrl (
//     .clk      (clk),
//     .rst_n    (por_rst_n),
//     .por_req  (por_req),
//     .rst_req  (domain_rst_req),
//     .rst_n_out(domain_rst_n)
//   );
// =============================================================================

module reset_controller #(
    parameter int unsigned NUM_DOMAINS    = 4,
    parameter int unsigned STRETCH_CYCLES = 16
) (
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     por_req,
    input  logic [NUM_DOMAINS-1:0]   rst_req,
    output logic [NUM_DOMAINS-1:0]   rst_n_out
);

    // Each domain has a counter that tracks how many more cycles reset must
    // be held. Domain i is in reset while its counter > 0. The counter is
    // loaded with STRETCH_CYCLES + i*STRETCH_CYCLES on assertion so that
    // higher-numbered domains naturally deassert later.
    //
    // Total max count for domain i = STRETCH_CYCLES * (i + 1)
    // Counter width must hold STRETCH_CYCLES * NUM_DOMAINS.
    localparam int unsigned MAX_COUNT = STRETCH_CYCLES * NUM_DOMAINS;
    localparam int unsigned CNT_W     = $clog2(MAX_COUNT + 1);

    logic [CNT_W-1:0] count [NUM_DOMAINS];

    // Compute the load value for domain i: STRETCH_CYCLES * (i + 1)
    // This encodes both the minimum assertion width and the sequential offset.
    function automatic logic [CNT_W-1:0] load_val(input int unsigned domain_idx);
        return CNT_W'(STRETCH_CYCLES * (domain_idx + 1));
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_DOMAINS; i++) begin
                count[i] <= '0;
            end
        end else begin
            for (int i = 0; i < NUM_DOMAINS; i++) begin
                if (por_req || rst_req[i]) begin
                    // (Re)load counter; stagger encodes the deassert order
                    count[i] <= load_val(i);
                end else if (count[i] != '0) begin
                    count[i] <= count[i] - 1'b1;
                end
            end
        end
    end

    // Domain i is in reset (output LOW) while its counter is non-zero
    always_comb begin
        for (int i = 0; i < NUM_DOMAINS; i++) begin
            rst_n_out[i] = (count[i] == '0) ? 1'b1 : 1'b0;
        end
    end

endmodule
