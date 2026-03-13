// =============================================================================
// Module: up_counter
// Description:
//   Synchronous up counter with enable, parallel load, and overflow detection.
//   Counts from 0 to (2^WIDTH - 1) and wraps back to 0. The overflow signal
//   pulses for exactly one clock cycle when the counter wraps from its maximum
//   value back to zero (i.e., when count == MAX and en is asserted).
//
// Parameters:
//   WIDTH  - Counter bit width (default: 8). Determines count range [0, 2^WIDTH-1].
//
// Ports:
//   clk       - Clock input (rising edge triggered)
//   rst_n     - Active-low synchronous reset; resets count to 0
//   en        - Enable: counter increments only when en=1
//   load      - Parallel load: when asserted, count is loaded with load_val
//               (load takes priority over en)
//   load_val  - Value to load when load=1 [WIDTH-1:0]
//   count     - Current counter value [WIDTH-1:0]
//   overflow  - One-cycle pulse asserted the cycle the counter wraps to 0
//
// Timing/Behavior:
//   - All state changes occur on the rising edge of clk
//   - rst_n is synchronous and active low
//   - load has higher priority than en
//   - overflow is registered; it is high on the cycle AFTER the wrap occurs,
//     coinciding with count == 0 after the wrap
//   - overflow is not asserted on reset or load
//
// Usage Notes:
//   - Set WIDTH to match your application's counting range
//   - Tie load=0 and load_val=0 if parallel load is not needed
//   - overflow can be used to cascade counters or as a terminal-count signal
//
// Example Instantiation:
//   up_counter #(
//     .WIDTH(8)
//   ) u_up_counter (
//     .clk      (clk),
//     .rst_n    (rst_n),
//     .en       (count_en),
//     .load     (load),
//     .load_val (load_val[7:0]),
//     .count    (count[7:0]),
//     .overflow (overflow)
//   );
// =============================================================================

module up_counter #(
  parameter int unsigned WIDTH = 8
) (
  input  logic              clk,
  input  logic              rst_n,
  input  logic              en,
  input  logic              load,
  input  logic [WIDTH-1:0]  load_val,
  output logic [WIDTH-1:0]  count,
  output logic              overflow
);

  localparam logic [WIDTH-1:0] MAX = '1;

  logic overflow_next;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count    <= '0;
      overflow <= 1'b0;
    end else begin
      overflow <= overflow_next;
      if (load) begin
        count <= load_val;
      end else if (en) begin
        count <= count + 1'b1;
      end
    end
  end

  always_comb begin
    overflow_next = 1'b0;
    if (!load && en && (count == MAX)) begin
      overflow_next = 1'b1;
    end
  end

endmodule
