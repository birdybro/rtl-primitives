// =============================================================================
// Module: saturating_counter
// Description:
//   Synchronous bidirectional saturating counter. Instead of wrapping on
//   overflow/underflow, the count value is clamped at its maximum
//   (2^WIDTH - 1) when counting up and at 0 when counting down.
//   at_max and at_min are combinational status flags.
//
// Parameters:
//   WIDTH  - Counter bit width (default: 8). Determines count range [0, 2^WIDTH-1].
//
// Ports:
//   clk      - Clock input (rising edge triggered)
//   rst_n    - Active-low synchronous reset; resets count to 0
//   en       - Enable: counter changes only when en=1
//   up_dn    - Direction: 1=count up, 0=count down
//   load     - Parallel load: when asserted, count is loaded with load_val
//              (load takes priority over en)
//   load_val - Value to load when load=1 [WIDTH-1:0]
//   count    - Current counter value [WIDTH-1:0]
//   at_max   - Combinational flag: asserted when count == 2^WIDTH - 1
//   at_min   - Combinational flag: asserted when count == 0
//
// Timing/Behavior:
//   - All state changes occur on the rising edge of clk
//   - rst_n is synchronous and active low
//   - load has highest priority, then en
//   - at_max and at_min are purely combinational (no pipeline delay)
//   - When at_max and counting up (and not loading), count holds at MAX
//   - When at_min and counting down (and not loading), count holds at 0
//   - load_val can exceed MAX only if WIDTH allows it (always in range by type)
//
// Usage Notes:
//   - Useful for confidence counters, rate limiters, and saturating accumulators
//   - at_max / at_min can gate further increments/decrements externally
//
// Example Instantiation:
//   saturating_counter #(
//     .WIDTH(8)
//   ) u_sat_counter (
//     .clk      (clk),
//     .rst_n    (rst_n),
//     .en       (count_en),
//     .up_dn    (direction),
//     .load     (load),
//     .load_val (load_val[7:0]),
//     .count    (count[7:0]),
//     .at_max   (at_max),
//     .at_min   (at_min)
//   );
// =============================================================================

module saturating_counter #(
  parameter int unsigned WIDTH = 8
) (
  input  logic              clk,
  input  logic              rst_n,
  input  logic              en,
  input  logic              up_dn,
  input  logic              load,
  input  logic [WIDTH-1:0]  load_val,
  output logic [WIDTH-1:0]  count,
  output logic              at_max,
  output logic              at_min
);

  localparam logic [WIDTH-1:0] MAX = '1;

  logic [WIDTH-1:0] count_next;

  always_comb begin
    at_max = (count == MAX);
    at_min = (count == '0);

    if (load) begin
      count_next = load_val;
    end else if (en) begin
      if (up_dn) begin
        count_next = at_max ? MAX : (count + 1'b1);
      end else begin
        count_next = at_min ? '0  : (count - 1'b1);
      end
    end else begin
      count_next = count;
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count <= '0;
    end else begin
      count <= count_next;
    end
  end

endmodule
