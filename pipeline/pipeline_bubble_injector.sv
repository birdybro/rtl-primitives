// =============================================================================
// Module: pipeline_bubble_injector
// Description:
//   Inserts pipeline bubbles (NOPs) into a pipeline stream.  When
//   inject_bubble is asserted the module passes NOP_VALUE downstream and
//   deasserts out_valid, effectively squashing the current beat.  When
//   inject_bubble is deasserted the input is forwarded unchanged.
//
// Parameters:
//   DATA_WIDTH - Width of the data bus in bits (default: 8)
//   NOP_VALUE  - Value driven on out_data when a bubble is injected (default: 0)
//
// Ports:
//   clk           - Clock, rising-edge triggered
//   rst_n         - Asynchronous active-low reset
//   in_valid      - Upstream valid qualifier
//   in_data       - Upstream data [DATA_WIDTH-1:0]
//   inject_bubble - When high, squash the current beat and insert a NOP
//   out_valid     - Downstream valid (deasserted when bubble injected)
//   out_data      - Downstream data; NOP_VALUE when bubble injected
//
// Timing / Behavior:
//   - Fully combinational (no registers); zero added latency.
//   - inject_bubble overrides in_valid: out_valid=0 and out_data=NOP_VALUE.
//   - The upstream source is NOT stalled; it is the caller's responsibility
//     to also stall the upstream stage if the injected beat must be replayed.
//   - clk and rst_n are included for interface uniformity and future use.
//
// Usage Notes:
//   - Typical use: connect inject_bubble to a hazard-detection stall signal.
//   - If the squashed beat must be retried, also assert a stall on the
//     upstream pipeline stage using its enable input.
//
// Example Instantiation:
//   pipeline_bubble_injector #(
//     .DATA_WIDTH(32),
//     .NOP_VALUE (32'hDEAD_NOP)
//   ) u_bubble (
//     .clk          (clk),
//     .rst_n        (rst_n),
//     .in_valid     (stage_valid),
//     .in_data      (stage_data),
//     .inject_bubble(hazard_stall),
//     .out_valid    (next_valid),
//     .out_data     (next_data)
//   );
// =============================================================================

module pipeline_bubble_injector #(
    parameter int                DATA_WIDTH = 8,
    parameter logic [DATA_WIDTH-1:0] NOP_VALUE  = '0
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  in_valid,
    input  logic [DATA_WIDTH-1:0] in_data,
    input  logic                  inject_bubble,
    output logic                  out_valid,
    output logic [DATA_WIDTH-1:0] out_data
);

    // Suppress unused port warnings (combinational module, ports kept for
    // interface uniformity and potential future registered extension).
    logic unused_clk, unused_rst_n;
    assign unused_clk   = clk;
    assign unused_rst_n = rst_n;

    always_comb begin
        if (inject_bubble) begin
            out_valid = 1'b0;
            out_data  = NOP_VALUE;
        end else begin
            out_valid = in_valid;
            out_data  = in_data;
        end
    end

endmodule
