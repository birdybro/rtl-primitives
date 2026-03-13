// -----------------------------------------------------------------------------
// Module: ready_valid_stage
// Description:
//   Single registered pipeline stage implementing the ready/valid handshake
//   protocol. Data presented on in_data with in_valid asserted is captured
//   into a flip-flop on the next rising clock edge, provided the stage is not
//   already holding unaccepted data (back-pressure). The downstream side sees
//   out_valid/out_data and drives out_ready when it can accept.
//
// Parameters:
//   DATA_WIDTH - Width of the data bus in bits (default: 8)
//
// Ports:
//   clk       - Clock input (rising-edge triggered)
//   rst_n     - Active-low synchronous reset
//   in_valid  - Upstream data valid
//   in_ready  - Upstream ready (output); asserted when stage can accept data
//   in_data   - Upstream data bus [DATA_WIDTH-1:0]
//   out_valid - Downstream data valid (output)
//   out_ready - Downstream ready
//   out_data  - Downstream data bus [DATA_WIDTH-1:0] (output)
//
// Behavior:
//   - A transfer occurs on the input  side when in_valid  & in_ready.
//   - A transfer occurs on the output side when out_valid & out_ready.
//   - When out_valid is asserted and out_ready is de-asserted, the stored data
//     is held and in_ready is de-asserted (back-pressure propagated upstream).
//   - No combinational path exists between out_ready and in_ready.
//
// Timing assumptions:
//   - in_valid / in_data must be stable before the rising clock edge.
//   - out_ready is sampled on the rising clock edge.
//
// Usage notes:
//   - Chain multiple stages to create a registered pipeline.
//   - For zero-bubble throughput with back-pressure use skid_buffer instead.
//
// Example instantiation:
//   ready_valid_stage #(
//     .DATA_WIDTH(16)
//   ) u_stage (
//     .clk      (clk),
//     .rst_n    (rst_n),
//     .in_valid (up_valid),
//     .in_ready (up_ready),
//     .in_data  (up_data),
//     .out_valid(dn_valid),
//     .out_ready(dn_ready),
//     .out_data (dn_data)
//   );
// -----------------------------------------------------------------------------

module ready_valid_stage #(
    parameter int DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // Upstream (input) interface
    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic [DATA_WIDTH-1:0] in_data,

    // Downstream (output) interface
    output logic                  out_valid,
    input  logic                  out_ready,
    output logic [DATA_WIDTH-1:0] out_data
);

    // -------------------------------------------------------------------------
    // Internal registers
    // -------------------------------------------------------------------------
    logic                  valid_r;
    logic [DATA_WIDTH-1:0] data_r;

    // -------------------------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------------------------
    assign out_valid = valid_r;
    assign out_data  = data_r;

    // Stage accepts new data when it is empty, or when the current occupant is
    // being consumed this cycle.
    assign in_ready  = !valid_r | out_ready;

    // -------------------------------------------------------------------------
    // Registered stage
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_r <= 1'b0;
            data_r  <= '0;
        end else begin
            if (in_valid & in_ready) begin
                // Accept new data from upstream
                valid_r <= 1'b1;
                data_r  <= in_data;
            end else if (out_ready & valid_r) begin
                // Downstream consumed data; stage now empty
                valid_r <= 1'b0;
            end
        end
    end

endmodule
