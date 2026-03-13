// =============================================================================
// Module: reset_pulse_generator
// Description:
//   Detects the rising edge of the synchronous reset request signal rst_req and
//   generates a synchronous active-high reset pulse of exactly PULSE_WIDTH clock
//   cycles. The pulse begins on the clock cycle following the rising edge of
//   rst_req. Any additional assertion of rst_req while a pulse is already active
//   extends the pulse for another PULSE_WIDTH cycles from the new rising edge.
//
// Parameters:
//   PULSE_WIDTH - Duration of the generated reset pulse in clock cycles (default: 4)
//
// Ports:
//   clk       - Clock input
//   rst_n     - Active-low asynchronous reset (resets this module's state)
//   rst_req   - Synchronous reset request input (active high, edge-detected)
//   rst_pulse - Active-high synchronous reset pulse output, PULSE_WIDTH cycles wide
//
// Timing/Behavior:
//   - rst_req is sampled on the rising edge of clk
//   - A rising edge on rst_req (0->1) starts the pulse counter
//   - rst_pulse asserts HIGH for exactly PULSE_WIDTH cycles after each rising edge
//   - rst_pulse is LOW at all other times
//   - rst_n LOW forces rst_pulse LOW and clears internal state
//
// Usage Notes:
//   - rst_req should be a registered, glitch-free signal in the same clock domain
//   - Downstream modules should treat rst_pulse as a synchronous reset
//   - For level-triggered behavior (not edge), compare against reset_stretcher
//   - PULSE_WIDTH must be >= 1
//
// Example Instantiation:
//   reset_pulse_generator #(
//     .PULSE_WIDTH(8)
//   ) u_rst_pulse (
//     .clk      (clk),
//     .rst_n    (por_rst_n),
//     .rst_req  (sw_reset_req),
//     .rst_pulse(sw_rst_pulse)
//   );
// =============================================================================

module reset_pulse_generator #(
    parameter int unsigned PULSE_WIDTH = 4
) (
    input  logic clk,
    input  logic rst_n,
    input  logic rst_req,
    output logic rst_pulse
);

    localparam int unsigned CNT_W = $clog2(PULSE_WIDTH + 1);

    logic [CNT_W-1:0] count;
    logic             rst_req_prev;
    logic             rising_edge;

    assign rising_edge = rst_req & ~rst_req_prev;
    assign rst_pulse   = (count != '0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_req_prev <= 1'b0;
            count        <= '0;
        end else begin
            rst_req_prev <= rst_req;
            if (rising_edge) begin
                count <= CNT_W'(PULSE_WIDTH);
            end else if (rst_pulse) begin
                count <= count - 1'b1;
            end
        end
    end

endmodule
