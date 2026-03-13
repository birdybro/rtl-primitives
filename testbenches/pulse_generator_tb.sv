`timescale 1ns/1ps
module pulse_generator_tb;
  parameter int W = 8;
  logic clk, rst_n, trigger, pulse_out;
  logic [W-1:0] pulse_width;
  int pass_cnt = 0, fail_cnt = 0;
  int pulse_cnt;

  pulse_generator #(.WIDTH(W)) dut (.clk(clk), .rst_n(rst_n), .trigger(trigger),
    .pulse_width(pulse_width), .pulse_out(pulse_out));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("pulse_generator_tb.vcd");
    $dumpvars(0, pulse_generator_tb);
    rst_n=0; trigger=0; pulse_width=0;
    tick; tick; rst_n=1;

    // No trigger: no pulse
    tick; tick;
    if (pulse_out) begin $error("pulse_out without trigger"); fail_cnt++; end
    else pass_cnt++;

    // Trigger rising edge: pulse lasts pulse_width cycles
    pulse_width = 5;
    trigger=1; tick; // rising edge detected
    pulse_cnt=0;
    repeat(7) begin
      tick;
      if (pulse_out) pulse_cnt++;
    end
    trigger=0;
    if (pulse_cnt !== 5) begin $error("pulse_width=%0d expected 5", pulse_cnt); fail_cnt++; end
    else pass_cnt++;

    // No pulse after it finishes
    tick; tick;
    if (pulse_out) begin $error("pulse_out after completion"); fail_cnt++; end
    else pass_cnt++;

    // Second trigger
    pulse_width = 3;
    trigger=0; tick; trigger=1; tick;
    pulse_cnt=0;
    repeat(5) begin
      tick;
      if (pulse_out) pulse_cnt++;
    end
    trigger=0;
    if (pulse_cnt !== 3) begin $error("2nd pulse_width=%0d expected 3", pulse_cnt); fail_cnt++; end
    else pass_cnt++;

    // pulse_width=0: no pulse
    pulse_width=0; trigger=0; tick; trigger=1; tick; trigger=0;
    tick; tick;
    if (pulse_out) begin $error("pulse_out with pulse_width=0"); fail_cnt++; end
    else pass_cnt++;

    $display("pulse_generator_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
