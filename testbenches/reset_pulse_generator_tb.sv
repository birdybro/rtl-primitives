`timescale 1ns/1ps
module reset_pulse_generator_tb;
  parameter int PW = 4;
  logic clk, rst_n, rst_req, rst_pulse;
  int pass_cnt = 0, fail_cnt = 0;
  int pulse_width_cnt;

  reset_pulse_generator #(.PULSE_WIDTH(PW)) dut (
    .clk(clk), .rst_n(rst_n), .rst_req(rst_req), .rst_pulse(rst_pulse));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("reset_pulse_generator_tb.vcd");
    $dumpvars(0, reset_pulse_generator_tb);
    rst_n=0; rst_req=0;
    tick; tick; rst_n=1;

    // No request: no pulse
    tick; tick;
    if (rst_pulse) begin $error("rst_pulse asserted without request"); fail_cnt++; end
    else pass_cnt++;

    // Rising edge of rst_req: pulse should last exactly PW cycles
    rst_req=1; tick; // rising edge detected
    pulse_width_cnt=0;
    repeat(PW+2) begin
      tick;
      if (rst_pulse) pulse_width_cnt++;
    end
    rst_req=0;
    if (pulse_width_cnt !== PW) begin $error("pulse_width=%0d expected %0d", pulse_width_cnt, PW); fail_cnt++; end
    else pass_cnt++;

    // No extra pulse after request deasserts
    tick; tick;
    if (rst_pulse) begin $error("pulse still active after deassertion"); fail_cnt++; end
    else pass_cnt++;

    // Second rising edge: another pulse
    rst_req=0; tick; rst_req=1; tick;
    pulse_width_cnt=0;
    repeat(PW+2) begin
      tick;
      if (rst_pulse) pulse_width_cnt++;
    end
    rst_req=0;
    if (pulse_width_cnt !== PW) begin $error("2nd pulse_width=%0d expected %0d", pulse_width_cnt, PW); fail_cnt++; end
    else pass_cnt++;

    // Reset clears pulse mid-flight
    rst_req=1; tick; tick; // start pulse
    rst_n=0; tick; rst_n=1; tick;
    if (rst_pulse) begin $error("rst_pulse active after reset"); fail_cnt++; end
    else pass_cnt++;

    $display("reset_pulse_generator_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
