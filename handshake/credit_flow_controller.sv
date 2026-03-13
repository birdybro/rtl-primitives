// -----------------------------------------------------------------------------
// Module: credit_flow_controller
// Description:
//   Credit-based flow control unit. The receiver pre-grants N credits to the
//   sender. Each time the sender transmits a word it consumes one credit; each
//   time the receiver processes a word it returns one credit. The sender may
//   only transmit when it holds at least one credit, preventing overflow at
//   the receiver.
//
//   This module sits on the SENDER side: it tracks the credit count, gates
//   transmission requests, and presents received data to the downstream
//   consumer.
//
// Parameters:
//   DATA_WIDTH  - Width of the data bus in bits (default: 8)
//   MAX_CREDITS - Maximum number of outstanding credits (default: 4)
//                 Determines the buffer depth on the receiver side.
//
// Ports:
//   clk        - Clock input (rising-edge triggered)
//   rst_n      - Active-low synchronous reset
//   credit_in  - Pulse from receiver: one returned credit per assertion
//   send_req   - Sender requests to transmit send_data
//   send_data  - Data to transmit [DATA_WIDTH-1:0]
//   send_ack   - Output: transmission accepted (send_req & credit available)
//   recv_valid - Output: data forwarded to downstream consumer
//   recv_data  - Output: forwarded data [DATA_WIDTH-1:0]
//
// Behavior:
//   - On reset, credit count initialises to MAX_CREDITS (receiver buffer empty).
//   - send_ack is asserted when send_req is high and credits > 0.
//   - On send_ack, credit count decrements by 1 and recv_valid/recv_data pulse
//     for one cycle.
//   - On credit_in, credit count increments by 1 (capped at MAX_CREDITS).
//   - Simultaneous credit_in and send_ack: count stays the same (net zero).
//   - recv_valid is registered and recv_data is registered one cycle after
//     send_ack. Both recv_valid and recv_data are always delayed by exactly
//     1 cycle from send_ack, forming a coherent valid/data pair at the output.
//
// Timing assumptions:
//   - credit_in is a single-cycle pulse (not a level signal).
//   - send_req / send_data must be stable before the rising clock edge.
//   - The downstream consumer of recv_valid/recv_data must tolerate 1-cycle
//     latency from send_ack.
//
// Usage notes:
//   - MAX_CREDITS should match the depth of the receive-side buffer so that
//     the sender never overflows it.
//   - To connect two chips, credit_in would travel back across the link.
//
// Example instantiation:
//   credit_flow_controller #(
//     .DATA_WIDTH (8),
//     .MAX_CREDITS(4)
//   ) u_cfc (
//     .clk       (clk),
//     .rst_n     (rst_n),
//     .credit_in (rx_credit_return),
//     .send_req  (tx_req),
//     .send_data (tx_data),
//     .send_ack  (tx_ack),
//     .recv_valid(pipe_valid),
//     .recv_data (pipe_data)
//   );
// -----------------------------------------------------------------------------

module credit_flow_controller #(
    parameter int DATA_WIDTH  = 8,
    parameter int MAX_CREDITS = 4
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // Credit return from receiver
    input  logic                  credit_in,

    // Send interface (from upstream sender)
    input  logic                  send_req,
    input  logic [DATA_WIDTH-1:0] send_data,
    output logic                  send_ack,

    // Receive interface (to downstream consumer)
    output logic                  recv_valid,
    output logic [DATA_WIDTH-1:0] recv_data
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam int CREDIT_WIDTH = $clog2(MAX_CREDITS + 1);

    // -------------------------------------------------------------------------
    // Credit counter
    // -------------------------------------------------------------------------
    logic [CREDIT_WIDTH-1:0] credits;

    // -------------------------------------------------------------------------
    // Send acknowledgement: granted when sender requests and credits available
    // -------------------------------------------------------------------------
    assign send_ack = send_req & (credits > '0);

    // -------------------------------------------------------------------------
    // Credit counter update
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            credits <= CREDIT_WIDTH'(MAX_CREDITS);
        end else begin
            unique case ({credit_in, send_ack})
                2'b10: credits <= credits + 1'b1; // Return only
                2'b01: credits <= credits - 1'b1; // Consume only
                default: ; // 2'b00 or 2'b11 — no net change
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Output data register: data travels one cycle after send_ack
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            recv_valid <= 1'b0;
            recv_data  <= '0;
        end else begin
            recv_valid <= send_ack;
            if (send_ack) begin
                recv_data <= send_data;
            end
        end
    end

endmodule
