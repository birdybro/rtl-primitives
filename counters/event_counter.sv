// =============================================================================
// Module: event_counter
// Description:
//   Counts rising-edge events on event_in. Asserts threshold_hit (level) when
//   the accumulated count is greater than or equal to the threshold input.
//   A synchronous clear (clr) resets the count to zero. The counter saturates
//   at (2^WIDTH - 1) to prevent wrap-around from clearing threshold_hit.
//
// Parameters:
//   WIDTH  - Counter bit width (default: 16). Determines maximum event count.
//
// Ports:
//   clk           - Clock input (rising edge triggered)
//   rst_n         - Active-low synchronous reset; resets count to 0
//   event_in      - Event input; the counter increments on each cycle
//                   event_in=1 (level-sensitive, not edge-detected internally)
//   threshold     - Comparison value [WIDTH-1:0]; threshold_hit asserts when
//                   count >= threshold
//   count         - Current event count [WIDTH-1:0]
//   threshold_hit - Level output: high while count >= threshold
//   clr           - Synchronous clear: resets count to 0 when asserted
//                   (clr takes priority over event_in)
//
// Timing/Behavior:
//   - All state changes occur on the rising edge of clk
//   - rst_n is synchronous and active low
//   - clr has higher priority than event_in
//   - threshold_hit is combinational (reflects count and threshold immediately)
//   - Counter saturates at MAX (does not wrap); counts are never lost due to
//     overflow; clr must be used to reset
//   - event_in is treated as a level signal sampled each clock; for single-
//     cycle pulse events this is equivalent to edge counting
//
// Usage Notes:
//   - To count single-cycle pulses, ensure event_in is high for exactly one
//     clock cycle per event
//   - For edge detection on a slower signal, instantiate an edge detector
//     upstream and connect its output to event_in
//   - threshold=0 causes threshold_hit to be permanently asserted
//
// Example Instantiation:
//   event_counter #(
//     .WIDTH(16)
//   ) u_event_counter (
//     .clk           (clk),
//     .rst_n         (rst_n),
//     .event_in      (packet_valid),
//     .threshold     (16'd100),
//     .count         (event_count[15:0]),
//     .threshold_hit (threshold_hit),
//     .clr           (clear_count)
//   );
// =============================================================================

module event_counter #(
  parameter int unsigned WIDTH = 16
) (
  input  logic              clk,
  input  logic              rst_n,
  input  logic              event_in,
  input  logic [WIDTH-1:0]  threshold,
  output logic [WIDTH-1:0]  count,
  output logic              threshold_hit,
  input  logic              clr
);

  localparam logic [WIDTH-1:0] MAX = '1;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count <= '0;
    end else if (clr) begin
      count <= '0;
    end else if (event_in && (count != MAX)) begin
      count <= count + 1'b1;
    end
  end

  // Combinational threshold comparison
  always_comb begin
    threshold_hit = (count >= threshold);
  end

endmodule
