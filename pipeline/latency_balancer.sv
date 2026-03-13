// =============================================================================
// Module: latency_balancer
// Description:
//   Matches the output timing of two parallel pipeline paths that have
//   different inherent latencies.  Path A (the shorter path) is delayed by
//   (LATENCY_B - LATENCY_A) additional register stages so that dout_a and
//   dout_b become time-aligned.  Path B passes through a zero-depth delay
//   line (combinational wire) and is presented unchanged.
//
//   The module instantiates two delay_line primitives:
//     - delay_line for path A: DEPTH = LATENCY_B - LATENCY_A
//     - delay_line for path B: DEPTH = 0  (passthrough)
//
// Parameters:
//   DATA_WIDTH - Width of each data path in bits (default: 8)
//   LATENCY_A  - Inherent pipeline latency of path A in cycles (default: 2)
//   LATENCY_B  - Inherent pipeline latency of path B in cycles (default: 4)
//                Must be >= LATENCY_A.
//
// Ports:
//   clk    - Clock, rising-edge triggered
//   rst_n  - Asynchronous active-low reset
//   en     - Enable / stall control applied to both delay lines simultaneously
//   din_a  - Data input for path A [DATA_WIDTH-1:0]
//   din_b  - Data input for path B [DATA_WIDTH-1:0]
//   dout_a - Latency-compensated output for path A [DATA_WIDTH-1:0]
//   dout_b - Pass-through output for path B [DATA_WIDTH-1:0]
//
// Timing / Behavior:
//   - Both outputs are valid simultaneously after max(LATENCY_A, LATENCY_B)
//     cycles from the first valid input (assuming continuous en assertion).
//   - When LATENCY_A == LATENCY_B, path A is a zero-latency passthrough too.
//   - The en signal stalls both paths simultaneously, preserving alignment.
//
// Usage Notes:
//   - LATENCY_B must be >= LATENCY_A; violating this causes a compile error.
//   - Connect the valid signal for path A through a matching delay_line of
//     the same depth if valid propagation is required.
//   - To balance three or more paths, chain multiple latency_balancer instances
//     or instantiate delay_line directly with appropriate depths.
//
// Example Instantiation:
//   latency_balancer #(
//     .DATA_WIDTH(32),
//     .LATENCY_A (2),
//     .LATENCY_B (5)
//   ) u_bal (
//     .clk   (clk),
//     .rst_n (rst_n),
//     .en    (pipe_en),
//     .din_a (path_a_data),   // arrives 2 cycles after source
//     .din_b (path_b_data),   // arrives 5 cycles after source
//     .dout_a(bal_a_data),    // delayed by 3 extra cycles, aligned with dout_b
//     .dout_b(bal_b_data)     // passes straight through
//   );
// =============================================================================

module latency_balancer #(
    parameter int DATA_WIDTH = 8,
    parameter int LATENCY_A  = 2,
    parameter int LATENCY_B  = 4
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  en,
    input  logic [DATA_WIDTH-1:0] din_a,
    input  logic [DATA_WIDTH-1:0] din_b,
    output logic [DATA_WIDTH-1:0] dout_a,
    output logic [DATA_WIDTH-1:0] dout_b
);

    // Enforce the constraint at elaboration time
    initial begin
        if (LATENCY_B < LATENCY_A) begin
            $fatal(1, "latency_balancer: LATENCY_B (%0d) must be >= LATENCY_A (%0d)",
                   LATENCY_B, LATENCY_A);
        end
    end

    localparam int DELAY_A = LATENCY_B - LATENCY_A;

    // Unused tap buses — width must be DEPTH+1 even for zero-depth case
    logic [DELAY_A:0][DATA_WIDTH-1:0] tap_a;
    logic [0:0][DATA_WIDTH-1:0]       tap_b;

    // Path A: compensate for its shorter inherent latency
    delay_line #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH     (DELAY_A)
    ) u_delay_a (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .din    (din_a),
        .dout   (dout_a),
        .tap_out(tap_a)
    );

    // Path B: zero-latency passthrough (already the longer path)
    delay_line #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH     (0)
    ) u_delay_b (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .din    (din_b),
        .dout   (dout_b),
        .tap_out(tap_b)
    );

endmodule
