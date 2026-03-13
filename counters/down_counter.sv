// =============================================================================
// Module: down_counter
// Description:
//   Synchronous down counter with enable, parallel load, and underflow
//   detection. Counts from a loaded value down to 0. When count reaches 0
//   and en is asserted, the counter wraps to (2^WIDTH - 1) and the underflow
//   signal pulses for exactly one clock cycle.
//
// Parameters:
//   WIDTH  - Counter bit width (default: 8). Determines count range [0, 2^WIDTH-1].
//
// Ports:
//   clk       - Clock input (rising edge triggered)
//   rst_n     - Active-low synchronous reset; resets count to 0
//   en        - Enable: counter decrements only when en=1
//   load      - Parallel load: when asserted, count is loaded with load_val
//               (load takes priority over en)
//   load_val  - Value to load when load=1 [WIDTH-1:0]
//   count     - Current counter value [WIDTH-1:0]
//   underflow - One-cycle pulse asserted the cycle the counter wraps from 0
//               to (2^WIDTH - 1)
//
// Timing/Behavior:
//   - All state changes occur on the rising edge of clk
//   - rst_n is synchronous and active low
//   - load has higher priority than en
//   - underflow is registered; it is high on the cycle AFTER the wrap,
//     coinciding with count == MAX after the wrap
//   - underflow is not asserted on reset or load
//
// Usage Notes:
//   - Load a terminal value and count down to detect timeout/expiry conditions
//   - Tie load=0 and load_val=0 if parallel load is not needed
//   - underflow can cascade to a higher-order counter stage
//
// Example Instantiation:
//   down_counter #(
//     .WIDTH(8)
//   ) u_down_counter (
//     .clk       (clk),
//     .rst_n     (rst_n),
//     .en        (count_en),
//     .load      (load),
//     .load_val  (load_val[7:0]),
//     .count     (count[7:0]),
//     .underflow (underflow)
//   );
// =============================================================================

module down_counter #(
  parameter int unsigned WIDTH = 8
) (
  input  logic              clk,
  input  logic              rst_n,
  input  logic              en,
  input  logic              load,
  input  logic [WIDTH-1:0]  load_val,
  output logic [WIDTH-1:0]  count,
  output logic              underflow
);

  logic underflow_next;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count     <= '0;
      underflow <= 1'b0;
    end else begin
      underflow <= underflow_next;
      if (load) begin
        count <= load_val;
      end else if (en) begin
        count <= count - 1'b1;
      end
    end
  end

  always_comb begin
    underflow_next = 1'b0;
    if (!load && en && (count == '0)) begin
      underflow_next = 1'b1;
    end
  end

endmodule
