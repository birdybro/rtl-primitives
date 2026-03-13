// -----------------------------------------------------------------------------
// Module: backpressure_adapter
// Description:
//   Adapts a source that cannot accept back-pressure (always-valid, no ready
//   signal) to a ready/valid sink. Incoming data words are stored in an
//   internal FIFO. If the FIFO fills up because the downstream sink is stalling
//   for too long, src_overflow is asserted for one cycle and the overflowing
//   word is dropped.
//
//   The FIFO is a standard circular buffer with binary pointers; BUFFER_DEPTH
//   must be a power of 2.
//
// Parameters:
//   DATA_WIDTH   - Width of the data bus in bits (default: 8)
//   BUFFER_DEPTH - Internal FIFO depth (default: 4, must be power of 2)
//
// Ports:
//   clk          - Clock input (rising-edge triggered)
//   rst_n        - Active-low synchronous reset
//   src_valid    - Source data valid (the source asserts this; no ready back)
//   src_data     - Source data bus [DATA_WIDTH-1:0]
//   src_overflow - Output: pulsed high for one cycle when a word is dropped
//   snk_valid    - Downstream valid (output)
//   snk_ready    - Downstream ready
//   snk_data     - Downstream data bus [DATA_WIDTH-1:0] (output)
//
// Behavior:
//   - Every cycle that src_valid is asserted the word is written into the FIFO
//     unless the FIFO is full, in which case src_overflow pulses for one cycle
//     and the word is discarded.
//   - snk_valid is asserted whenever the FIFO is non-empty; data is presented
//     and consumed when snk_valid & snk_ready.
//   - Back-pressure from the sink is absorbed by the FIFO up to BUFFER_DEPTH
//     entries.
//
// Timing assumptions:
//   - src_valid / src_data must be stable before the rising clock edge.
//   - snk_ready is sampled on the rising clock edge.
//   - BUFFER_DEPTH must be a power of 2.
//
// Usage notes:
//   - Size BUFFER_DEPTH to the maximum burst length of the source to avoid
//     overflow.
//   - src_overflow can be connected to an error counter or interrupt flag.
//
// Example instantiation:
//   backpressure_adapter #(
//     .DATA_WIDTH  (8),
//     .BUFFER_DEPTH(16)
//   ) u_bp_adapt (
//     .clk         (clk),
//     .rst_n       (rst_n),
//     .src_valid   (sensor_valid),
//     .src_data    (sensor_data),
//     .src_overflow(overflow_flag),
//     .snk_valid   (fifo_valid),
//     .snk_ready   (fifo_ready),
//     .snk_data    (fifo_data)
//   );
// -----------------------------------------------------------------------------

module backpressure_adapter #(
    parameter int DATA_WIDTH   = 8,
    parameter int BUFFER_DEPTH = 4   // Must be a power of 2
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // Always-valid source (no ready signal)
    input  logic                  src_valid,
    input  logic [DATA_WIDTH-1:0] src_data,
    output logic                  src_overflow,

    // Ready/valid sink
    output logic                  snk_valid,
    input  logic                  snk_ready,
    output logic [DATA_WIDTH-1:0] snk_data
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam int PTR_WIDTH = $clog2(BUFFER_DEPTH) + 1;

    // -------------------------------------------------------------------------
    // FIFO storage and pointers
    // -------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] mem [0:BUFFER_DEPTH-1];

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;

    // -------------------------------------------------------------------------
    // Full / empty flags (standard wrap-bit method)
    // -------------------------------------------------------------------------
    logic full_flag;
    logic empty_flag;

    assign full_flag  = (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1]) &&
                        (wr_ptr[PTR_WIDTH-2:0] == rd_ptr[PTR_WIDTH-2:0]);
    assign empty_flag = (wr_ptr == rd_ptr);

    // -------------------------------------------------------------------------
    // snk_valid: sink side is valid when FIFO is non-empty.
    // snk_data is combinationally driven from the head of the FIFO so the
    // first word is immediately visible without an extra read-latency cycle.
    // -------------------------------------------------------------------------
    assign snk_valid = !empty_flag;
    assign snk_data  = mem[rd_ptr[PTR_WIDTH-2:0]];

    // -------------------------------------------------------------------------
    // Write path: always accept from source; signal overflow when full
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr       <= '0;
            src_overflow <= 1'b0;
        end else begin
            src_overflow <= 1'b0; // Default: no overflow
            if (src_valid) begin
                if (!full_flag) begin
                    mem[wr_ptr[PTR_WIDTH-2:0]] <= src_data;
                    wr_ptr <= wr_ptr + 1'b1;
                end else begin
                    // FIFO full — drop word and flag overflow
                    src_overflow <= 1'b1;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read pointer update
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rd_ptr <= '0;
        end else begin
            if (snk_valid & snk_ready) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

endmodule
