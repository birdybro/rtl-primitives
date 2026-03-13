// -----------------------------------------------------------------------------
// Module: elastic_buffer
// Description:
//   Synchronous FIFO-based elastic buffer with ready/valid handshake on both
//   input and output ports. Provides configurable storage depth to absorb
//   bursts and decouple producer/consumer timing.
//
//   Implemented as a circular buffer with binary read/write pointers of
//   width log2(DEPTH)+1; the MSB serves as the wrap-around bit for
//   full/empty detection without extra flags.
//
// Parameters:
//   DATA_WIDTH - Width of the data bus in bits (default: 8)
//   DEPTH      - Number of entries; MUST be a power of 2 (default: 4)
//
// Ports:
//   clk       - Clock input (rising-edge triggered)
//   rst_n     - Active-low synchronous reset
//   in_valid  - Upstream data valid
//   in_ready  - Upstream ready (output); asserted when buffer is not full
//   in_data   - Upstream data bus [DATA_WIDTH-1:0]
//   out_valid - Downstream data valid (output); asserted when buffer is not empty
//   out_ready - Downstream ready
//   out_data  - Downstream data bus [DATA_WIDTH-1:0] (output); registered read
//
// Behavior:
//   - Full/empty determined by pointer comparison (standard 2^(n+1) method).
//   - Simultaneous read and write when neither full nor empty is handled
//     correctly (occupancy stays constant).
//   - out_data is combinationally driven from the memory array at the current
//     read pointer, so it is valid (and stable) whenever out_valid is asserted,
//     with no extra latency cycle before the first word is visible.
//
// Timing assumptions:
//   - in_valid/in_data must be stable before the rising clock edge.
//   - out_ready is sampled on the rising clock edge.
//   - DEPTH must be a power of 2; behaviour is undefined otherwise.
//
// Usage notes:
//   - Increase DEPTH to handle longer bursts without dropping data.
//   - For a single-entry buffer use mailbox_fifo instead.
//
// Example instantiation:
//   elastic_buffer #(
//     .DATA_WIDTH(8),
//     .DEPTH     (8)
//   ) u_buf (
//     .clk      (clk),
//     .rst_n    (rst_n),
//     .in_valid (src_valid),
//     .in_ready (src_ready),
//     .in_data  (src_data),
//     .out_valid(dst_valid),
//     .out_ready(dst_ready),
//     .out_data (dst_data)
//   );
// -----------------------------------------------------------------------------

module elastic_buffer #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 4   // Must be a power of 2
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
    // Local parameters
    // -------------------------------------------------------------------------
    localparam int PTR_WIDTH = $clog2(DEPTH) + 1; // Extra bit for wrap detection

    // -------------------------------------------------------------------------
    // Storage and pointers
    // -------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0] wr_ptr;   // Write pointer
    logic [PTR_WIDTH-1:0] rd_ptr;   // Read pointer

    // -------------------------------------------------------------------------
    // Full / empty flags
    // -------------------------------------------------------------------------
    // Pointers equal                  => empty
    // Pointers differ only in MSB     => full
    logic full_flag;
    logic empty_flag;

    assign full_flag  = (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1]) &&
                        (wr_ptr[PTR_WIDTH-2:0] == rd_ptr[PTR_WIDTH-2:0]);
    assign empty_flag = (wr_ptr == rd_ptr);

    // -------------------------------------------------------------------------
    // Ready / valid outputs
    // -------------------------------------------------------------------------
    assign in_ready  = !full_flag;
    assign out_valid = !empty_flag;

    // Combinational read: data at the head is always presented without an
    // extra latency cycle, so the first word is visible as soon as out_valid
    // is asserted.
    assign out_data  = mem[rd_ptr[PTR_WIDTH-2:0]];

    // -------------------------------------------------------------------------
    // Write logic
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else begin
            if (in_valid & in_ready) begin
                mem[wr_ptr[PTR_WIDTH-2:0]] <= in_data;
                wr_ptr <= wr_ptr + 1'b1;
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
            if (out_valid & out_ready) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

endmodule
