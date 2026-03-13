// =============================================================================
// Module: up_down_counter
// Description:
//   Synchronous bidirectional counter with enable, direction control, parallel
//   load, overflow, and underflow detection. The up_dn input selects the count
//   direction. overflow pulses when counting up and wrapping from MAX to 0;
//   underflow pulses when counting down and wrapping from 0 to MAX.
//
// Parameters:
//   WIDTH  - Counter bit width (default: 8). Determines count range [0, 2^WIDTH-1].
//
// Ports:
//   clk       - Clock input (rising edge triggered)
//   rst_n     - Active-low synchronous reset; resets count to 0
//   en        - Enable: counter changes only when en=1
//   up_dn     - Direction: 1=count up, 0=count down
//   load      - Parallel load: when asserted, count is loaded with load_val
//               (load takes priority over en)
//   load_val  - Value to load when load=1 [WIDTH-1:0]
//   count     - Current counter value [WIDTH-1:0]
//   overflow  - One-cycle pulse when counter wraps from MAX to 0 (up direction)
//   underflow - One-cycle pulse when counter wraps from 0 to MAX (down direction)
//
// Timing/Behavior:
//   - All state changes occur on the rising edge of clk
//   - rst_n is synchronous and active low
//   - load has highest priority, then en
//   - overflow and underflow are registered (pipelined one cycle)
//   - Only one of overflow/underflow can be asserted in any given cycle
//   - Neither flag is asserted on reset or parallel load
//
// Usage Notes:
//   - up_dn may change freely between cycles; direction takes effect on the
//     next enabled clock edge
//   - For a simple unidirectional counter, tie up_dn to a constant
//
// Example Instantiation:
//   up_down_counter #(
//     .WIDTH(8)
//   ) u_up_down_counter (
//     .clk       (clk),
//     .rst_n     (rst_n),
//     .en        (count_en),
//     .up_dn     (direction),
//     .load      (load),
//     .load_val  (load_val[7:0]),
//     .count     (count[7:0]),
//     .overflow  (overflow),
//     .underflow (underflow)
//   );
// =============================================================================

module up_down_counter #(
  parameter int unsigned WIDTH = 8
) (
  input  logic              clk,
  input  logic              rst_n,
  input  logic              en,
  input  logic              up_dn,
  input  logic              load,
  input  logic [WIDTH-1:0]  load_val,
  output logic [WIDTH-1:0]  count,
  output logic              overflow,
  output logic              underflow
);

  localparam logic [WIDTH-1:0] MAX = '1;

  logic overflow_next;
  logic underflow_next;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      count     <= '0;
      overflow  <= 1'b0;
      underflow <= 1'b0;
    end else begin
      overflow  <= overflow_next;
      underflow <= underflow_next;
      if (load) begin
        count <= load_val;
      end else if (en) begin
        count <= up_dn ? (count + 1'b1) : (count - 1'b1);
      end
    end
  end

  always_comb begin
    overflow_next  = 1'b0;
    underflow_next = 1'b0;
    if (!load && en) begin
      if (up_dn && (count == MAX)) begin
        overflow_next = 1'b1;
      end else if (!up_dn && (count == '0)) begin
        underflow_next = 1'b1;
      end
    end
  end

endmodule
