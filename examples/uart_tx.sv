// =============================================================================
// Example: uart_tx
//
// Description:
//   Simple UART transmitter demonstrating use of:
//     - clock_enable_generator  (baud-rate tick generation)
//     - pipeline_register        (registered stage for start-bit detection)
//     - down_counter             (bit position counter)
//     - skid_buffer              (input byte buffering)
//
// Protocol: 8N1 — 8 data bits, no parity, 1 stop bit.
// Baud rate is set by configuring clock_enable_generator's period to
// (clk_freq / baud_rate - 1).
// =============================================================================

module uart_tx #(
    parameter int CLK_WIDTH = 16   // width for baud period register
) (
    input  logic             clk,
    input  logic             rst_n,

    // Baud rate: period = clk_freq/baud_rate
    input  logic [CLK_WIDTH-1:0] baud_period,

    // AXI-style byte input
    input  logic             in_valid,
    output logic             in_ready,
    input  logic [7:0]       in_data,

    // UART serial output
    output logic             tx
);

    // -------------------------------------------------------------------------
    // Baud tick (one clock-wide pulse at the baud rate)
    // -------------------------------------------------------------------------
    logic baud_tick;
    logic baud_en;

    clock_enable_generator #(.WIDTH(CLK_WIDTH)) u_baud (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (baud_en),
        .period(baud_period),
        .clk_en(baud_tick)
    );

    // -------------------------------------------------------------------------
    // Input byte buffer (1-entry skid buffer absorbs one byte while TX is busy)
    // -------------------------------------------------------------------------
    logic        buf_valid, buf_ready;
    logic [7:0]  buf_data;

    skid_buffer #(.DATA_WIDTH(8)) u_buf (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .in_data  (in_data),
        .out_valid(buf_valid),
        .out_ready(buf_ready),
        .out_data (buf_data)
    );

    // -------------------------------------------------------------------------
    // TX state machine
    // State 0: IDLE       — wait for byte in buffer
    // State 1: START_BIT  — send start bit (0)
    // State 2: DATA_BITS  — send 8 data bits, LSB first
    // State 3: STOP_BIT   — send stop bit (1)
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3
    } state_t;

    state_t state;
    logic [7:0] shift_reg;
    logic [3:0] bit_cnt;     // counts 0..7 for data bits

    assign buf_ready = (state == IDLE);
    assign baud_en   = (state != IDLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            shift_reg <= 8'hFF;
            bit_cnt   <= '0;
            tx        <= 1'b1;  // UART idle = high
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (buf_valid) begin
                        shift_reg <= buf_data;
                        state     <= START;
                        bit_cnt   <= '0;
                    end
                end

                START: begin
                    tx <= 1'b0;  // start bit
                    if (baud_tick) state <= DATA;
                end

                DATA: begin
                    tx <= shift_reg[0];
                    if (baud_tick) begin
                        shift_reg <= {1'b1, shift_reg[7:1]}; // shift right
                        if (bit_cnt == 4'd7) begin
                            state <= STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1;  // stop bit
                    if (baud_tick) state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
