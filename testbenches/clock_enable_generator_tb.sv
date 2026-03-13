`timescale 1ns/1ps
module clock_enable_generator_tb;
  parameter int W = 8;
  logic clk, rst_n, en, clk_en;
  logic [W-1:0] period;
  int pass_cnt = 0, fail_cnt = 0;
  int en_cnt;

  clock_enable_generator #(.WIDTH(W)) dut (.clk(clk), .rst_n(rst_n), .en(en),
    .period(period), .clk_en(clk_en));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("clock_enable_generator_tb.vcd");
    $dumpvars(0, clock_enable_generator_tb);
    rst_n=0; en=0; period=0;
    tick; tick; rst_n=1;

    // period=4: expect one clk_en every 4 cycles
    period=4; en=1;
    en_cnt=0;
    repeat(12) begin
      tick;
      if (clk_en) en_cnt++;
    end
    if (en_cnt !== 3) begin $error("period=4: %0d pulses in 12 cycles expected 3", en_cnt); fail_cnt++; end
    else pass_cnt++;

    // Disable: no pulses
    en=0;
    en_cnt=0;
    repeat(8) begin
      tick;
      if (clk_en) en_cnt++;
    end
    if (en_cnt !== 0) begin $error("disabled: %0d pulses expected 0", en_cnt); fail_cnt++; end
    else pass_cnt++;

    // period=1: pulse every cycle
    en=1; period=1; rst_n=0; tick; rst_n=1;
    en_cnt=0;
    repeat(4) begin
      tick;
      if (clk_en) en_cnt++;
    end
    if (en_cnt !== 4) begin $error("period=1: %0d pulses in 4 cycles expected 4", en_cnt); fail_cnt++; end
    else pass_cnt++;

    $display("clock_enable_generator_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
