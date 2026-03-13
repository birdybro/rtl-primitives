// =============================================================================
// Module: pipeline_fork
// Description:
//   Forks a single pipeline stream (valid/ready handshake) to NUM_OUTPUTS
//   independent downstream consumers.  A transaction is only accepted from
//   upstream (in_ready asserted) once every output that has not yet been
//   consumed in the current beat has asserted its out_ready.  A per-output
//   completion mask tracks which outputs have already accepted the data so
//   that slow consumers do not force fast ones to wait for the next beat.
//
// Parameters:
//   DATA_WIDTH  - Width of the data bus in bits (default: 8)
//   NUM_OUTPUTS - Number of forked output ports (default: 2)
//
// Ports:
//   clk        - Clock, rising-edge triggered
//   rst_n      - Asynchronous active-low reset
//   in_valid   - Upstream valid qualifier
//   in_ready   - Upstream ready (output) — high when all pending outputs done
//   in_data    - Upstream data [DATA_WIDTH-1:0]
//   out_valid  - Per-output valid [NUM_OUTPUTS-1:0]
//   out_ready  - Per-output ready from downstream [NUM_OUTPUTS-1:0]
//   out_data   - Per-output data [NUM_OUTPUTS-1:0][DATA_WIDTH-1:0]
//                All outputs carry the same replicated data word.
//
// Timing / Behavior:
//   - Data is not registered inside this module; out_data is combinationally
//     driven from in_data (zero additional latency).
//   - A completion mask (done_mask) records which outputs have handshaked.
//     An output's out_valid deasserts once it has been accepted so it is not
//     presented twice.
//   - in_ready pulses high for one cycle when all outputs complete, clearing
//     the mask on the next clock edge.
//   - If all outputs happen to be ready simultaneously the mask never needs
//     to be stored and the throughput is one beat per cycle.
//
// Usage Notes:
//   - All out_data outputs carry identical data; downstream consumers are
//     responsible for discarding data they do not need.
//   - Do not hold out_ready high permanently on a consumer that processes
//     data; pulse it for exactly one cycle per accepted beat.
//
// Example Instantiation:
//   pipeline_fork #(
//     .DATA_WIDTH (32),
//     .NUM_OUTPUTS(3)
//   ) u_fork (
//     .clk      (clk),
//     .rst_n    (rst_n),
//     .in_valid (src_valid),
//     .in_ready (src_ready),
//     .in_data  (src_data),
//     .out_valid(fork_valid),   // [2:0]
//     .out_ready(fork_ready),   // [2:0]
//     .out_data (fork_data)     // [2:0][31:0]
//   );
// =============================================================================

module pipeline_fork #(
    parameter int DATA_WIDTH  = 8,
    parameter int NUM_OUTPUTS = 2
) (
    input  logic                               clk,
    input  logic                               rst_n,
    input  logic                               in_valid,
    output logic                               in_ready,
    input  logic [DATA_WIDTH-1:0]              in_data,
    output logic [NUM_OUTPUTS-1:0]             out_valid,
    input  logic [NUM_OUTPUTS-1:0]             out_ready,
    output logic [NUM_OUTPUTS-1:0][DATA_WIDTH-1:0] out_data
);

    // Tracks which outputs have already accepted the current beat.
    // Bit k is set after output k has completed its handshake.
    logic [NUM_OUTPUTS-1:0] done_mask;

    // out_valid[k] is active when there is a valid beat AND output k has not
    // yet been consumed this beat.
    always_comb begin
        for (int k = 0; k < NUM_OUTPUTS; k++) begin
            out_valid[k] = in_valid & ~done_mask[k];
            out_data[k]  = in_data;
        end
    end

    // A new input is accepted when every output that still needs to consume
    // data is simultaneously ready, or has already been marked done.
    logic all_done;
    always_comb begin
        all_done = 1'b1;
        for (int k = 0; k < NUM_OUTPUTS; k++) begin
            // Output k is satisfied if already done OR is accepting right now
            if (!done_mask[k] && !(out_ready[k] && in_valid)) begin
                all_done = 1'b0;
            end
        end
    end

    assign in_ready = in_valid & all_done;

    // Update completion mask
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_mask <= '0;
        end else begin
            if (in_valid & all_done) begin
                // All outputs consumed — clear mask for next beat
                done_mask <= '0;
            end else if (in_valid) begin
                // Record any outputs that accepted this cycle
                for (int k = 0; k < NUM_OUTPUTS; k++) begin
                    if (out_ready[k] & ~done_mask[k]) begin
                        done_mask[k] <= 1'b1;
                    end
                end
            end
        end
    end

endmodule
