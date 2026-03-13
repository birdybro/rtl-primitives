// =============================================================================
// Example: multi_domain_system
//
// Description:
//   Complete multi-clock-domain system skeleton demonstrating:
//     - power_on_reset        (single POR source)
//     - reset_synchronizer    (per-domain reset)
//     - reset_controller      (sequenced multi-domain release)
//     - async_fifo            (CDC data path: fast → slow domain)
//     - clock_divider         (derive a slow enable from fast clock)
//     - clock_activity_detector (monitor the slow domain clock)
//     - round_robin_arbiter   (fair access to shared resource)
//     - skid_buffer           (backpressure-tolerant output stage)
//
// Block diagram:
//
//   [fast_clk] ──► POR ──► reset_controller ──► sync reset (fast domain)
//                                             └──► sync reset (slow domain)
//
//   [fast_clk, fast data] ──► async_fifo ──► [slow_clk, slow consumer]
//
//   [fast_clk] ──► round_robin_arbiter ──► skid_buffer ──► output
// =============================================================================

module multi_domain_system #(
    parameter int DATA_WIDTH  = 8,
    parameter int FIFO_AW     = 4,   // async FIFO depth = 2^FIFO_AW
    parameter int NUM_MASTERS = 3
) (
    // Fast clock domain (producer / master side)
    input  logic                                  fast_clk,

    // Slow clock domain (consumer side)
    input  logic                                  slow_clk,

    // Global asynchronous reset (from board)
    input  logic                                  board_rst_n,

    // Per-master request and data (fast domain)
    input  logic [NUM_MASTERS-1:0]                mst_req,
    input  logic [NUM_MASTERS-1:0][DATA_WIDTH-1:0] mst_data,

    // Slow-domain consumer
    output logic                                  slow_valid,
    output logic [DATA_WIDTH-1:0]                 slow_data,
    input  logic                                  slow_ready,

    // Status
    output logic                                  slow_clk_ok,
    output logic [NUM_MASTERS-1:0]                mst_gnt
);

    // =========================================================================
    // 1. Power-on reset generation (fast_clk domain)
    // =========================================================================
    logic por_rst_n;

    power_on_reset #(.DEPTH(16)) u_por (
        .clk      (fast_clk),
        .por_rst_n(por_rst_n)
    );

    // =========================================================================
    // 2. Multi-domain reset controller
    //    Domain 0 = fast, Domain 1 = slow
    // =========================================================================
    logic [1:0] domain_rst_n_raw;

    reset_controller #(
        .NUM_DOMAINS   (2),
        .STRETCH_CYCLES(16)
    ) u_rst_ctrl (
        .clk      (fast_clk),
        .rst_n    (por_rst_n),
        .por_req  (1'b0),
        .rst_req  (2'b00),
        .rst_n_out(domain_rst_n_raw)
    );

    // Synchronize to each domain
    logic fast_rst_n, slow_rst_n_sync;

    reset_synchronizer #(.STAGES(2)) u_fast_rst_sync (
        .clk        (fast_clk),
        .async_rst_n(domain_rst_n_raw[0] & board_rst_n),
        .sync_rst_n (fast_rst_n)
    );

    reset_synchronizer #(.STAGES(2)) u_slow_rst_sync (
        .clk        (slow_clk),
        .async_rst_n(domain_rst_n_raw[1] & board_rst_n),
        .sync_rst_n (slow_rst_n_sync)
    );

    // =========================================================================
    // 3. Clock activity detection for slow_clk
    // =========================================================================
    clock_activity_detector #(.WINDOW_CYCLES(32)) u_clk_det (
        .ref_clk(fast_clk),
        .rst_n  (fast_rst_n),
        .mon_clk(slow_clk),
        .active (slow_clk_ok)
    );

    // =========================================================================
    // 4. Round-robin arbiter across masters (fast domain)
    // =========================================================================
    logic [NUM_MASTERS-1:0] arb_gnt;
    logic [$clog2(NUM_MASTERS)-1:0] gnt_idx;
    logic any_gnt;

    round_robin_arbiter #(.NUM_REQS(NUM_MASTERS)) u_rr_arb (
        .clk  (fast_clk),
        .rst_n(fast_rst_n),
        .req  (mst_req),
        .gnt  (arb_gnt)
    );

    assign mst_gnt = arb_gnt;

    priority_encoder #(.WIDTH(NUM_MASTERS)) u_gnt_enc (
        .in   (arb_gnt),
        .out  (gnt_idx),
        .valid(any_gnt)
    );

    // =========================================================================
    // 5. Async FIFO: fast domain producer → slow domain consumer
    // =========================================================================
    logic fifo_wr_en, fifo_wr_full;
    logic fifo_rd_empty;
    logic [DATA_WIDTH-1:0] fifo_rd_data;

    assign fifo_wr_en = any_gnt & ~fifo_wr_full;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(FIFO_AW)
    ) u_cdc_fifo (
        .wr_clk  (fast_clk),
        .wr_rst_n(fast_rst_n),
        .wr_en   (fifo_wr_en),
        .wr_data (mst_data[gnt_idx]),
        .wr_full (fifo_wr_full),

        .rd_clk  (slow_clk),
        .rd_rst_n(slow_rst_n_sync),
        .rd_en   (~fifo_rd_empty & slow_ready),
        .rd_data (fifo_rd_data),
        .rd_empty(fifo_rd_empty)
    );

    // =========================================================================
    // 6. Skid buffer on slow-domain output for backpressure tolerance
    // =========================================================================
    logic skid_in_valid, skid_in_ready;
    logic [DATA_WIDTH-1:0] skid_in_data;

    assign skid_in_valid = ~fifo_rd_empty;
    assign skid_in_data  = fifo_rd_data;

    skid_buffer #(.DATA_WIDTH(DATA_WIDTH)) u_skid (
        .clk      (slow_clk),
        .rst_n    (slow_rst_n_sync),
        .in_valid (skid_in_valid),
        .in_ready (skid_in_ready),
        .in_data  (skid_in_data),
        .out_valid(slow_valid),
        .out_ready(slow_ready),
        .out_data (slow_data)
    );

endmodule
