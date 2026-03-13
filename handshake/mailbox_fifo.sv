// -----------------------------------------------------------------------------
// Module: mailbox_fifo
// Description:
//   Single-entry mailbox implementing the ready/valid handshake on both the
//   write (producer) and read (consumer) ports. The mailbox can hold exactly
//   one data word at a time.
//
//   The producer drives wr_valid and wr_data; wr_ready is asserted when the
//   mailbox is empty. The consumer sees rd_valid when a word is waiting and
//   asserts rd_ready to consume it.
//
// Parameters:
//   DATA_WIDTH - Width of the data bus in bits (default: 8)
//
// Ports:
//   clk      - Clock input (rising-edge triggered)
//   rst_n    - Active-low synchronous reset
//   wr_valid - Producer data valid
//   wr_ready - Producer ready (output); asserted when mailbox is empty
//   wr_data  - Producer data bus [DATA_WIDTH-1:0]
//   rd_valid - Consumer data valid (output); asserted when mailbox holds a word
//   rd_ready - Consumer ready
//   rd_data  - Consumer data bus [DATA_WIDTH-1:0] (output)
//
// Behavior:
//   - When wr_valid & wr_ready: word is latched into the mailbox.
//   - When rd_valid & rd_ready: word is consumed, mailbox becomes empty.
//   - If both wr and rd fire in the same cycle (simultaneous write and read),
//     the new word is stored and the old word is forwarded; occupancy stays 1.
//   - wr_ready and rd_valid are mutually exclusive under normal operation
//     EXCEPT during the simultaneous write/read cycle described above.
//
// Timing assumptions:
//   - wr_valid/wr_data must be stable before the rising clock edge.
//   - rd_ready is sampled on the rising clock edge.
//
// Usage notes:
//   - Suitable for single-word message passing between pipeline stages.
//   - For deeper buffering use elastic_buffer.
//
// Example instantiation:
//   mailbox_fifo #(
//     .DATA_WIDTH(32)
//   ) u_mbox (
//     .clk     (clk),
//     .rst_n   (rst_n),
//     .wr_valid(prod_valid),
//     .wr_ready(prod_ready),
//     .wr_data (prod_data),
//     .rd_valid(cons_valid),
//     .rd_ready(cons_ready),
//     .rd_data (cons_data)
//   );
// -----------------------------------------------------------------------------

module mailbox_fifo #(
    parameter int DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // Write (producer) interface
    input  logic                  wr_valid,
    output logic                  wr_ready,
    input  logic [DATA_WIDTH-1:0] wr_data,

    // Read (consumer) interface
    output logic                  rd_valid,
    input  logic                  rd_ready,
    output logic [DATA_WIDTH-1:0] rd_data
);

    // -------------------------------------------------------------------------
    // Internal registers
    // -------------------------------------------------------------------------
    logic                  occupied;
    logic [DATA_WIDTH-1:0] data_r;

    // -------------------------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------------------------
    assign wr_ready = !occupied | (rd_valid & rd_ready); // Empty, or draining this cycle
    assign rd_valid = occupied;
    assign rd_data  = data_r;

    // -------------------------------------------------------------------------
    // Mailbox register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            occupied <= 1'b0;
            data_r   <= '0;
        end else begin
            if (wr_valid & wr_ready) begin
                // Accept new word (mailbox was empty, or was drained this cycle)
                occupied <= 1'b1;
                data_r   <= wr_data;
            end else if (rd_valid & rd_ready) begin
                // Consumer consumed the word; mailbox now empty
                occupied <= 1'b0;
            end
        end
    end

endmodule
