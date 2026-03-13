// =============================================================================
// Module: pulse_generator
// Description:
//   Generates a one-shot active-high pulse of configurable width (in clock
//   cycles) upon detection of a rising edge on the trigger input.
//
// Parameters:
//   WIDTH - Bit-width of the pulse_width counter (default 8)
//
// Ports:
//   clk         - Input clock
//   rst_n       - Active-low synchronous reset
//   trigger     - Rising edge starts the pulse
//   pulse_width - Duration of the pulse in clk cycles (sampled at trigger edge)
//   pulse_out   - Active-high output pulse
//
// Usage notes:
//   - A new trigger rising edge while a pulse is active is ignored.
//   - pulse_width=0 produces no pulse.
//   - pulse_width is sampled on the cycle the rising edge is detected.
//
// Timing/Behavior:
//   - Rising edge of trigger is detected by comparing current and previous value.
//   - pulse_out asserts the cycle after the rising edge and stays high for
//     pulse_width cycles.
//
// Example instantiation:
//   pulse_generator #(.WIDTH(8)) u_pulse (
//     .clk         (clk),
//     .rst_n       (rst_n),
//     .trigger     (trigger),
//     .pulse_width (8'd10),
//     .pulse_out   (pulse_out)
//   );
// =============================================================================

module pulse_generator #(
  parameter int unsigned WIDTH = 8
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             trigger,
  input  logic [WIDTH-1:0] pulse_width,
  output logic             pulse_out
);

  logic             trigger_prev;
  logic             rising_edge;
  logic [WIDTH-1:0] count;
  logic             active;

  always_comb begin
    rising_edge = trigger & ~trigger_prev;
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      trigger_prev <= 1'b0;
      count        <= '0;
      active       <= 1'b0;
      pulse_out    <= 1'b0;
    end else begin
      trigger_prev <= trigger;

      if (rising_edge && !active && pulse_width != '0) begin
        active    <= 1'b1;
        count     <= pulse_width - 1'b1;
        pulse_out <= 1'b1;
      end else if (active) begin
        if (count == '0) begin
          active    <= 1'b0;
          pulse_out <= 1'b0;
        end else begin
          count <= count - 1'b1;
        end
      end
    end
  end

endmodule
