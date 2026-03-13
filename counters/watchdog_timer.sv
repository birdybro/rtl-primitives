// =============================================================================
// Module: watchdog_timer
// Description:
//   Programmable watchdog timer. An internal down-counter counts from
//   timeout_val toward zero. If the counter reaches zero before being
//   restarted (kicked), the timeout output pulses for exactly one clock cycle.
//   After timeout, the counter stops until kick is asserted. Asserting kick
//   at any time reloads the counter with timeout_val and resumes counting.
//
// Parameters:
//   TIMEOUT_WIDTH  - Width of the timeout counter in bits (default: 16).
//                    Maximum programmable timeout = 2^TIMEOUT_WIDTH - 1 cycles.
//
// Ports:
//   clk         - Clock input (rising edge triggered)
//   rst_n       - Active-low synchronous reset; resets counter and clears timeout
//   kick        - Reload input: reloads counter with timeout_val and restarts
//                 the countdown (may be asserted at any time, including after
//                 timeout)
//   timeout_val - Programmable timeout period [TIMEOUT_WIDTH-1:0] in clock
//                 cycles. Sampled on rst_n de-assertion and on each kick.
//                 A value of 0 disables the watchdog (counter holds at 0,
//                 timeout never asserted).
//   timeout     - One-cycle pulse asserted the cycle the counter expires
//                 (transitions from 1 to 0 with no pending kick)
//
// Timing/Behavior:
//   - All state changes occur on the rising edge of clk
//   - rst_n is synchronous and active low; on reset the counter is loaded
//     with timeout_val and counting begins
//   - kick reloads the counter synchronously and clears any pending timeout
//   - timeout is a registered one-cycle pulse; it does not repeat until the
//     next kick reloads and the counter expires again
//   - If timeout_val changes while counting, the new value takes effect on
//     the next kick
//
// Usage Notes:
//   - The software/hardware watchdog "service routine" must assert kick for
//     at least one clock cycle before the counter reaches 0
//   - A timeout_val of 1 causes timeout on the very next cycle after kick
//   - Connect timeout to a system reset or interrupt controller
//
// Example Instantiation:
//   watchdog_timer #(
//     .TIMEOUT_WIDTH(16)
//   ) u_watchdog (
//     .clk         (clk),
//     .rst_n       (rst_n),
//     .kick        (wdt_kick),
//     .timeout_val (16'd50000),
//     .timeout     (wdt_timeout)
//   );
// =============================================================================

module watchdog_timer #(
  parameter int unsigned TIMEOUT_WIDTH = 16
) (
  input  logic                      clk,
  input  logic                      rst_n,
  input  logic                      kick,
  input  logic [TIMEOUT_WIDTH-1:0]  timeout_val,
  output logic                      timeout
);

  logic [TIMEOUT_WIDTH-1:0] count;
  logic                     timeout_next;
  // Track whether the timer has already fired (stopped state)
  logic                     expired;

  always_comb begin
    // timeout pulses on the cycle when count reaches 1 and is about to
    // decrement to 0 (i.e., count == 1 with no kick, timeout_val != 0)
    timeout_next = (!kick) && (!expired) && (count == {{(TIMEOUT_WIDTH-1){1'b0}}, 1'b1})
                   && (timeout_val != '0);
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count   <= timeout_val;
      timeout <= 1'b0;
      expired <= 1'b0;
    end else begin
      timeout <= timeout_next;
      if (kick) begin
        count   <= timeout_val;
        expired <= 1'b0;
      end else if (!expired && (timeout_val != '0)) begin
        if (count == '0) begin
          expired <= 1'b1;
        end else begin
          count <= count - 1'b1;
        end
      end
    end
  end

endmodule
