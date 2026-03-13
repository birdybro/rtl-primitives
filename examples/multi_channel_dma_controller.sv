// =============================================================================
// Example: multi_channel_dma_controller
//
// Description:
//   A simple 4-channel DMA controller demonstrating the use of:
//     - weighted_round_robin_arbiter  (arbitrate among channel requests)
//     - simple_fifo                   (per-channel data buffers)
//     - up_counter                    (transfer byte counter per channel)
//     - event_counter                 (count completed transfers)
//
// This is a structural/illustrative example, not a synthesisable bus master.
// =============================================================================

module multi_channel_dma_controller #(
    parameter int NUM_CH     = 4,   // number of DMA channels
    parameter int DATA_WIDTH = 32,  // bus width
    parameter int FIFO_DEPTH = 8,   // samples per channel FIFO
    parameter int CNT_WIDTH  = 16   // transfer counter width
) (
    input  logic                                 clk,
    input  logic                                 rst_n,

    // Per-channel write interfaces (producers)
    input  logic [NUM_CH-1:0]                    ch_wr_en,
    input  logic [NUM_CH-1:0][DATA_WIDTH-1:0]    ch_wr_data,

    // Per-channel weight (higher weight = more bus grants)
    input  logic [NUM_CH-1:0][3:0]               ch_weight,

    // Shared bus output
    output logic                                 bus_valid,
    output logic [DATA_WIDTH-1:0]                bus_data,
    output logic [$clog2(NUM_CH)-1:0]            bus_ch_id,

    // Transfer statistics
    output logic [CNT_WIDTH-1:0]                 total_xfers
);

    // -------------------------------------------------------------------------
    // Per-channel FIFOs
    // -------------------------------------------------------------------------
    logic [NUM_CH-1:0]                  ch_rd_en;
    logic [NUM_CH-1:0][DATA_WIDTH-1:0]  ch_rd_data;
    logic [NUM_CH-1:0]                  ch_full;
    logic [NUM_CH-1:0]                  ch_empty;

    genvar g;
    generate
        for (g = 0; g < NUM_CH; g++) begin : gen_ch_fifo
            simple_fifo #(
                .DATA_WIDTH(DATA_WIDTH),
                .DEPTH     (FIFO_DEPTH)
            ) u_fifo (
                .clk    (clk),
                .rst_n  (rst_n),
                .wr_en  (ch_wr_en[g]),
                .wr_data(ch_wr_data[g]),
                .rd_en  (ch_rd_en[g]),
                .rd_data(ch_rd_data[g]),
                .full   (ch_full[g]),
                .empty  (ch_empty[g]),
                .count  (/* unused */)
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Weighted Round-Robin Arbiter
    // Each channel requests the bus when its FIFO is non-empty
    // -------------------------------------------------------------------------
    logic [NUM_CH-1:0] ch_req;
    logic [NUM_CH-1:0] ch_gnt;

    assign ch_req = ~ch_empty; // request if data available

    weighted_round_robin_arbiter #(
        .NUM_REQS    (NUM_CH),
        .WEIGHT_WIDTH(4)
    ) u_arb (
        .clk   (clk),
        .rst_n (rst_n),
        .req   (ch_req),
        .weight(ch_weight),
        .gnt   (ch_gnt)
    );

    // -------------------------------------------------------------------------
    // Grant decode: read from the granted channel's FIFO
    // -------------------------------------------------------------------------
    logic [$clog2(NUM_CH)-1:0] gnt_idx;
    logic                      any_gnt;

    // Convert one-hot grant to binary index using priority_encoder
    priority_encoder #(.WIDTH(NUM_CH)) u_gnt_enc (
        .in   (ch_gnt),
        .out  (gnt_idx),
        .valid(any_gnt)
    );

    always_comb begin
        ch_rd_en = '0;
        if (any_gnt) ch_rd_en[gnt_idx] = 1'b1;
    end

    // -------------------------------------------------------------------------
    // Bus output register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_valid <= 1'b0;
            bus_data  <= '0;
            bus_ch_id <= '0;
        end else begin
            bus_valid <= any_gnt;
            bus_data  <= ch_rd_data[gnt_idx];
            bus_ch_id <= gnt_idx;
        end
    end

    // -------------------------------------------------------------------------
    // Transfer counter: count each successful bus transaction
    // -------------------------------------------------------------------------
    event_counter #(.WIDTH(CNT_WIDTH)) u_xfer_cnt (
        .clk          (clk),
        .rst_n        (rst_n),
        .event_in     (any_gnt),
        .threshold    ('1),          // threshold = MAX (never fire)
        .count        (total_xfers),
        .threshold_hit(/* unused */),
        .clr          (1'b0)
    );

endmodule
