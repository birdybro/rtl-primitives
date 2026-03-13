`timescale 1ns/1ps
module programmable_interval_timer_tb;
  parameter int W = 8;
  logic clk, rst_n, en, one_shot, tick_out;
  logic [W-1:0] period, count;
  int pass_cnt = 0, fail_cnt = 0;
  int tick_cnt;

  programmable_interval_timer #(.WIDTH(W)) dut (
    .clk(clk), .rst_n(rst_n), .en(en),
    .period(period), .one_shot(one_shot),
    .tick(tick_out), .count(count));

  initial clk = 0; always #5 clk = ~clk;
  task automatic cycle; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("programmable_interval_timer_tb.vcd");
    $dumpvars(0, programmable_interval_timer_tb);
    rst_n=0; en=0; period=0; one_shot=0;
    cycle; cycle; rst_n=1;

    // Repeating mode: period=4, expect tick every 4 cycles
    period=4; one_shot=0; en=1;
    tick_cnt=0;
    repeat(12) begin
      cycle;
      if (tick_out) tick_cnt++;
    end
    if (tick_cnt !== 3) begin $error("repeating: %0d ticks expected 3 in 12 cycles", tick_cnt); fail_cnt++; end
    else pass_cnt++;

    // One-shot: only one tick
    en=0; cycle; rst_n=0; cycle; rst_n=1;
    period=4; one_shot=1; en=1;
    tick_cnt=0;
    repeat(16) begin
      cycle;
      if (tick_out) tick_cnt++;
    end
    if (tick_cnt !== 1) begin $error("one_shot: %0d ticks expected 1 in 16 cycles", tick_cnt); fail_cnt++; end
    else pass_cnt++;

    // Disabled: no ticks
    en=0; one_shot=0; period=2;
    tick_cnt=0;
    repeat(8) begin
      cycle;
      if (tick_out) tick_cnt++;
    end
    if (tick_cnt !== 0) begin $error("disabled: %0d ticks expected 0", tick_cnt); fail_cnt++; end
    else pass_cnt++;

    $display("programmable_interval_timer_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
