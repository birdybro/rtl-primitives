// =============================================================================
// Module: pipeline_join
// Description:
//   Joins NUM_INPUTS pipeline streams into one output using an all-valid gate.
//   out_valid asserts only when every input is simultaneously valid.
//   in_ready deasserts for all inputs when the output cannot accept data.
//
// Parameters:
//   DATA_WIDTH - Width of each input data bus in bits (default: 8)
//   NUM_INPUTS - Number of input streams to join (default: 2)
//
// Ports:
//   clk      - Clock, rising-edge triggered
//   rst_n    - Asynchronous active-low reset
//   in_valid - Per-input valid [NUM_INPUTS-1:0]
//   in_ready - Per-input ready (output) [NUM_INPUTS-1:0]
//   in_data  - Per-input data [NUM_INPUTS-1:0][DATA_WIDTH-1:0]
//   out_valid - Output valid
//   out_ready - Output ready from downstream
//   out_data  - Concatenated output data [NUM_INPUTS-1:0][DATA_WIDTH-1:0]
//
// Timing / Behavior:
//   - Fully combinational: no internal registers, zero added latency.
//   - out_valid = AND of all in_valid bits.
//   - in_ready[k] = out_ready & out_valid (all inputs must be valid before any
//     is consumed, preventing partial acceptance).
//
// Usage Notes:
//   - All inputs must present stable data whenever their valid is asserted.
//   - out_data preserves the input ordering: out_data[0] = in_data[0], etc.
//
// Example Instantiation:
//   pipeline_join #(
//     .DATA_WIDTH(32),
//     .NUM_INPUTS(2)
//   ) u_join (
//     .clk      (clk),
//     .rst_n    (rst_n),
//     .in_valid (join_valid),  // [1:0]
//     .in_ready (join_ready),  // [1:0]
//     .in_data  (join_data),   // [1:0][31:0]
//     .out_valid(merged_valid),
//     .out_ready(merged_ready),
//     .out_data (merged_data)  // [1:0][31:0]
//   );
// =============================================================================

module pipeline_join #(
    parameter int DATA_WIDTH = 8,
    parameter int NUM_INPUTS = 2
) (
    input  logic                               clk,
    input  logic                               rst_n,
    input  logic [NUM_INPUTS-1:0]              in_valid,
    output logic [NUM_INPUTS-1:0]              in_ready,
    input  logic [NUM_INPUTS-1:0][DATA_WIDTH-1:0] in_data,
    output logic                               out_valid,
    input  logic                               out_ready,
    output logic [NUM_INPUTS-1:0][DATA_WIDTH-1:0] out_data
);

    // Suppress unused port warnings for clk/rst_n (module is combinational;
    // ports kept for interface uniformity and future registered extension).
    logic unused_clk, unused_rst_n;
    assign unused_clk   = clk;
    assign unused_rst_n = rst_n;

    always_comb begin
        out_valid = &in_valid;
        // Only accept from all inputs together when downstream is ready
        for (int k = 0; k < NUM_INPUTS; k++) begin
            in_ready[k] = out_valid & out_ready;
            out_data[k] = in_data[k];
        end
    end

endmodule
