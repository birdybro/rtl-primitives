// =============================================================================
// Module: circular_buffer
// Description:
//   General-purpose circular (ring) buffer with independently controlled
//   head (read) and tail (write) pointers.  Provides full/empty status flags
//   and an entry count.  The implementation is functionally equivalent to a
//   synchronous FIFO but is explicitly named to emphasise the ring-pointer
//   semantics useful in streaming and producer-consumer designs.
//
// Parameters:
//   DATA_WIDTH - Width of each data word in bits (default: 8)
//   DEPTH      - Number of entries in the ring (default: 8); power of two
//                recommended so that pointer wrap-around works naturally
//
// Ports:
//   clk     - System clock (rising-edge triggered)
//   rst_n   - Asynchronous active-low reset
//   wr_en   - Write (push) enable; ignored when full
//   wr_data - Data to write at the current tail pointer
//   rd_en   - Read (pop) enable; ignored when empty
//   rd_data - Data at the current head pointer (registered, 1-cycle latency)
//   full    - Asserted when the buffer is full (count == DEPTH)
//   empty   - Asserted when the buffer is empty (count == 0)
//   count   - Number of valid entries currently held
//
// Timing / Behaviour:
//   - Write and read may be asserted simultaneously; the count remains
//     unchanged in that case (one entry in, one entry out).
//   - rd_data is registered: it captures the value at head on the rising
//     edge following an asserted rd_en, similar to synchronous RAM read.
//   - Overflow (wr_en when full) and underflow (rd_en when empty) are
//     silently ignored; pointers and count are not modified.
//
// Usage Notes:
//   - For lock-free single-producer/single-consumer use, only one side
//     should modify its respective pointer at a time.
//   - DEPTH must be at least 2.
//
// Example Instantiation:
//   circular_buffer #(
//     .DATA_WIDTH(8),
//     .DEPTH     (8)
//   ) u_cbuf (
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

module circular_buffer #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 8
) (
    input  logic                        clk,
    input  logic                        rst_n,

    input  logic                        wr_en,
    input  logic [DATA_WIDTH-1:0]       wr_data,

    input  logic                        rd_en,
    output logic [DATA_WIDTH-1:0]       rd_data,

    output logic                        full,
    output logic                        empty,
    output logic [$clog2(DEPTH+1)-1:0]  count
);

    localparam int ADDR_WIDTH = $clog2(DEPTH);

    // Ring storage
    logic [DATA_WIDTH-1:0] ring [0:DEPTH-1];

    // Tail pointer (next write position), head pointer (next read position)
    logic [ADDR_WIDTH-1:0] tail;
    logic [ADDR_WIDTH-1:0] head;
    logic [$clog2(DEPTH+1)-1:0] count_r;

    assign full  = (count_r == DEPTH[$clog2(DEPTH+1)-1:0]);
    assign empty = (count_r == '0);
    assign count = count_r;

    wire do_write = wr_en && !full;
    wire do_read  = rd_en && !empty;

    // Write path: advance tail
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tail <= '0;
        end else if (do_write) begin
            ring[tail] <= wr_data;
            tail       <= (tail == ADDR_WIDTH'(DEPTH - 1)) ? '0 : tail + 1'b1;
        end
    end

    // Read path: advance head, registered output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head    <= '0;
            rd_data <= '0;
        end else if (do_read) begin
            rd_data <= ring[head];
            head    <= (head == ADDR_WIDTH'(DEPTH - 1)) ? '0 : head + 1'b1;
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
                default: count_r <= count_r;
            endcase
        end
    end

endmodule
