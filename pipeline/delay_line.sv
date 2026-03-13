// =============================================================================
// Module: delay_line
// Description:
//   Parameterized shift-register delay line.  Data presented on din appears on
//   dout exactly DEPTH clock cycles later (when en is continuously asserted).
//   Every intermediate tap is also exposed via tap_out so that users can read
//   any stage without additional logic.
//
//   Special case: DEPTH=0 connects din directly to dout (zero-latency wire).
//
// Parameters:
//   DATA_WIDTH - Width of each data word in bits (default: 8)
//   DEPTH      - Number of register stages / cycles of latency (default: 4)
//                Must be >= 0.
//
// Ports:
//   clk     - Clock, rising-edge triggered
//   rst_n   - Asynchronous active-low reset
//   en      - Shift enable; when low all stages hold their current values
//   din     - Data input [DATA_WIDTH-1:0]
//   dout    - Data output after DEPTH cycles [DATA_WIDTH-1:0]
//   tap_out - Per-tap outputs [DEPTH:0][DATA_WIDTH-1:0]
//             tap_out[0]     = din  (combinational, no latency)
//             tap_out[k]     = data delayed by k cycles
//             tap_out[DEPTH] = dout
//
// Timing / Behavior:
//   - Each tap adds exactly one cycle of latency relative to the previous tap.
//   - When en=0 all registers freeze; tap_out[0] still reflects current din.
//   - Reset clears all internal registers to zero.
//
// Usage Notes:
//   - Use DEPTH=0 when a delay-free path is needed but a uniform interface is
//     required (e.g., inside latency_balancer when paths are already matched).
//   - tap_out allows matched-delay fan-out to multiple consumers.
//
// Example Instantiation:
//   delay_line #(
//     .DATA_WIDTH(16),
//     .DEPTH     (3)
//   ) u_dly (
//     .clk    (clk),
//     .rst_n  (rst_n),
//     .en     (pipe_en),
//     .din    (data_in),
//     .dout   (data_out),   // 3-cycle delayed
//     .tap_out(taps)        // taps[0]=din, taps[1]=1-cyc, taps[2]=2-cyc, taps[3]=3-cyc
//   );
// =============================================================================

module delay_line #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 4
) (
    input  logic                          clk,
    input  logic                          rst_n,
    input  logic                          en,
    input  logic [DATA_WIDTH-1:0]         din,
    output logic [DATA_WIDTH-1:0]         dout,
    output logic [DEPTH:0][DATA_WIDTH-1:0] tap_out
);

    // tap_out[0] is always the combinational input
    assign tap_out[0] = din;

    generate
        if (DEPTH == 0) begin : gen_passthrough
            // Zero-latency passthrough
            assign dout = din;
        end else begin : gen_shift_reg
            // Internal shift register; index 0 is the first registered stage
            // (one cycle after din), index DEPTH-1 is the last.
            logic [DEPTH-1:0][DATA_WIDTH-1:0] sreg;

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    for (int i = 0; i < DEPTH; i++) begin
                        sreg[i] <= '0;
                    end
                end else if (en) begin
                    sreg[0] <= din;
                    for (int i = 1; i < DEPTH; i++) begin
                        sreg[i] <= sreg[i-1];
                    end
                end
            end

            // Wire taps: tap_out[k] = sreg[k-1] for k in 1..DEPTH
            for (genvar k = 1; k <= DEPTH; k++) begin : gen_taps
                assign tap_out[k] = sreg[k-1];
            end

            assign dout = sreg[DEPTH-1];
        end
    endgenerate

endmodule
