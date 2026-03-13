`timescale 1ns/1ps
module saturating_counter_tb;
  parameter int W = 4;
  logic clk, rst_n, en, up_dn, load, at_max, at_min;
  logic [W-1:0] load_val, count;
  int pass_cnt = 0, fail_cnt = 0;

  saturating_counter #(.WIDTH(W)) dut (.clk(clk), .rst_n(rst_n), .en(en), .up_dn(up_dn),
    .load(load), .load_val(load_val), .count(count), .at_max(at_max), .at_min(at_min));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("saturating_counter_tb.vcd");
    $dumpvars(0, saturating_counter_tb);
    rst_n=0; en=0; up_dn=1; load=0; load_val=0;
    tick; tick; rst_n=1;

    // After reset: count=0, at_min=1
    if (count !== 0) begin $error("After reset count=%0d", count); fail_cnt++; end
    else pass_cnt++;
    if (!at_min) begin $error("at_min not set at reset"); fail_cnt++; end
    else pass_cnt++;

    // Count up to max: 2^W - 1 = 15
    en=1; up_dn=1;
    repeat(16) tick; // count will saturate at 15
    if (count !== W'('1)) begin $error("count=%0d expected MAX=%0d", count, 2**W-1); fail_cnt++; end
    else pass_cnt++;
    if (!at_max) begin $error("at_max not set"); fail_cnt++; end
    else pass_cnt++;
    // One more up: still max
    tick;
    if (count !== W'('1)) begin $error("count changed above max: %0d", count); fail_cnt++; end
    else pass_cnt++;

    // Count down to min
    up_dn=0;
    repeat(16) tick;
    if (count !== 0) begin $error("count=%0d expected 0 after counting down", count); fail_cnt++; end
    else pass_cnt++;
    if (!at_min) begin $error("at_min not set at bottom"); fail_cnt++; end
    else pass_cnt++;
    // One more down: still 0
    tick;
    if (count !== 0) begin $error("count went below 0: %0d", count); fail_cnt++; end
    else pass_cnt++;

    // Load
    load=1; load_val=7; tick; load=0;
    if (count !== 7) begin $error("After load count=%0d expected 7", count); fail_cnt++; end
    else pass_cnt++;

    $display("saturating_counter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
