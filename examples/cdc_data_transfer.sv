// =============================================================================
// Example: cdc_data_transfer
//
// Description:
//   Demonstrates safe clock-domain crossing for a data word using:
//     - async_fifo            (main data path CDC buffer)
//     - reset_synchronizer    (per-domain reset management)
//     - gray_encoder          (inline illustration of pointer encoding)
//     - sync_2ff              (inline illustration of single-bit sync)
//
// This module bridges a streaming producer in clk_src to a consumer in clk_dst.
// =============================================================================

module cdc_data_transfer #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4    // FIFO depth = 2^ADDR_WIDTH
) (
    // Source (write) clock domain
    input  logic                  src_clk,
    input  logic                  src_async_rst_n,
    input  logic                  src_valid,
    output logic                  src_ready,       // FIFO not full
    input  logic [DATA_WIDTH-1:0] src_data,

    // Destination (read) clock domain
    input  logic                  dst_clk,
    input  logic                  dst_async_rst_n,
    output logic                  dst_valid,       // FIFO not empty
    input  logic                  dst_ready,
    output logic [DATA_WIDTH-1:0] dst_data
);

    // -------------------------------------------------------------------------
    // Synchronized resets for each clock domain
    // -------------------------------------------------------------------------
    logic src_rst_n, dst_rst_n;

    reset_synchronizer #(.STAGES(2)) u_src_rst (
        .clk        (src_clk),
        .async_rst_n(src_async_rst_n),
        .sync_rst_n (src_rst_n)
    );

    reset_synchronizer #(.STAGES(2)) u_dst_rst (
        .clk        (dst_clk),
        .async_rst_n(dst_async_rst_n),
        .sync_rst_n (dst_rst_n)
    );

    // -------------------------------------------------------------------------
    // Asynchronous FIFO — main data path CDC element
    // -------------------------------------------------------------------------
    logic wr_full, rd_empty;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_fifo (
        .wr_clk  (src_clk),
        .wr_rst_n(src_rst_n),
        .wr_en   (src_valid & ~wr_full),
        .wr_data (src_data),
        .wr_full (wr_full),

        .rd_clk  (dst_clk),
        .rd_rst_n(dst_rst_n),
        .rd_en   (dst_ready & ~rd_empty),
        .rd_data (dst_data),
        .rd_empty(rd_empty)
    );

    assign src_ready  = ~wr_full;
    assign dst_valid  = ~rd_empty;

endmodule
