// =============================================================================
// Module: pipeline_register
// Description:
//   Single pipeline register stage with enable (stall) and synchronous flush.
//   Captures din/valid_in on the rising clock edge when en is asserted.
//   A flush clears the stored data and valid flag synchronously, inserting a
//   bubble into the pipeline regardless of the en signal.
//
// Parameters:
//   DATA_WIDTH - Width of the data path in bits (default: 8)
//
// Ports:
//   clk       - Clock, rising-edge triggered
//   rst_n     - Asynchronous active-low reset
//   en        - Pipeline enable; when low the stage stalls (holds current value)
//   flush     - Synchronous flush; clears stage and deasserts valid_out
//   din       - Data input [DATA_WIDTH-1:0]
//   dout      - Registered data output [DATA_WIDTH-1:0]
//   valid_in  - Upstream valid qualifier
//   valid_out - Downstream valid qualifier (registered alongside data)
//
// Timing / Behavior:
//   - dout and valid_out are registered, producing one cycle of latency.
//   - flush takes priority over en: if both are asserted the stage is cleared.
//   - When en=0 and flush=0 the register retains its current value (stall).
//
// Usage Notes:
//   - Connect flush to a pipeline flush/cancel signal.
//   - Tie flush to 0 if flush functionality is not required.
//   - Chain multiple instances for multi-stage pipelines.
//
// Example Instantiation:
//   pipeline_register #(
//     .DATA_WIDTH(32)
//   ) u_stage1 (
//     .clk      (clk),
//     .rst_n    (rst_n),
//     .en       (pipe_en),
//     .flush    (pipe_flush),
//     .din      (stage0_data),
//     .dout     (stage1_data),
//     .valid_in (stage0_valid),
//     .valid_out(stage1_valid)
//   );
// =============================================================================

module pipeline_register #(
    parameter int DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  en,
    input  logic                  flush,
    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout,
    input  logic                  valid_in,
    output logic                  valid_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout      <= '0;
            valid_out <= 1'b0;
        end else if (flush) begin
            dout      <= '0;
            valid_out <= 1'b0;
        end else if (en) begin
            dout      <= din;
            valid_out <= valid_in;
        end
        // en=0, flush=0: hold current value (stall)
    end

endmodule
