// =============================================================================
// Module: simple_fifo
// Description:
//   Synchronous, single-clock FIFO with configurable data width and depth.
//   Implemented with a circular buffer using separate write and read pointers.
//   An extra count register (one bit wider than the address) is maintained to
//   distinguish the full and empty conditions without ambiguity.
//
// Parameters:
//   DATA_WIDTH - Width of each data word in bits (default: 8)
//   DEPTH      - Number of entries (default: 16); should be a power of two
//   ADDR_WIDTH - Address pointer width, derived as $clog2(DEPTH)
//
// Ports:
//   clk     - System clock (rising-edge triggered)
//   rst_n   - Asynchronous active-low reset
//   wr_en   - Write enable; ignored when full
//   wr_data - Data word to push
//   rd_en   - Read enable; ignored when empty
//   rd_data - Data word popped (registered, valid one cycle after rd_en)
//   full    - Asserted when the FIFO cannot accept more data
//   empty   - Asserted when the FIFO has no valid data
//   count   - Number of valid entries currently stored
//
// Timing / Behaviour:
//   - Write and read may occur on the same clock edge (simultaneous push/pop
//     is supported and does not change the count).
//   - Read latency: 1 clock cycle (rd_data is registered).
//   - All outputs are synchronous to clk; reset de-assertion is asynchronous.
//
// Usage Notes:
//   - Do not assert wr_en when full; data will be silently discarded.
//   - Do not assert rd_en when empty; rd_data will retain its last value.
//   - DEPTH must be at least 2 and should be a power of two.
//
// Example Instantiation:
//   simple_fifo #(
//     .DATA_WIDTH(8),
//     .DEPTH     (16)
//   ) u_fifo (
//     .clk    (clk),
//     .rst_n  (rst_n),
//     .wr_en  (wr_en),
//     .wr_data(wr_data),
//     .rd_en  (rd_en),
//     .rd_data(rd_data),
//     .full   (full),
//     .empty  (empty),
//     .count  (count)
//   );
// =============================================================================

module simple_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16,
    parameter int ADDR_WIDTH = $clog2(DEPTH)
) (
    input  logic                          clk,
    input  logic                          rst_n,

    input  logic                          wr_en,
    input  logic [DATA_WIDTH-1:0]         wr_data,

    input  logic                          rd_en,
    output logic [DATA_WIDTH-1:0]         rd_data,

    output logic                          full,
    output logic                          empty,
    output logic [$clog2(DEPTH+1)-1:0]    count
);

    // Storage array
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;
    // One extra bit in count covers the range [0, DEPTH] inclusive
    logic [$clog2(DEPTH+1)-1:0] count_r;

    assign full  = (count_r == DEPTH[$clog2(DEPTH+1)-1:0]);
    assign empty = (count_r == '0);
    assign count = count_r;

    // Qualify enables to prevent overflow / underflow
    wire do_write = wr_en && !full;
    wire do_read  = rd_en && !empty;

    // Write path
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (do_write) begin
            mem[wr_ptr] <= wr_data;
            wr_ptr      <= wr_ptr + 1'b1;
        end
    end

    // Read path — registered output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr  <= '0;
            rd_data <= '0;
        end else if (do_read) begin
            rd_data <= mem[rd_ptr];
            rd_ptr  <= rd_ptr + 1'b1;
        end
    end

    // Count tracking
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_r <= '0;
        end else begin
            unique case ({do_write, do_read})
                2'b10:   count_r <= count_r + 1'b1;
                2'b01:   count_r <= count_r - 1'b1;
                default: count_r <= count_r;       // 00 or 11 (no net change)
            endcase
        end
    end

endmodule
