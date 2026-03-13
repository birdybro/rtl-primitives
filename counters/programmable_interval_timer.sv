// =============================================================================
// Module: programmable_interval_timer
// Description:
//   Generates periodic tick pulses at a configurable interval. An internal
//   up-counter increments from 0 each enabled clock cycle. When count reaches
//   (period - 1), tick pulses for exactly one clock cycle and the counter
//   reloads to 0. In one_shot mode the counter halts after the first tick
//   until re-enabled. In periodic mode (one_shot=0) the counter automatically
//   reloads and continues generating ticks.
//
// Parameters:
//   WIDTH  - Bit width of the counter and period input (default: 16).
//            Maximum programmable period = 2^WIDTH - 1 clock cycles.
//
// Ports:
//   clk      - Clock input (rising edge triggered)
//   rst_n    - Active-low synchronous reset; resets counter to 0, clears tick
//   en       - Enable: timer counts only when en=1; halting en mid-count
//              freezes the count (does not reset it)
//   period   - Tick interval in clock cycles [WIDTH-1:0]. The timer fires
//              after (period) enabled clock cycles (count 0 to period-1).
//              A period of 0 disables tick generation.
//   one_shot - Mode select: 0=periodic (auto-reload), 1=one-shot (halts
//              after the first tick; re-assert en to restart, count resets
//              to 0 after firing)
//   tick     - One-cycle pulse asserted when count reaches (period - 1)
//              and en is asserted
//   count    - Current counter value [WIDTH-1:0]
//
// Timing/Behavior:
//   - All state changes occur on the rising edge of clk
//   - rst_n is synchronous and active low
//   - tick is a registered one-cycle pulse coinciding with count == 0 on the
//     cycle following the terminal count (count wraps to 0 when tick fires)
//   - Changing period mid-count takes effect on the next counter reload
//   - In one_shot mode the counter is held at 0 after firing; de-asserting
//     and re-asserting en does NOT restart; re-assert en after rst_n to
//     restart (or use periodic mode and gate en externally)
//   - period=1 causes tick every enabled cycle
//
// Usage Notes:
//   - Use periodic mode for regular interrupt generation (e.g., system tick)
//   - Use one_shot mode for single-event delays
//   - The count output can be used for time-since-last-tick measurements
//
// Example Instantiation:
//   programmable_interval_timer #(
//     .WIDTH(16)
//   ) u_pit (
//     .clk      (clk),
//     .rst_n    (rst_n),
//     .en       (timer_en),
//     .period   (16'd1000),
//     .one_shot (1'b0),
//     .tick     (sys_tick),
//     .count    (timer_count[15:0])
//   );
// =============================================================================

module programmable_interval_timer #(
  parameter int unsigned WIDTH = 16
) (
  input  logic              clk,
  input  logic              rst_n,
  input  logic              en,
  input  logic [WIDTH-1:0]  period,
  input  logic              one_shot,
  output logic              tick,
  output logic [WIDTH-1:0]  count
);

  // terminal is the last count value before reload (period - 1)
  // When period==0 the timer is disabled; no tick is ever generated.
  logic              tick_next;
  logic [WIDTH-1:0]  count_next;
  // one_shot_done: latched after first tick in one_shot mode
  logic              one_shot_done;

  always_comb begin
    tick_next  = 1'b0;
    count_next = count;

    if (en && !one_shot_done && (period != '0)) begin
      if (count >= (period - 1'b1)) begin
        // Terminal count reached
        tick_next  = 1'b1;
        count_next = '0;
      end else begin
        count_next = count + 1'b1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count         <= '0;
      tick          <= 1'b0;
      one_shot_done <= 1'b0;
    end else begin
      tick  <= tick_next;
      count <= count_next;
      if (tick_next && one_shot) begin
        one_shot_done <= 1'b1;
      end
    end
  end

endmodule
